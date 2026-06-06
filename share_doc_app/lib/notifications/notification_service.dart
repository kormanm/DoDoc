import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../tasks/models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  static const _channelId = 'sharedoc_today';
  static const _notificationId = 1;

  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  Future<void> rebuildNotification(List<Task> todayTasks) async {
    if (todayTasks.isEmpty) {
      await _plugin.cancel(_notificationId);
      return;
    }

    final lines = todayTasks
        .take(5)
        .map((t) => '${_severityIcon(t.severity)} ${t.title}')
        .toList();

    final body = lines.join('\n');
    final remaining = todayTasks.length > 5
        ? '\n+${todayTasks.length - 5} more'
        : '';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'Today\'s Tasks',
      channelDescription: 'Persistent notification showing tasks due today',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      styleInformation: BigTextStyleInformation(body + remaining),
    );

    await _plugin.show(
      _notificationId,
      '${todayTasks.length} task${todayTasks.length == 1 ? '' : 's'} due today',
      body + remaining,
      NotificationDetails(android: androidDetails),
    );
  }

  String _severityIcon(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return '[!]';
      case Severity.high:
        return '[H]';
      case Severity.medium:
        return '[M]';
      case Severity.low:
        return '[L]';
    }
  }
}
