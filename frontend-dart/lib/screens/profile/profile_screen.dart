// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/unified_components.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';
import 'user_password_change_screen.dart';
import 'social_network_link_screen.dart';
import 'profile_info_screen.dart';

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
          _buildSecuritySection(),
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
    return UnifiedComponents.settingsSection(
      title: 'Profile Information',
      items: [
        UnifiedComponents.settingsItem(
          icon: Icons.edit,
          title: 'Edit Profile Information', 
          subtitle: 'Manage public, private, friend, and music info',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileInfoScreen()),
          ),
        ),
        UnifiedComponents.settingsItem(
          icon: Icons.link,
          title: 'Social Network Links',
          subtitle: 'Connect Facebook or Google account',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SocialNetworkLinkScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (!profileProvider.isPasswordUsable) {
          return const SizedBox.shrink();
        }

        return UnifiedComponents.settingsSection(
          title: 'Security',
          items: [
            UnifiedComponents.settingsItem(
              icon: Icons.password,
              title: 'Change Password',
              subtitle: 'Change your account password',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPasswordChangeScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountActionsSection() {
    return UnifiedComponents.settingsSection(
      title: 'Account',
      items: [
        UnifiedComponents.settingsItem(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: _showSignOutDialog,
          color: Colors.orange,
        ),
      ],
    );
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
