// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/app_core.dart';
import '../../utils/snackbar_utils.dart';
import 'user_password_change_screen.dart';
import 'social_network_link_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded; 

  const ProfileScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      profileProvider.loadProfile(auth.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    
    if (widget.isEmbedded) {
      return _buildContent(auth, profileProvider);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Profile'),
      ),
      body: _buildContent(auth, profileProvider),
    );
  }

  Widget _buildContent(AuthProvider auth, ProfileProvider profileProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(auth),
          const SizedBox(height: 16),
          _buildSection('Account', [
            _buildItem(Icons.edit, 'Edit Profile', 'Update your profile information', 
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
            _buildItem(Icons.content_copy, 'Copy User ID', 'Share your user ID: ${auth.userId ?? "Unknown"}',
                () => _copyToClipboard(auth.userId ?? '')),
            _buildItem(Icons.security, 'Privacy & Security', 'Manage your account security', 
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
          ]),
          _buildSection('Music', [
            _buildItem(Icons.library_music, 'My Library', 'View your saved music', 
                () => Navigator.pushNamed(context, AppRoutes.home)),
            _buildItem(Icons.high_quality, 'Audio Quality', 'Set streaming quality', 
                () => _showAudioQualityDialog()),
            _buildItem(Icons.download, 'Downloads', 'Manage your offline music',
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
          ]),
          _buildSection('Social', [
            _buildItem(Icons.people, AppStrings.friends, 'Manage your friends',
                () => Navigator.pushNamed(context, AppRoutes.friends)),
            _buildItem(Icons.share, 'Sharing', 'Control sharing settings', 
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
            _buildItem(Icons.block, 'Blocked Users', 'Manage blocked accounts',
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
          ]),
          if (profileProvider.isPasswordUsable) ...[
            _buildSection('Security', [
              _buildItem(Icons.password, 'Password Change', 'Change your password',
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const UserPasswordChangeScreen()))),
            ]),
          ],
          _buildSection('App', [
            _buildItem(Icons.link, 'Link Social Network', 'Connect social accounts',
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const SocialNetworkLinkScreen()))),
            _buildItem(Icons.notifications, 'Notifications', 'Control notifications',
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
            _buildItem(Icons.info, 'About', 'Version ${AppConstants.version}', 
                () => _showAboutDialog()),
            _buildItem(Icons.help, 'Help & Support', 'Get help', 
                () => SnackBarUtils.showInfo(context, AppStrings.featureComingSoon)),
          ]),
          Card(
            color: AppTheme.surface,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
                  onTap: () => _showSignOutDialog(context, auth),
                ),
                const Divider(height: 1, color: AppTheme.surfaceVariant),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete your account', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.black),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
              ],
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, color: AppTheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${auth.userId ?? "Unknown"}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ],
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

  Widget _buildItem(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    final itemColor = color ?? Colors.white;
    final iconColor = color ?? AppTheme.primary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: itemColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: itemColor.withOpacity(0.7), fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: itemColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _copyToClipboard(String text) {
    SnackBarUtils.showSuccess(context, 'User ID copied to clipboard');
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Audio Quality', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('High (320kbps)', style: TextStyle(color: Colors.white)),
              value: 'high',
              groupValue: 'high',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Normal (160kbps)', style: TextStyle(color: Colors.white)),
              value: 'normal',
              groupValue: 'high',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Low (96kbps)', style: TextStyle(color: Colors.white)),
              value: 'low',
              groupValue: 'high',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SnackBarUtils.showSuccess(context, 'Audio quality updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('About Music Room', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${AppConstants.version}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            const Text('A collaborative music sharing platform', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('© 2024 Music Room Team', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently delete your account and all associated data:', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('• All your playlists', style: TextStyle(color: Colors.grey)),
            Text('• Your friend connections', style: TextStyle(color: Colors.grey)),
            Text('• Your listening history', style: TextStyle(color: Colors.grey)),
            Text('• Your profile information', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('This action cannot be undone.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SnackBarUtils.showError(context, 'Account deletion is not implemented yet');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
