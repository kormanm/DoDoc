import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'auth/auth_state.dart';
import 'consent/consent_screen.dart';
import 'consent/consent_service.dart';
import 'settings/settings_screen.dart';
import 'share/share_receiver.dart';
import 'todo/todo_sync_service.dart';
import 'tasks/data/task_repository.dart';
import 'tasks/models/task.dart';
import 'tasks/ui/task_detail_screen.dart';
import 'tasks/ui/task_list_screen.dart';

class ShareDocApp extends StatefulWidget {
  final ShareReceiver shareReceiver;

  const ShareDocApp({super.key, required this.shareReceiver});

  @override
  State<ShareDocApp> createState() => _ShareDocAppState();
}

class _ShareDocAppState extends State<ShareDocApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _uriSub;
  late final _LifecycleObserver _observer;
  String? _pendingTaskId;
  DateTime? _lastResumeSyncAt;

  @override
  void initState() {
    super.initState();
    _observer = _LifecycleObserver(_onResumed);
    WidgetsBinding.instance.addObserver(_observer);
    widget.shareReceiver.init();
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _uriSub?.cancel();
    widget.shareReceiver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ShareDoc',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const _LoginScreen();
          }
          return Consumer<ConsentService>(
            builder: (context, consent, _) {
              if (!consent.consentShown) {
                return ConsentScreen(
                  onComplete: () async {
                    await context.read<TaskRepository>().syncAll();
                    _tryOpenPendingTask();
                  },
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _tryOpenPendingTask();
              });
              return const _HomeScreen();
            },
          );
        },
      ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ShareDoc',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Transform documents into actionable tasks'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                final authService = context.read<AuthService>();
                final taskRepository = context.read<TaskRepository>();
                final consentService = context.read<ConsentService>();
                final todoSync = context.read<TodoSyncService>();
                final result =
                    await authService.signIn(forceAccountSelection: true);
                if (!context.mounted) return;
                if (result.isFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.failure!.message),
                      duration: const Duration(seconds: 10),
                    ),
                  );
                  return;
                }

                await consentService.loadFromProfile();
                await todoSync.ensureConnectedForSession(
                  interactiveIfMissing: true,
                );
                await taskRepository.syncAll();
              },
              child: const Text('Sign in or create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShareDoc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => context.read<TaskRepository>().syncAll(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: const TaskListScreen(),
    );
  }
}

extension on _ShareDocAppState {
  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {}

    _uriSub = _appLinks.uriLinkStream.listen(_handleIncomingUri);
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != 'sharedoc' || uri.host != 'task') return;
    if (uri.pathSegments.isEmpty) return;
    _pendingTaskId = uri.pathSegments.first;
    _tryOpenPendingTask();
  }

  Future<void> _tryOpenPendingTask() async {
    final taskId = _pendingTaskId;
    if (taskId == null || !mounted) return;

    final authState = context.read<AuthState>();
    final consent = context.read<ConsentService>();
    final repo = context.read<TaskRepository>();
    if (!authState.isAuthenticated || !consent.consentShown) return;

    final existing = _findTaskById(repo.tasks, taskId);
    if (existing == null) {
      await repo.syncAll();
      if (!mounted) return;
    }

    final resolved = _findTaskById(repo.tasks, taskId);
    if (resolved == null) {
      _pendingTaskId = null;
      final currentContext = _navigatorKey.currentContext;
      if (currentContext != null && currentContext.mounted) {
        ScaffoldMessenger.maybeOf(currentContext)?.showSnackBar(
          const SnackBar(content: Text('Task not found')),
        );
      }
      return;
    }

    _pendingTaskId = null;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: taskId),
      ),
    );
  }

  void _onResumed() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastResumeSyncAt != null &&
        now.difference(_lastResumeSyncAt!) < const Duration(minutes: 2)) {
      return;
    }
    _lastResumeSyncAt = now;

    final authState = context.read<AuthState>();
    final consent = context.read<ConsentService>();
    if (authState.isAuthenticated && consent.consentShown) {
      unawaited(_reconnectAndSync());
    }
  }

  Future<void> _reconnectAndSync() async {
    await context.read<TodoSyncService>().ensureConnectedForSession(
          interactiveIfMissing: false,
        );
    if (!mounted) return;
    await context.read<TaskRepository>().syncAll();
  }

  Task? _findTaskById(List<Task> tasks, String taskId) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback _onResumed;

  _LifecycleObserver(this._onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }
}
