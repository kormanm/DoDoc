import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../tasks/data/local_task_dao.dart';
import 'notification_service.dart';

class DailyAlarm {
  static const _alarmId = 0;

  static Future<void> schedule() async {
    await AndroidAlarmManager.initialize();
    await AndroidAlarmManager.periodic(
      const Duration(hours: 24),
      _alarmId,
      _callback,
      exact: true,
      wakeup: true,
      startAt: _next8am(),
    );
  }

  static DateTime _next8am() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 8);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  @pragma('vm:entry-point')
  static Future<void> _callback() async {
    final db = AppDatabase();
    final notifications = NotificationService();
    await notifications.init();
    final todayTasks = await db.getTodayTasks();
    await notifications.rebuildNotification(todayTasks);
  }
}
