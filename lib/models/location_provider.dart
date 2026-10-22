import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/geo.dart';
import 'umrah_location.dart';
import 'journey_models.dart';
import 'journey_record.dart';

/// GPS signal state during a journey.
enum GpsSignal {
  /// Fixes are arriving (or no journey is active).
  ok,

  /// No fix for [LocationProvider._staleAfter]; the track has a hole.
  lost,

  /// Fixes resumed after [lost]; shown briefly, then back to [ok].
  recovered,
}

class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _journeyActiveKey = 'journey_active';

  /// Latest GPS fix. Changes on every fix, so it is a separate notifier:
  /// listening to the provider itself only rebuilds on zone, GPS-state or
  /// journey changes.
  final ValueNotifier<Position?> position = ValueNotifier<Position?>(null);

  UmrahLocation? _currentZone;
  UmrahLocation? _manualZone;
  bool _gpsAvailable = false;
  bool _gpsStarting = false;
  bool _isJourneyActive = false;
  JourneyKind _kind = JourneyKind.umrah;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceSub;

  // Journey recording
  final List<JourneyPoint> _gpsTrack = [];
  final List<CheckpointRecord> _checkpoints = [];
  DateTime? _journeyStartTime;

  // sampling helpers
  JourneyPoint? _lastSavedPoint;
  DateTime? _lastSavedTime;
  DateTime? _lastFixTime;
  Timer? _autosaveTimer;
  Timer? _signalTimer;
  GpsSignal _signal = GpsSignal.ok;
  DateTime? _recoveredAt;

  // Track file writes run one after another (autosave vs checkpoint writes).
  Future<void> _writeChain = Future.value();

  // sampling/configuration
  static const _minDistanceMeters = 5.0;
  static const _maxIntervalSeconds = 15;
  static const _autosaveInterval = Duration(seconds: 15);

  /// Fixes less accurate than this are ignored for the track (common under
  /// the roofs of Masjidil Haram; they make the path zig-zag).
  static const _maxAccuracyMeters = 50.0;

  /// No fix for this long during a journey counts as lost GPS.
  static const _staleAfter = Duration(seconds: 30);

  /// No fix for this long between two track points marks a gap in the track.
  static const _gapAfter = Duration(seconds: 60);
  static const _recoveredShownFor = Duration(seconds: 10);

  Position? get currentPosition => position.value;
  UmrahLocation? get currentZone => _manualZone ?? _currentZone;
  bool get gpsAvailable => _gpsAvailable;
  bool get isJourneyActive => _isJourneyActive;

  /// GPS signal state; always [GpsSignal.ok] when no journey is active.
  GpsSignal get gpsSignal => _isJourneyActive ? _signal : GpsSignal.ok;

  /// Kind of the current (or last loaded) session.
  JourneyKind get journeyKind => _kind;
  bool get isUmrahActive => _isJourneyActive && _kind == JourneyKind.umrah;
  bool get isWidaActive => _isJourneyActive && _kind == JourneyKind.wida;
  List<JourneyPoint> get gpsTrack => List.unmodifiable(_gpsTrack);
  List<CheckpointRecord> get checkpoints => List.unmodifiable(_checkpoints);
  DateTime? get journeyStartTime => _journeyStartTime;

  /// Last checkpoint that has startTime but no endTime yet (in-progress).
  CheckpointRecord? get lastIncompleteCheckpoint {
    for (int i = _checkpoints.length - 1; i >= 0; i--) {
      if (!_checkpoints[i].isCompleted) return _checkpoints[i];
    }
    return null;
  }

  /// Checkpoints that have been started (whether completed or not).
  bool isCheckpointStarted(int num) =>
      _checkpoints.any((c) => c.checkpointNum == num);

  /// Whether checkpoint N has been fully completed.
  bool isCheckpointCompleted(int num) =>
      _checkpoints.any((c) => c.checkpointNum == num && c.isCompleted);

  /// Checkpoints that were started but never ended.
  List<CheckpointRecord> get missedCheckpoints =>
      _checkpoints.where((c) => !c.isCompleted).toList();

  /// Returns the lowest checkpoint number of the current session's kind that
  /// hasn't been started yet, or null if all of them have been started.
  int? nextUnstartedCheckpoint() {
    for (int i = _kind.firstCp; i <= _kind.lastCp; i++) {
      if (!_checkpoints.any((c) => c.checkpointNum == i)) return i;
    }
    return null;
  }

  LocationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initGps(requestPermission: true);
    _watchServiceStatus();
    _loadJourneyState();
  }

  Future<void> _loadJourneyState() async {
    final prefs = await SharedPreferences.getInstance();
    _isJourneyActive = prefs.getBool(_journeyActiveKey) ?? false;
    if (_isJourneyActive) {
      await _loadPersistentTrack();
      _onJourneyRunning();
    }
    notifyListeners();
  }

  Future<void> _loadPersistentTrack() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/umrah_cur.json');
      if (!await file.exists()) return;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (map['track'] is List) {
        _gpsTrack.clear();
        _gpsTrack.addAll((map['track'] as List)
            .map((e) => JourneyPoint.fromJson(e as Map<String, dynamic>)));
        if (_gpsTrack.isNotEmpty) {
          _lastSavedPoint = _gpsTrack.last;
          _lastSavedTime = _gpsTrack.last.timestamp;
        }
      }
      if (map['checkpoints'] is List) {
        _checkpoints.clear();
        _checkpoints.addAll((map['checkpoints'] as List)
            .map((e) => CheckpointRecord.fromJson(e as Map<String, dynamic>)));
      }
      if (map['start'] != null) {
        _journeyStartTime = DateTime.parse(map['start'] as String);
      }
      // Files written before Tawaf Wida' sessions existed have no 'kind'.
      _kind = JourneyKind.fromName(map['kind'] as String?);
    } catch (e) {
      debugPrint('Load track error: $e');
    }
  }

  // ── GPS ───────────────────────────────────────────────────────────────────

  /// Starts the position stream if it isn't running. Asks for permission only
  /// when [requestPermission] is set (app start, starting a journey), so
  /// resuming the app doesn't nag a user who declined.
  Future<void> _initGps({bool requestPermission = false}) async {
    if (_positionSub != null || _gpsStarting) return;
    _gpsStarting = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setGpsAvailable(false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setGpsAvailable(false);
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        // No distance filter: a steady stream of fixes is what tells a lost
        // signal apart from standing still. Sampling below thins the track.
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 2),
        ),
      ).listen(_onPosition, onError: _onPositionError);
      _setGpsAvailable(true);
    } catch (e) {
      debugPrint('GPS init error: $e');
    } finally {
      _gpsStarting = false;
    }
  }

  void _stopGps() {
    _positionSub?.cancel();
    _positionSub = null;
    _setGpsAvailable(false);
  }

  void _onPositionError(Object e) {
    debugPrint('GPS stream error: $e');
    _stopGps();
  }

  void _watchServiceStatus() {
    try {
      _serviceSub = Geolocator.getServiceStatusStream().listen((status) {
        if (status == ServiceStatus.enabled) {
          _initGps();
        } else {
          _stopGps();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  void _setGpsAvailable(bool v) {
    if (_gpsAvailable == v) return;
    _gpsAvailable = v;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The stream can die while the app is in the background; restart it.
    if (state == AppLifecycleState.resumed) _initGps();
  }

  void _onPosition(Position pos) {
    final now = DateTime.now();
    _lastFixTime = now;
    position.value = pos;
    var changed = false;

    if (_signal == GpsSignal.lost) {
      _signal = GpsSignal.recovered;
      _recoveredAt = now;
      changed = true;
    }

    final detected = _detectZone(pos);
    if (detected?.id != _currentZone?.id) {
      _currentZone = detected;
      changed = true;
    }

    if (_isJourneyActive && pos.accuracy <= _maxAccuracyMeters) {
      _maybeAddTrackPoint(pos, now);
    }

    if (changed) notifyListeners();
  }

  UmrahLocation? _detectZone(Position pos) {
    UmrahLocation? detected;
    double minDist = double.infinity;
    for (final loc in umrahLocations) {
      bool inside = false;
      if (loc.polygon != null && loc.polygon!.isNotEmpty) {
        inside =
            _pointInPolygon(LatLng(pos.latitude, pos.longitude), loc.polygon!);
      } else if (loc.center != null && loc.radiusMeters != null) {
        final d = metersBetween(pos.latitude, pos.longitude,
            loc.center!.latitude, loc.center!.longitude);
        inside = d <= loc.radiusMeters!;
      }
      if (inside) {
        double dist = double.infinity;
        if (loc.center != null) {
          dist = metersBetween(pos.latitude, pos.longitude,
              loc.center!.latitude, loc.center!.longitude);
        }
        if (dist < minDist) {
          minDist = dist;
          detected = loc;
        }
      }
    }
    return detected;
  }

  void _maybeAddTrackPoint(Position pos, DateTime now) {
    final last = _lastSavedPoint;
    final lastTime = _lastSavedTime;
    final sinceLast = lastTime == null ? null : now.difference(lastTime);
    final bool shouldAdd;
    if (last == null || sinceLast == null) {
      shouldAdd = true;
    } else {
      final dist =
          metersBetween(pos.latitude, pos.longitude, last.lat, last.lng);
      shouldAdd = dist >= _minDistanceMeters ||
          sinceLast.inSeconds >= _maxIntervalSeconds;
    }
    if (!shouldAdd) return;
    final p = JourneyPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      timestamp: now,
      gapBefore: sinceLast != null && sinceLast > _gapAfter,
    );
    _gpsTrack.add(p);
    _lastSavedPoint = p;
    _lastSavedTime = now;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> poly) {
    var x = point.longitude;
    var y = point.latitude;
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude;
      final yi = poly[i].latitude;
      final xj = poly[j].longitude;
      final yj = poly[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  void manualOverrideZone(UmrahLocation? zone) {
    _manualZone = zone;
    notifyListeners();
  }

  /// Re-evaluates the lost/recovered GPS state; runs every few seconds while
  /// a journey is active.
  void _checkSignal() {
    final now = DateTime.now();
    final lastFix = _lastFixTime ?? _journeyStartTime ?? now;
    var next = _signal;
    if (now.difference(lastFix) > _staleAfter) {
      next = GpsSignal.lost;
    } else if (_signal == GpsSignal.recovered &&
        _recoveredAt != null &&
        now.difference(_recoveredAt!) > _recoveredShownFor) {
      next = GpsSignal.ok;
    }
    if (next != _signal) {
      _signal = next;
      notifyListeners();
    }
  }

  // ── Journey control ───────────────────────────────────────────────────────

  /// Begin a new journey of [kind] (or resume existing if track file present).
  /// Does nothing while another session (of any kind) is active.
  Future<void> startJourney({JourneyKind kind = JourneyKind.umrah}) async {
    if (_isJourneyActive) return;
    await _loadPersistentTrack();
    // Leftover data from a session of the other kind must not leak into this one.
    if (_kind != kind && (_gpsTrack.isNotEmpty || _checkpoints.isNotEmpty)) {
      _clearState();
    }
    _kind = kind;
    if (_gpsTrack.isEmpty && _checkpoints.isEmpty) {
      _journeyStartTime = DateTime.now();
    }
    _isJourneyActive = true;
    _signal = GpsSignal.ok;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, true);
    _onJourneyRunning();
    if (!_gpsAvailable) _initGps(requestPermission: true);
  }

  /// Timers and screen wakelock for an active journey.
  void _onJourneyRunning() {
    _lastFixTime ??= DateTime.now();
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(_autosaveInterval, (_) => autosaveTick());
    _signalTimer?.cancel();
    _signalTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkSignal());
    // GPS stops recording when the screen locks, so keep it on.
    WakelockPlus.enable().catchError((_) {});
  }

  void _onJourneyStopped() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _signalTimer?.cancel();
    _signalTimer = null;
    _signal = GpsSignal.ok;
    WakelockPlus.disable().catchError((_) {});
  }

  /// Called when user opens a doa with checkPointStart set.
  Future<void> recordCheckpointStart(int num, String name) async {
    // Ignore checkpoints that belong to the other kind of session
    if (!_kind.ownsCheckpoint(num)) return;
    // Don't duplicate if already started
    if (_checkpoints.any((c) => c.checkpointNum == num)) return;
    final pos = position.value;
    _checkpoints.add(CheckpointRecord(
      checkpointNum: num,
      name: name,
      startTime: DateTime.now(),
      lat: pos?.latitude,
      lng: pos?.longitude,
    ));
    notifyListeners();
    await _persistTrack();
  }

  /// Called when user taps "Ya" in checkpoint-end dialog.
  Future<void> recordCheckpointEnd(int num) async {
    if (!_kind.ownsCheckpoint(num)) return;
    final idx = _checkpoints.indexWhere((c) => c.checkpointNum == num);
    if (idx < 0) return;
    _checkpoints[idx].endTime = DateTime.now();
    notifyListeners();
    await _persistTrack();
  }

  /// Queues a write of the current state; writes never overlap.
  Future<void> _persistTrack() {
    final content = jsonEncode({
      'start': _journeyStartTime?.toIso8601String(),
      'active': _isJourneyActive,
      'kind': _kind.name,
      'track': _gpsTrack.map((p) => p.toJson()).toList(),
      'checkpoints': _checkpoints.map((c) => c.toJson()).toList(),
    });
    return _writeChain = _writeChain.then((_) => _writeTrackFile(content));
  }

  Future<void> _writeTrackFile(String content) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tmp = File('${dir.path}/umrah_cur.json.tmp');
      await tmp.writeAsString(content, flush: true);
      await tmp.rename('${dir.path}/umrah_cur.json');
    } catch (e) {
      debugPrint('Persist track error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _serviceSub?.cancel();
    _onJourneyStopped();
    position.dispose();
    super.dispose();
  }

  Future<void> autosaveTick() async {
    if (_isJourneyActive) await _persistTrack();
  }

  /// Finalize the journey and clear internal state; returns record ready for history.
  Future<UmrahJourneyRecord> finalizeJourney({String? notes}) async {
    _isJourneyActive = false;
    final endTime = DateTime.now();
    final record = UmrahJourneyRecord(
      id: _journeyStartTime?.toIso8601String() ?? endTime.toIso8601String(),
      startTime: _journeyStartTime ?? endTime,
      endTime: endTime,
      notes: notes,
      gpsTrack: List.from(_gpsTrack),
      completed: true,
      checkpoints: List.from(_checkpoints),
      kind: _kind,
    );
    _clearState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    await _persistTrack();
    notifyListeners();
    return record;
  }

  void _clearState() {
    _gpsTrack.clear();
    _checkpoints.clear();
    _journeyStartTime = null;
    _kind = JourneyKind.umrah;
    _lastSavedPoint = null;
    _lastSavedTime = null;
    _onJourneyStopped();
  }
}
