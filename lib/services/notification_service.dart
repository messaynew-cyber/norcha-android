// The notification service — the thin layer between the planner and Android.
//
// SEPARATION
// ReminderPlanner (lib/core/reminders.dart) decides WHAT to say and WHEN. It is
// pure Dart, unit-tested, and knows nothing about Android. This file does the
// platform work and nothing else. That split is why the scheduling logic can be
// tested at all — the plugin is not mockable from here, so it must not contain
// decisions worth testing.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/holidays.dart';
import '../core/reminders.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'norcha_deadlines';
  static const _channelName = 'Deadlines';
  static const _channelDesc =
      'Reminders before Ethiopian holidays and gift seasons.';

  /// Prepare the plugin and the timezone database.
  /// MUST be called before any scheduling. Safe to call more than once.
  static Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local));
    } catch (_) {
      // A device that cannot report its zone is not a reason to crash the app.
      // Addis is the shop's own timezone, so it is the sane default.
      tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.defaultImportance,
    ));

    _ready = true;
  }

  /// Ask for permission. Called when the customer first shows interest in a
  /// deadline — not on launch. A prompt before they have seen anything is the
  /// fastest way to be denied forever.
  static Future<bool> requestPermission() async {
    await init();
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await impl?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule [reminders], replacing anything previously scheduled.
  ///
  /// Cancel-all first, deliberately: a stale reminder for an occasion that has
  /// passed is worse than no reminder.
  static Future<int> schedule(List<Reminder> reminders) async {
    await init();
    await _plugin.cancelAll();

    var count = 0;
    for (final r in reminders) {
      final fire = tz.TZDateTime.from(r.fireAt, tz.local);
      // The planner only produces future times, but a device whose clock moved
      // could still hand us a past one. Skipping is correct — zonedSchedule
      // throws on a past time.
      if (fire.isBefore(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        fire,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Required by flutter_local_notifications 17.x. On Android the date is
        // always interpreted in the device's own timezone, so this only affects
        // iOS — but the parameter is not optional and omitting it fails the
        // build. Declared explicitly rather than guessed from a newer version's
        // API, which is how withValues() broke the earlier build.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: r.occasionId,
      );
      count++;
    }
    return count;
  }

  /// Plan and schedule in one step, for the current moment.
  static Future<int> refresh({String lang = 'en'}) async {
    final planned = ReminderPlanner.plan(DateTime.now(), lang: lang);
    return schedule(planned);
  }

  /// How many notifications are pending. Shown to the customer rather than
  /// asserted — 'we will remind you' should be checkable.
  static Future<int> pendingCount() async {
    await init();
    final list = await _plugin.pendingNotificationRequests();
    return list.length;
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  @visibleForTesting
  static Future<List<int>> pendingIds() async {
    await init();
    final list = await _plugin.pendingNotificationRequests();
    return list.map((e) => e.id).toList();
  }
}

/// The next reminder the customer would receive, for display.
/// Null when nothing is scheduled, which is a normal state.
Future<DateTime?> nextReminderAt() async {
  final planned = ReminderPlanner.plan(DateTime.now());
  return ReminderPlanner.nextFire(planned);
}

/// The occasion the current reminders are for, for display in the UI.
Occasion? currentOccasion() => NorchaHolidays.current(DateTime.now());
