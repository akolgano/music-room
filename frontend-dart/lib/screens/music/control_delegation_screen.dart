// lib/screens/music/control_delegation_screen.dart
import 'package:flutter/material.dart';
import '../../core/core.dart';

class MusicControlDelegationScreen extends StatelessWidget {
  const MusicControlDelegationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.background, title: const Text('Control Delegation')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Control Delegation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Coming Soon', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
