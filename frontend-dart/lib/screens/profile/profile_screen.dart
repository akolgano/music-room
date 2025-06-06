// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_core.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.person, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.displayName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${auth.userId ?? "Unknown"}',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('Account', [
              _buildItem(Icons.edit, 'Edit Profile', 'Update your profile information', () {}),
              _buildItem(Icons.security, 'Privacy & Security', 'Manage your account security', () {}),
            ]),
            _buildSection('Music', [
              _buildItem(Icons.library_music, 'My Library', 'View your saved music', () {}),
              _buildItem(Icons.high_quality, 'Audio Quality', 'Set streaming quality', () {}),
            ]),
            _buildSection('Social', [
              _buildItem(Icons.people, 'Friends', 'Manage your friends', () {}),
              _buildItem(Icons.share, 'Sharing', 'Control sharing settings', () {}),
            ]),
            _buildSection('App', [
              _buildItem(Icons.info, 'About', 'Version ${AppConstants.version}', () {}),
              _buildItem(Icons.help, 'Help & Support', 'Get help', () {}),
            ]),
            Card(
              color: AppTheme.surface,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
                onTap: () => _showSignOutDialog(context, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ),
        Card(
          color: AppTheme.surface,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1) const Divider(height: 1, color: AppTheme.surfaceVariant),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(AppStrings.logout, style: TextStyle(color: Colors.white)),
        content: const Text(AppStrings.confirmLogout, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Signed In'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(AppStrings.logout, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
