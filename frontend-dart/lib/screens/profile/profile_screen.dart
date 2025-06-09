// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';
import 'user_password_change_screen.dart';
import 'social_network_link_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded; 

  const ProfileScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends BaseScreen<ProfileScreen> {
  @override
  String get screenTitle => 'Profile';

  @override
  bool get showDrawer => !widget.isEmbedded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.loadProfile(auth.token);
    });
  }

  @override
  Widget buildContent() {
    final profileProvider = Provider.of<ProfileProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          
          SettingsSection(
            title: 'Account',
            items: [
              SettingsItem(
                icon: Icons.edit,
                title: 'Edit Profile', 
                subtitle: 'Update your profile information',
                onTap: () => _showEditProfileDialog(),
              ),
              SettingsItem(
                icon: Icons.content_copy,
                title: 'Copy User ID',
                subtitle: 'Share your user ID: ${auth.userId ?? "Unknown"}',
                onTap: () => _copyToClipboard(auth.userId ?? ''),
              ),
              SettingsItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your account security',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
            ],
          ),
          
          SettingsSection(
            title: 'Music',
            items: [
              SettingsItem(
                icon: Icons.library_music,
                title: 'My Library',
                subtitle: 'View your saved music',
                onTap: () => navigateTo(AppRoutes.home),
              ),
              SettingsItem(
                icon: Icons.high_quality,
                title: 'Audio Quality',
                subtitle: 'Set streaming quality',
                onTap: _showAudioQualityDialog,
              ),
              SettingsItem(
                icon: Icons.download,
                title: 'Downloads',
                subtitle: 'Manage your offline music',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
            ],
          ),
          
          SettingsSection(
            title: 'Social',
            items: [
              SettingsItem(
                icon: Icons.people,
                title: AppStrings.friends,
                subtitle: 'Manage your friends',
                onTap: () => navigateTo(AppRoutes.friends),
              ),
              SettingsItem(
                icon: Icons.share,
                title: 'Sharing',
                subtitle: 'Control sharing settings',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
              SettingsItem(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked accounts',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
            ],
          ),
          
          if (profileProvider.isPasswordUsable)
            SettingsSection(
              title: 'Security',
              items: [
                SettingsItem(
                  icon: Icons.password,
                  title: 'Password Change',
                  subtitle: 'Change your password',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const UserPasswordChangeScreen())),
                ),
              ],
            ),
          
          SettingsSection(
            title: 'App',
            items: [
              SettingsItem(
                icon: Icons.link,
                title: 'Link Social Network',
                subtitle: 'Connect social accounts',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const SocialNetworkLinkScreen())),
              ),
              SettingsItem(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Control notifications',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
              SettingsItem(
                icon: Icons.storage,
                title: 'Storage',
                subtitle: 'Manage app storage and cache',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
              SettingsItem(
                icon: Icons.info,
                title: 'About',
                subtitle: 'Version ${AppConstants.version}',
                onTap: _showAboutDialog,
              ),
              SettingsItem(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get help',
                onTap: () => showInfo(AppStrings.featureComingSoon),
              ),
            ],
          ),
          
          SettingsSection(
            title: 'Account Actions',
            items: [
              SettingsItem(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                onTap: _showSignOutDialog,
                color: Colors.orange,
              ),
              SettingsItem(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: _showDeleteAccountDialog,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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

  void _showEditProfileDialog() {
    DialogUtils.showTextInputDialog(
      context,
      title: 'Edit Username',
      initialValue: auth.username ?? '',
      hintText: 'Enter new username',
      validator: Validators.username,
    ).then((newUsername) {
      if (newUsername != null && newUsername != auth.username) {
        showInfo('Profile editing functionality coming soon!');
      }
    });
  }

  void _copyToClipboard(String text) {
    showSuccess('User ID copied to clipboard');
  }

  void _showAudioQualityDialog() {
    DialogUtils.showSelectionDialog<String>(
      context: context,
      title: 'Audio Quality',
      items: ['High (320kbps)', 'Normal (160kbps)', 'Low (96kbps)'],
      itemTitle: (quality) => quality,
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        showSuccess('Audio quality updated');
      }
    });
  }

  void _showAboutDialog() {
    DialogUtils.showAboutDialog(
      context: context,
      appName: AppConstants.appName,
      version: AppConstants.version,
      description: 'A collaborative music sharing platform',
      features: [
        'Real-time collaborative playlists',
        'Deezer integration for music discovery',
        'Social features and friend connections',
        'Multi-device synchronization',
      ],
    );
  }

  void _showSignOutDialog() {
    DialogUtils.showLogoutConfirmDialog(context).then((confirmed) {
      if (confirmed == true) {
        auth.logout();
      }
    });
  }

  void _showDeleteAccountDialog() {
    DialogUtils.showConfirmDialog(
      context,
      title: 'Delete Account',
      message: AppStrings.deleteAccountWarning,
      confirmText: 'Delete Account',
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed == true) {
        showError('Account deletion is not implemented yet');
      }
    });
  }
}
