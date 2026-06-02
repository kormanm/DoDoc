import 'package:flutter/material.dart';

class ShareDocApp extends StatelessWidget {
  const ShareDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareDoc',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('ShareDocApp')),
      ),
    );
  }
}
