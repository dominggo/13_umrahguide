import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'umrah_location.dart';
import 'journey_models.dart';

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
    notifyListeners();
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
      final d = _distanceMeters(pos.latitude, pos.longitude, loc.center.latitude, loc.center.longitude);
      if (d <= loc.radiusMeters && d < minDist) {
        minDist = d;
        detected = loc;
      }
    }
    _currentZone = detected;

    // Record GPS track if journey active
    if (_isJourneyActive) {
      _gpsTrack.add(JourneyPoint(lat: pos.latitude, lng: pos.longitude, timestamp: DateTime.now()));
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

  double _rad(double deg) => deg * math.pi / 180;

  void manualOverrideZone(UmrahLocation? zone) {
    _manualZone = zone;
    notifyListeners();
  }

  // ── Journey control ───────────────────────────────────────────────────────

  Future<void> startJourney() async {
    _gpsTrack.clear();
    _events.clear();
    _journeyStartTime = DateTime.now();
    _isJourneyActive = true;
    _events.add(JourneyEvent(
      eventType: JourneyEventType.journeyStart,
      timestamp: _journeyStartTime!,
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
    ));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journeyActiveKey, true);
  }

  Future<void> logEvent(JourneyEvent event) async {
    _events.add(event);
    await _persistTrack();
  }

  Future<({List<JourneyPoint> track, List<JourneyEvent> events, DateTime? start})> endJourney() async {
    _isJourneyActive = false;
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
      final file = File('${dir.path}/journey_track.json');
      await file.writeAsString(jsonEncode({
        'track': _gpsTrack.map((p) => p.toJson()).toList(),
        'events': _events.map((e) => e.toJson()).toList(),
      }));
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _connectSub?.cancel();
    super.dispose();
  }
}
