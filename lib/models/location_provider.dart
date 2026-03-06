import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'umrah_location.dart';
import 'journey_models.dart';
import 'journey_record.dart';

class LocationProvider extends ChangeNotifier {
  static const _journeyActiveKey = 'journey_active';

  Position? _currentPosition;
  UmrahLocation? _currentZone;
  UmrahLocation? _manualZone;
  bool _isOnline = false;
  bool _gpsAvailable = false;
  bool _isJourneyActive = false;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  // Journey recording
  final List<JourneyPoint> _gpsTrack = [];
  final List<CheckpointRecord> _checkpoints = [];
  DateTime? _journeyStartTime;

  // sampling helpers
  JourneyPoint? _lastSavedPoint;
  DateTime? _lastSavedTime;
  Timer? _autosaveTimer;

  // sampling/configuration
  static const _minDistanceMeters = 5.0;
  static const _maxIntervalSeconds = 15;
  static const _autosaveInterval = Duration(seconds: 15);

  Position? get currentPosition => _currentPosition;
  UmrahLocation? get currentZone => _manualZone ?? _currentZone;
  bool get isOnline => _isOnline;
  bool get gpsAvailable => _gpsAvailable;
  bool get isJourneyActive => _isJourneyActive;
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

  /// Returns the lowest checkpoint number in 1..maxCp that hasn't been started yet.
  /// Returns null if all checkpoints up to maxCp have been started.
  int? nextUnstartedCheckpoint(int maxCp) {
    for (int i = 1; i <= maxCp; i++) {
      if (!_checkpoints.any((c) => c.checkpointNum == i)) return i;
    }
    return null;
  }

  LocationProvider() {
    _initConnectivity();
    _initGps();
    _loadJourneyState();
  }

  Future<void> _loadJourneyState() async {
    final prefs = await SharedPreferences.getInstance();
    _isJourneyActive = prefs.getBool(_journeyActiveKey) ?? false;
    if (_isJourneyActive) {
      await _loadPersistentTrack();
      _startAutosaveTimer();
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
      }
      if (map['checkpoints'] is List) {
        _checkpoints.clear();
        _checkpoints.addAll((map['checkpoints'] as List)
            .map((e) => CheckpointRecord.fromJson(e as Map<String, dynamic>)));
      }
      if (map['start'] != null) {
        _journeyStartTime = DateTime.parse(map['start'] as String);
      }
    } catch (_) {}
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
    _connectSub = Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
  }

  Future<void> _initGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _gpsAvailable = true;
      notifyListeners();

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onPosition);
    } catch (_) {}
  }

  void _onPosition(Position pos) {
    _currentPosition = pos;

    // Detect zone
    UmrahLocation? detected;
    double minDist = double.infinity;
    for (final loc in umrahLocations) {
      bool inside = false;
      if (loc.polygon != null && loc.polygon!.isNotEmpty) {
        inside =
            _pointInPolygon(LatLng(pos.latitude, pos.longitude), loc.polygon!);
      } else if (loc.center != null && loc.radiusMeters != null) {
        final d = _distanceMeters(pos.latitude, pos.longitude,
            loc.center!.latitude, loc.center!.longitude);
        inside = d <= loc.radiusMeters!;
      }
      if (inside) {
        double dist = double.infinity;
        if (loc.center != null) {
          dist = _distanceMeters(pos.latitude, pos.longitude,
              loc.center!.latitude, loc.center!.longitude);
        }
        if (dist < minDist) {
          minDist = dist;
          detected = loc;
        }
      }
    }
    _currentZone = detected;

    // Record GPS track if journey active
    if (_isJourneyActive) {
      final now = DateTime.now();
      bool shouldAdd = false;
      if (_lastSavedPoint == null) {
        shouldAdd = true;
      } else {
        final dist = _distanceMeters(pos.latitude, pos.longitude,
            _lastSavedPoint!.lat, _lastSavedPoint!.lng);
        if (dist >= _minDistanceMeters) {
          shouldAdd = true;
        } else if (_lastSavedTime != null &&
            now.difference(_lastSavedTime!).inSeconds >= _maxIntervalSeconds) {
          shouldAdd = true;
        }
      }
      if (shouldAdd) {
        final p =
            JourneyPoint(lat: pos.latitude, lng: pos.longitude, timestamp: now);
        _gpsTrack.add(p);
        _lastSavedPoint = p;
        _lastSavedTime = now;
      }
    }

    notifyListeners();
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
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

  double _rad(double deg) => deg * math.pi / 180;

  void manualOverrideZone(UmrahLocation? zone) {
    _manualZone = zone;
    notifyListeners();
  }

  // ── Journey control ───────────────────────────────────────────────────────

  /// Begin a new journey (or resume existing if track file present).
  Future<void> startJourney() async {
    if (_isJourneyActive) return;
    await _loadPersistentTrack();
    if (_gpsTrack.isEmpty && _checkpoints.isEmpty) {
      _journeyStartTime = DateTime.now();
    }
    _isJourneyActive = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, true);
    _startAutosaveTimer();
  }

  /// Called when user opens a doa with checkPointStart set.
  Future<void> recordCheckpointStart(int num, String name) async {
    // Don't duplicate if already started
    if (_checkpoints.any((c) => c.checkpointNum == num)) return;
    _checkpoints.add(CheckpointRecord(
      checkpointNum: num,
      name: name,
      startTime: DateTime.now(),
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    ));
    notifyListeners();
    await _persistTrack();
  }

  /// Called when user taps "Ya" in checkpoint-end dialog.
  Future<void> recordCheckpointEnd(int num) async {
    final idx = _checkpoints.indexWhere((c) => c.checkpointNum == num);
    if (idx < 0) return;
    _checkpoints[idx].endTime = DateTime.now();
    notifyListeners();
    await _persistTrack();
  }

  Future<void> _persistTrack() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tmp = File('${dir.path}/umrah_cur.json.tmp');
      final file = File('${dir.path}/umrah_cur.json');
      final content = jsonEncode({
        'start': _journeyStartTime?.toIso8601String(),
        'active': _isJourneyActive,
        'track': _gpsTrack.map((p) => p.toJson()).toList(),
        'checkpoints': _checkpoints.map((c) => c.toJson()).toList(),
      });
      await tmp.writeAsString(content);
      if (await tmp.exists()) await tmp.rename(file.path);
    } catch (e, stack) {
      // ← Changed from catch (_)
      debugPrint('Persist track error: $e');
      debugPrint(stack.toString());
      // Don't rethrow - this is called during finalize
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _connectSub?.cancel();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  void _startAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(_autosaveInterval, (_) => autosaveTick());
  }

  void _stopAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  Future<void> autosaveTick() async {
    if (_isJourneyActive) await _persistTrack();
  }

  /// Finalize the journey and clear internal state; returns record ready for history.
  Future<UmrahJourneyRecord> finalizeJourney({String? notes}) async {
    debugPrint('=== FINALIZE JOURNEY ===');
    debugPrint('_journeyStartTime: $_journeyStartTime');
    debugPrint('_isJourneyActive: $_isJourneyActive');
    debugPrint('_gpsTrack length: ${_gpsTrack.length}');
    debugPrint('_checkpoints length: ${_checkpoints.length}');

    _isJourneyActive = false;
    final endTime = DateTime.now();
    debugPrint('endTime: $endTime');

    final record = UmrahJourneyRecord(
      id: _journeyStartTime?.toIso8601String() ?? endTime.toIso8601String(),
      startTime: _journeyStartTime ?? endTime,
      endTime: endTime,
      notes: notes,
      gpsTrack: List.from(_gpsTrack),
      completed: true,
      version: 2,
      checkpoints: List.from(_checkpoints),
    );

    debugPrint('Record created:');
    debugPrint('  id: ${record.id}');
    debugPrint('  startTime: ${record.startTime}');
    debugPrint('  endTime: ${record.endTime}');
    debugPrint('  gpsTrack: ${record.gpsTrack.length}');
    debugPrint('  checkpoints: ${record.checkpoints.length}');

    _clearState();

    debugPrint('After _clearState():');
    debugPrint('  _journeyStartTime: $_journeyStartTime');
    debugPrint('  _gpsTrack: ${_gpsTrack.length}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    await _persistTrack();
    notifyListeners();

    debugPrint('=== FINALIZE COMPLETE ===');
    return record;
  }

  /// Capture current track as an incomplete record then clear state.
  Future<UmrahJourneyRecord> snapshotAndClear({String? notes}) async {
    _isJourneyActive = false;
    final endTime = DateTime.now();
    final record = UmrahJourneyRecord(
      id: _journeyStartTime?.toIso8601String() ?? endTime.toIso8601String(),
      startTime: _journeyStartTime ?? endTime,
      endTime: endTime,
      notes: notes,
      gpsTrack: List.from(_gpsTrack),
      completed: false,
      version: 2,
      checkpoints: List.from(_checkpoints),
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
    _lastSavedPoint = null;
    _lastSavedTime = null;
    _stopAutosaveTimer();
  }

  Future<void> pauseJourney() async {
    _isJourneyActive = false;
    _stopAutosaveTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    notifyListeners();
  }

  Future<void> resumeJourney() async {
    if (_isJourneyActive) return;
    _isJourneyActive = true;
    _startAutosaveTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, true);
    notifyListeners();
  }
}
