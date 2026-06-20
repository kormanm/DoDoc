import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/documents_api.dart';
import 'api/tasks_api.dart';
import 'api/users_api.dart';
import 'app.dart';
import 'auth/auth_service.dart';
import 'auth/auth_state.dart';
import 'consent/consent_service.dart';
import 'notifications/daily_alarm.dart';
import 'notifications/notification_service.dart';
import 'share/share_handler.dart';
import 'share/share_receiver.dart';
import 'todo/todo_sync_service.dart';
import 'tasks/data/local_task_dao.dart';
import 'tasks/data/task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authState = AuthState();
  final authService = AuthService(
    const FlutterAppAuth(),
    const FlutterSecureStorage(),
    authState,
  );
  await authService.restoreSession();

  final apiClient = ApiClient(authService);
  final usersApi = UsersApi(apiClient);
  final tasksApi = TasksApi(apiClient);
  final documentsApi = DocumentsApi(apiClient);
  final todoSyncService = TodoSyncService(authService);

  final db = AppDatabase();
  final notifications = NotificationService();
  await notifications.init();

  await todoSyncService.initialize();

  final taskRepository =
      TaskRepository(db, tasksApi, notifications, todoSyncService);
  final consentService = ConsentService(usersApi);

  if (authState.isAuthenticated) {
    await consentService.loadFromProfile();
    await todoSyncService.ensureConnectedForSession(interactiveIfMissing: false);
    await taskRepository.syncAll();
  }

  final shareHandler = ShareHandler(
    documentsApi,
    () => consentService.persistDocs,
  );

  await DailyAlarm.schedule();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authState),
        Provider.value(value: authService),
        Provider.value(value: usersApi),
        Provider.value(value: documentsApi),
        ChangeNotifierProvider.value(value: todoSyncService),
        ChangeNotifierProvider.value(value: taskRepository),
        ChangeNotifierProvider.value(value: consentService),
        Provider.value(value: shareHandler),
      ],
      child: ShareDocApp(
        shareReceiver: ShareReceiver(shareHandler, taskRepository),
      ),
    ),
  );
}
