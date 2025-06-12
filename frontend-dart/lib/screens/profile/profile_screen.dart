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
      final profileProvider = getProvider<ProfileProvider>();
      profileProvider.loadProfile(auth.token);
    });
  }

  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          
          _buildProfileInformationSection(),
          _buildSocialNetworkSection(),
          
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, _) {
              if (profileProvider.isPasswordUsable) {
                return _buildSecuritySection();
              }
              return const SizedBox.shrink();
            },
          ),
          
          _buildAccountActionsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return AppTheme.buildHeaderCard(
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
                    border: Border.all(color: Colors.white, width: 2),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ID: ${auth.userId ?? "Unknown"}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInformationSection() {
    return SettingsSection(
      title: 'Profile Information',
      items: [
        SettingsItem(
          icon: Icons.public,
          title: 'Public Information', 
          subtitle: 'Information visible to everyone',
          onTap: () => _showEditInformationDialog('public'),
        ),
        SettingsItem(
          icon: Icons.people,
          title: 'Friends Information',
          subtitle: 'Information visible to friends only',
          onTap: () => _showEditInformationDialog('friends'),
        ),
        SettingsItem(
          icon: Icons.lock,
          title: 'Private Information',
          subtitle: 'Information visible only to you',
          onTap: () => _showEditInformationDialog('private'),
        ),
        SettingsItem(
          icon: Icons.music_note,
          title: 'Music Preferences',
          subtitle: 'Your music tastes and preferences',
          onTap: _showMusicPreferencesDialog,
        ),
      ],
    );
  }

  Widget _buildSocialNetworkSection() {
    return SettingsSection(
      title: 'Social Network',
      items: [
        SettingsItem(
          icon: Icons.link,
          title: 'Link Social Account',
          subtitle: 'Connect Facebook or Google account',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const SocialNetworkLinkScreen())),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return SettingsSection(
      title: 'Security',
      items: [
        SettingsItem(
          icon: Icons.password,
          title: 'Change Password',
          subtitle: 'Change your account password',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => const UserPasswordChangeScreen())),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection() {
    return SettingsSection(
      title: 'Account',
      items: [
        SettingsItem(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: _showSignOutDialog,
          color: Colors.orange,
        ),
      ],
    );
  }

  void _showEditInformationDialog(String type) async {
    String title = '';
    String hint = '';
    
    switch (type) {
      case 'public':
        title = 'Edit Public Information';
        hint = 'Information visible to everyone';
        break;
      case 'friends':
        title = 'Edit Friends Information';
        hint = 'Information visible to friends only';
        break;
      case 'private':
        title = 'Edit Private Information';
        hint = 'Information visible only to you';
        break;
    }

    final result = await DialogUtils.showMultiInputDialog(
      context: context,
      title: title,
      fields: [
        InputField(key: 'bio', label: 'Bio', hint: 'Tell others about yourself'),
        InputField(key: 'location', label: 'Location', hint: 'Your location'),
        InputField(key: 'website', label: 'Website', hint: 'Your website or social media'),
      ],
    );
    
    if (result != null) {
      showSuccess('$type information updated successfully');
    }
  }

  void _showMusicPreferencesDialog() async {
    final result = await DialogUtils.showMultiInputDialog(
      context: context,
      title: 'Music Preferences',
      fields: [
        InputField(key: 'genres', label: 'Favorite Genres', hint: 'Rock, Pop, Jazz, etc.'),
        InputField(key: 'artists', label: 'Favorite Artists', hint: 'Your top artists'),
        InputField(key: 'mood', label: 'Listening Mood', hint: 'Happy, Relaxed, Energetic, etc.'),
      ],
    );
    
    if (result != null) {
      showSuccess('Music preferences updated successfully');
    }
  }

  void _showSignOutDialog() async {
    final confirmed = await showConfirmDialog(
      'Sign Out',
      AppStrings.confirmLogout,
      isDangerous: true,
    );
    
    if (confirmed) {
      auth.logout();
    }
  }
}
