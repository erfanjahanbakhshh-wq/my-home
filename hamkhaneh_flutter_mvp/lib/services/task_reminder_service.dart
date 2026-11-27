import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/household_store.dart';

/// One local reminder per open task, at 09:00 local time on the calendar day
/// before its due date. This is device-local (not a server push notification).
class TaskReminderService {
  TaskReminderService._();
  static final TaskReminderService instance = TaskReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Exact alarms improve punctuality. If Android denies the special access,
    // scheduling below safely falls back to inexact allow-while-idle.
    await android?.requestExactAlarmsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  int _notificationId(String taskId) {
    // Stable FNV-1a hash (Dart's String.hashCode is not stable between launches).
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 0x40000000 | (hash & 0x3fffffff);
  }

  Future<void> synchronize(Iterable<HomeTask> tasks) async {
    if (!_initialized) return;
    try {
      final eligible = tasks.where((task) => task.id.isNotEmpty && !task.done).toList();
      final desired = <int>{};
      for (final task in eligible) {
        final id = _notificationId(task.id);
        desired.add(id);
        await _schedule(task, id);
      }
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= 0x40000000 && request.id < 0x80000000 && !desired.contains(request.id)) {
          await _plugin.cancel(request.id);
        }
      }
    } catch (error, stack) {
      debugPrint('Task reminder sync failed: $error\n$stack');
    }
  }

  Future<void> _schedule(HomeTask task, int id) async {
    final now = DateTime.now();
    final dueDay = DateTime(task.due.year, task.due.month, task.due.day);
    final today = DateTime(now.year, now.month, now.day);
    if (!dueDay.isAfter(today)) {
      await _plugin.cancel(id);
      return;
    }
    var reminder = dueDay.subtract(const Duration(days: 1)).add(const Duration(hours: 9));
    // A task entered after 09:00 on the immediately preceding day still gets
    // a prompt shortly after creation; older/overdue reminders are discarded.
    if (!reminder.isAfter(now)) {
      if (reminder.year == today.year && reminder.month == today.month && reminder.day == today.day) {
        reminder = now.add(const Duration(minutes: 1));
      } else {
        await _plugin.cancel(id);
        return;
      }
    }
    final zonedTime = tz.TZDateTime.from(reminder, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_deadline_reminders', 'یادآوری موعد کارها',
        channelDescription: 'یادآوری یک روز پیش از موعد کارهای خانه',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id, 'یادآوری کار خانه', '«${task.title}» فردا موعد دارد.', zonedTime, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    } on PlatformException {
      await _plugin.zonedSchedule(
        id, 'یادآوری کار خانه', '«${task.title}» فردا موعد دارد.', zonedTime, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= 0x40000000 && request.id < 0x80000000) {
          await _plugin.cancel(request.id);
        }
      }
    } catch (error) {
      debugPrint('Task reminder cancellation failed: $error');
    }
  }
}
