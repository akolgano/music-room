// lib/screens/profile/components/profile_sections.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';

class ProfileSections extends StatelessWidget {
  final AuthProvider authProvider;
  final Function(String) onShowComingSoon;
  final Function(AuthProvider) onShowSignOutDialog;
  final VoidCallback onShowDeleteAccountDialog;
  final Function(String, String) onShowEditDialog;
  final Function(String) onCopyToClipboard;
  final VoidCallback onShowAudioQualityDialog;
  final VoidCallback onShowAboutDialog;

  const ProfileSections({
    Key? key,
    required this.authProvider,
    required this.onShowComingSoon,
    required this.onShowSignOutDialog,
    required this.onShowDeleteAccountDialog,
    required this.onShowEditDialog,
    required this.onCopyToClipboard,
    required this.onShowAudioQualityDialog,
    required this.onShowAboutDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'Account',
          [
            _buildItem(
              Icons.edit,
              'Edit Profile',
              'Update your username and profile info',
              () => onShowEditDialog('Username', authProvider.username ?? ''),
            ),
            _buildItem(
              Icons.content_copy,
              'Copy User ID',
              'Share your user ID: ${authProvider.userId ?? "Unknown"}',
              () => onCopyToClipboard(authProvider.userId ?? ''),
            ),
            _buildItem(
              Icons.security,
              'Privacy & Security',
              'Manage your account security settings',
              () => onShowComingSoon('Privacy settings'),
            ),
          ],
        ),
        _buildSection(
          'Music',
          [
            _buildItem(
              Icons.library_music,
              'My Library',
              'View your saved playlists and tracks',
              () => Navigator.of(context).pushNamed('/playlists'),
            ),
            _buildItem(
              Icons.high_quality,
              'Audio Quality',
              'Set your preferred streaming quality',
              onShowAudioQualityDialog,
            ),
            _buildItem(
              Icons.download,
              'Downloads',
              'Manage your offline music',
              () => onShowComingSoon('Offline downloads'),
            ),
          ],
        ),
        _buildSection(
          'Social',
          [
            _buildItem(
              Icons.people,
              'Friends',
              'Manage your music friends',
              () => Navigator.of(context).pushNamed(AppRoutes.friends),
            ),
            _buildItem(
              Icons.share,
              'Sharing',
              'Control how you share music',
              () => onShowComingSoon('Sharing preferences'),
            ),
            _buildItem(
              Icons.block,
              'Blocked Users',
              'Manage blocked accounts',
              () => onShowComingSoon('Blocked users'),
            ),
          ],
        ),
        _buildSection(
          'App',
          [
            _buildItem(
              Icons.notifications,
              'Notifications',
              'Control your notification preferences',
              () => onShowComingSoon('Notifications'),
            ),
            _buildItem(
              Icons.storage,
              'Storage',
              'Manage app storage and cache',
              () => onShowComingSoon('Storage management'),
            ),
            _buildItem(
              Icons.info,
              'About',
              'Version ${AppConstants.version}',
              onShowAboutDialog,
            ),
          ],
        ),
        _buildSection(
          'Support',
          [
            _buildItem(
              Icons.help,
              'Help & Support',
              'Get help with Music Room',
              () => onShowComingSoon('Help center'),
            ),
            _buildItem(
              Icons.feedback,
              'Send Feedback',
              'Help us improve Music Room',
              () => onShowComingSoon('Feedback'),
            ),
            _buildItem(
              Icons.bug_report,
              'Report a Bug',
              'Found something wrong? Let us know',
              () => onShowComingSoon('Bug reporting'),
            ),
          ],
        ),
        _buildSection(
          'Account Actions',
          [
            _buildItem(
              Icons.logout,
              'Sign Out',
              'Sign out of your account',
              () => onShowSignOutDialog(authProvider),
              color: Colors.orange,
            ),
            _buildItem(
              Icons.delete_forever,
              'Delete Account',
              'Permanently delete your account',
              onShowDeleteAccountDialog,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        Card(
          color: AppTheme.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(
                      height: 1,
                      color: AppTheme.surfaceVariant,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
  }) {
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
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: itemColor.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: itemColor.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
