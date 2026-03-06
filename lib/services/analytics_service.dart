import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Static wrapper around Firebase Analytics.
/// All methods are safe no-ops when [initialized] is false.
class AnalyticsService {
  /// Set to true after Firebase.initializeApp() succeeds.
  static bool initialized = false;

  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics? get _instance {
    if (!initialized) return null;
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics;
  }

  static Future<void> _log(String name,
      [Map<String, Object>? params]) async {
    try {
      await _instance?.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics error ($name): $e');
    }
  }

  /// Logged when the user taps "Mulakan Umrah".
  static Future<void> logJourneyStarted() =>
      _log('journey_started');

  /// Logged when the user taps "Selesai Ibadah Umrah".
  static Future<void> logJourneyCompleted(
          {required int checkpointsCompleted}) =>
      _log('journey_completed',
          {'checkpoints_completed': checkpointsCompleted});

  /// Logged when the user confirms a checkpoint end.
  static Future<void> logCheckpointCompleted(
          {required int checkpointNum, required String name}) =>
      _log('checkpoint_completed',
          {'checkpoint_num': checkpointNum, 'checkpoint_name': name});

  /// Logged when a step is opened from the journey screen.
  static Future<void> logStepViewed({required String stepId}) =>
      _log('step_viewed', {'step_id': stepId});
}
