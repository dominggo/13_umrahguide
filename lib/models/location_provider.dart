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
  final List<JourneyEvent> _events = [];
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
  List<JourneyEvent> get events => List.unmodifiable(_events);
  DateTime? get journeyStartTime => _journeyStartTime;

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
      // restart autosave loop
      _startAutosaveTimer();
    }
    notifyListeners();
  }

  Future<void> _loadPersistentTrack() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/journey_track.json');
      if (!await file.exists()) return;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (map['track'] is List) {
        _gpsTrack.clear();
        _gpsTrack.addAll((map['track'] as List).map((e) => JourneyPoint.fromJson(e as Map<String, dynamic>)));
      }
      if (map['events'] is List) {
        _events.clear();
        _events.addAll((map['events'] as List).map((e) => JourneyEvent.fromJson(e as Map<String, dynamic>)));
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
        inside = _pointInPolygon(LatLng(pos.latitude, pos.longitude), loc.polygon!);
      } else if (loc.center != null && loc.radiusMeters != null) {
        final d = _distanceMeters(pos.latitude, pos.longitude, loc.center!.latitude, loc.center!.longitude);
        inside = d <= loc.radiusMeters!;
      }
      if (inside) {
        // if multiple zones overlap choose the one closest to its center (if defined)
        double dist = double.infinity;
        if (loc.center != null) {
          dist = _distanceMeters(pos.latitude, pos.longitude, loc.center!.latitude, loc.center!.longitude);
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
      // sample to reduce points
      final now = DateTime.now();
      bool shouldAdd = false;
      if (_lastSavedPoint == null) {
        shouldAdd = true;
      } else {
        final dist = _distanceMeters(pos.latitude, pos.longitude, _lastSavedPoint!.lat, _lastSavedPoint!.lng);
        if (dist >= _minDistanceMeters) {
          shouldAdd = true;
        } else if (_lastSavedTime != null && now.difference(_lastSavedTime!).inSeconds >= _maxIntervalSeconds) {
          shouldAdd = true;
        }
      }
      if (shouldAdd) {
        final p = JourneyPoint(lat: pos.latitude, lng: pos.longitude, timestamp: now);
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
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> poly) {
    // ray-casting algorithm
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
  ///
  /// If a persisted track exists it will be loaded and recording resumed.
  Future<void> startJourney() async {
    if (_isJourneyActive) return;
    await _loadPersistentTrack();
    if (_gpsTrack.isEmpty && _events.isEmpty) {
      // brand‑new journey
      _journeyStartTime = DateTime.now();
      _events.add(JourneyEvent(
        eventType: JourneyEventType.journeyStart,
        timestamp: _journeyStartTime!,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      ));
    } else {
      // try to set start time from first event
      final startEvt = _events.cast<JourneyEvent?>().firstWhere(
          (e) => e?.eventType == JourneyEventType.journeyStart,
          orElse: () => null);
      _journeyStartTime = startEvt?.timestamp;
    }
    _isJourneyActive = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, true);
    _startAutosaveTimer();
  }

  Future<void> logEvent(JourneyEvent event) async {
    _events.add(event);
    await _persistTrack();
  }

  /// Ends the current journey and returns the raw data.
  /// Use [finalizeJourney] for history‑friendly record.
  Future<({List<JourneyPoint> track, List<JourneyEvent> events, DateTime? start})> endJourney() async {
    _isJourneyActive = false;
    _stopAutosaveTimer();
    final endEvent = JourneyEvent(
      eventType: JourneyEventType.journeyEnd,
      timestamp: DateTime.now(),
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    );
    _events.add(endEvent);
    final result = (track: List<JourneyPoint>.from(_gpsTrack), events: List<JourneyEvent>.from(_events), start: _journeyStartTime);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    await _persistTrack();
    return result;
  }

  Future<void> _persistTrack() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tmp = File('${dir.path}/journey_track.json.tmp');
      final file = File('${dir.path}/journey_track.json');
      final content = jsonEncode({
        'start': _journeyStartTime?.toIso8601String(),
        'active': _isJourneyActive,
        'track': _gpsTrack.map((p) => p.toJson()).toList(),
        'events': _events.map((e) => e.toJson()).toList(),
      });
      await tmp.writeAsString(content);
      if (await tmp.exists()) {
        await tmp.rename(file.path);
      }
    } catch (_) {}
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

  /// Create a snapshot object for the current journey. Does not modify state.
  Future<UmrahJourneySnapshot> snapshotJourney({required bool incomplete, String? notes}) async {
    // ensure events include journeyEnd if not active
    DateTime? end = _isJourneyActive ? null : DateTime.now();
    if (!incomplete && end == null) end = DateTime.now();

    return UmrahJourneySnapshot(
      id: _journeyStartTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      startTime: _journeyStartTime ?? DateTime.now(),
      endTime: end,
      events: List.from(_events),
      gpsTrack: List.from(_gpsTrack),
      completed: !incomplete,
      notes: notes,
      stepSummaries: [],
    );
  }

  /// Finalize the journey and clear internal state; returns record ready for history.
  Future<UmrahJourneyRecord> finalizeJourney({String? notes}) async {
    final snap = await snapshotJourney(incomplete: false, notes: notes);
    final record = UmrahJourneyRecord(
      id: snap.id,
      startTime: snap.startTime,
      endTime: snap.endTime ?? DateTime.now(),
      notes: snap.notes,
      events: snap.events,
      gpsTrack: snap.gpsTrack,
      completed: true,
      version: 1,
      stepSummaries: snap.stepSummaries,
    );
    // clear
    _isJourneyActive = false;
    _gpsTrack.clear();
    _events.clear();
    _journeyStartTime = null;
    _lastSavedPoint = null;
    _lastSavedTime = null;
    _stopAutosaveTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    await _persistTrack();
    notifyListeners();
    return record;
  }

  /// Capture current track as an incomplete record then clear state.
  Future<UmrahJourneyRecord> snapshotAndClear({String? notes}) async {
    final snap = await snapshotJourney(incomplete: true, notes: notes);
    final record = UmrahJourneyRecord(
      id: snap.id,
      startTime: snap.startTime,
      endTime: snap.endTime ?? DateTime.now(),
      notes: snap.notes,
      events: snap.events,
      gpsTrack: snap.gpsTrack,
      completed: false,
      version: 1,
      stepSummaries: snap.stepSummaries,
    );
    // clear state just like finalize
    _isJourneyActive = false;
    _gpsTrack.clear();
    _events.clear();
    _journeyStartTime = null;
    _lastSavedPoint = null;
    _lastSavedTime = null;
    _stopAutosaveTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, false);
    await _persistTrack();
    notifyListeners();
    return record;
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
  }}
