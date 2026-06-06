import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'auth/auth_state.dart';
import 'consent/consent_screen.dart';
import 'consent/consent_service.dart';
import 'settings/settings_screen.dart';
import 'share/share_receiver.dart';
import 'tasks/data/task_repository.dart';
import 'tasks/ui/task_list_screen.dart';

class ShareDocApp extends StatefulWidget {
  final ShareReceiver shareReceiver;

  const ShareDocApp({super.key, required this.shareReceiver});

  @override
  State<ShareDocApp> createState() => _ShareDocAppState();
}

class _ShareDocAppState extends State<ShareDocApp> {
  @override
  void initState() {
    super.initState();
    widget.shareReceiver.init();
  }

  @override
  void dispose() {
    widget.shareReceiver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                  onComplete: () {
                    context.read<TaskRepository>().loadAll();
                  },
                );
              }
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
                final result = await authService.signIn();
                if (result.isSuccess && context.mounted) {
                  final usersApi =
                      context.read<TaskRepository>();
                  await context.read<ConsentService>().loadFromProfile();
                  await usersApi.loadAll();
                }
              },
              child: const Text('Sign in with Microsoft'),
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
