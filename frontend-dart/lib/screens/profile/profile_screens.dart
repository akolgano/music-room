import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import '../../providers/profile_providers.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../core/logging_core.dart';
import '../../widgets/status_widgets.dart';
import '../../widgets/avatar_widgets.dart';
import '../../widgets/sections_widgets.dart';
import '../base_screens.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends BaseScreen<ProfileScreen> with UserActionLoggingMixin {
  List<Map<String, dynamic>> _musicPreferences = [];

  @override
  String get screenTitle => 'Profile';
  @override
  bool get showBackButton => !widget.isEmbedded;
  @override
  bool get showMiniPlayer => !widget.isEmbedded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
    });
  }

  Future<void> _initializeProfile() async {
    final profileProvider = getProvider<ProfileProvider>();
    try {
      await profileProvider.loadProfile(auth.token);
      await _loadMusicPreferences();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileScreen] Error initializing profile: $e');
      }
    }
  }

  Future<void> _loadMusicPreferences() async {
    try {
      final profileProvider = getProvider<ProfileProvider>();
      final preferences = await profileProvider.getMusicPreferences(auth.token!);
      setState(() {
        _musicPreferences = preferences;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileScreen] Error loading music preferences: $e');
      }
    }
  }


  @override
  Widget buildContent() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading) return buildLoadingState(message: 'Loading profile...');
        return RefreshIndicator(
          onRefresh: () => profileProvider.loadProfile(auth.token),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
            child: Column(
              children: [
                _buildProfileHeader(profileProvider),
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                Center(child: const ConnectionStatusIndicator()),
                SizedBox(height: ThemeUtils.getResponsivePadding(context)),
                ProfileSectionsWidget(
                  profileProvider: profileProvider,
                  auth: auth,
                  musicPreferences: _musicPreferences,
                  handleUpdateSuccess: _handleUpdateSuccess,
                  updateVisibility: _updateVisibility,
                  showSignOutDialog: _showSignOutDialog,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(ProfileProvider profileProvider) {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          ProfileAvatarWidget(
            profileProvider: profileProvider,
            auth: auth,
            onSuccess: () => showSuccess('Avatar updated successfully!'),
            onError: showError,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Avatar Privacy:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 8),
              _buildVisibilityIcon(profileProvider.avatarVisibility),
              const SizedBox(width: 4),
              PopupMenuButton<VisibilityLevel>(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 16),
                onSelected: (visibility) => _updateVisibility(profileProvider, 'avatarVisibility', visibility),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: VisibilityLevel.public,
                    child: Row(
                      children: [
                        Icon(Icons.public, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text('Public'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: VisibilityLevel.friends,
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('Friends Only'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: VisibilityLevel.private,
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Text('Private'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profileProvider.name ?? profileProvider.username ?? auth.username ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildVisibilityIcon(profileProvider.nameVisibility),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'ID: ${profileProvider.userId ?? auth.userId ?? "Unknown"}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityIcon(VisibilityLevel? visibility) {
    switch (visibility) {
      case VisibilityLevel.public:
        return const Icon(Icons.public, color: Colors.green, size: 16);
      case VisibilityLevel.friends:
        return const Icon(Icons.people, color: Colors.blue, size: 16);
      case VisibilityLevel.private:
        return const Icon(Icons.lock, color: Colors.orange, size: 16);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
    }
  }

  void _handleUpdateSuccess(String fieldName, ProfileProvider profileProvider) {
    showSuccess('$fieldName updated successfully');
  }

  Future<void> _updateVisibility(ProfileProvider profileProvider, String field, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(auth.token,
      avatarVisibility: field == 'avatarVisibility' ? visibility : null,
      nameVisibility: field == 'nameVisibility' ? visibility : null,
      locationVisibility: field == 'locationVisibility' ? visibility : null,
      bioVisibility: field == 'bioVisibility' ? visibility : null,
      phoneVisibility: field == 'phoneVisibility' ? visibility : null,
      friendInfoVisibility: field == 'friendInfoVisibility' ? visibility : null,
      musicPreferencesVisibility: field == 'musicPreferencesVisibility' ? visibility : null,
    );
    if (success) {
      final fieldNames = {
        'avatarVisibility': 'Avatar', 'nameVisibility': 'Name', 'locationVisibility': 'Location', 'bioVisibility': 'Bio',
        'phoneVisibility': 'Phone', 'friendInfoVisibility': 'Friend info', 'musicPreferencesVisibility': 'Music preferences',
      };
      showSuccess('${fieldNames[field]} visibility updated');

      if (mounted) {
        setState(() {});
      }
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