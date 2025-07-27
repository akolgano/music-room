import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme_utils.dart';
import '../../core/validators.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';
import 'user_password_change_screen.dart';
import 'social_network_link_screen.dart';
import 'widgets/music_preference_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded; 
  const ProfileScreen({super.key, this.isEmbedded = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends BaseScreen<ProfileScreen> {
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
      final profileProvider = getProvider<ProfileProvider>();
      profileProvider.loadProfile(auth.token);
      _loadMusicPreferences();
    });
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
                _buildAccountInfoSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                _buildPublicInfoSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                _buildContactInfoSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                _buildFriendInfoSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                _buildMusicPreferencesSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
                _buildSocialAccountsSection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2), 
                _buildSecuritySection(profileProvider), 
                SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2), 
                _buildAccountActionsSection(),
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
          GestureDetector(
            onTap: profileProvider.isLoading 
                ? null 
                : () => _editAvatar(profileProvider),
            child: Stack(
              children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: profileProvider.avatarUrl?.isNotEmpty == true
                      ? null
                      : LinearGradient(begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: profileProvider.avatarUrl?.isNotEmpty == true
                    ? ClipOval(
                        child: profileProvider.avatarUrl!.startsWith('data:')
                            ? Image.memory(
                                base64Decode(profileProvider.avatarUrl!.split(',')[1]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialsAvatar(profileProvider),
                              )
                            : Image.network(
                                profileProvider.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialsAvatar(profileProvider),
                              ),
                      )
                    : _buildInitialsAvatar(profileProvider),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: profileProvider.isLoading 
                      ? null 
                      : () => _editAvatar(profileProvider),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: profileProvider.isLoading 
                          ? Colors.grey 
                          : AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: profileProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                  ),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profileProvider.name ?? profileProvider.username ?? auth.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildVisibilityIcon(profileProvider.avatarVisibility),
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
                Text(
                  'ID: ${profileProvider.userId ?? auth.userId ?? "Unknown"}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Account',
      items: [
        _buildInfoItem(
          icon: Icons.person,
          title: 'Username',
          value: profileProvider.username ?? 'Not set',
          isEditable: false,
        ),
        _buildInfoItem(
          icon: Icons.email,
          title: 'Email',
          value: profileProvider.userEmail ?? 'Not set',
          isEditable: false,
        ),
      ],
    );
  }

  Widget _buildPublicInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Public Info',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.person_outline,
          title: 'Name',
          value: profileProvider.name ?? 'Not set',
          visibility: profileProvider.nameVisibility,
          onEdit: () => _editName(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'nameVisibility', visibility),
        ),
        _buildInfoItemWithVisibility(
          icon: Icons.location_on,
          title: 'Location',
          value: profileProvider.location ?? 'Not specified',
          visibility: profileProvider.locationVisibility,
          onEdit: () => _editLocation(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'locationVisibility', visibility),
        ),
        _buildInfoItemWithVisibility(
          icon: Icons.info,
          title: 'Bio',
          value: profileProvider.bio ?? 'No bio yet',
          visibility: profileProvider.bioVisibility,
          onEdit: () => _editBio(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'bioVisibility', visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Contact',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.phone,
          title: 'Phone',
          value: profileProvider.phone ?? 'Not set',
          visibility: profileProvider.phoneVisibility,
          onEdit: () => _editPhone(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'phoneVisibility', visibility),
        ),
      ],
    );
  }

  Widget _buildFriendInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Friends',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.people,
          title: 'Friend Info',
          value: profileProvider.friendInfo ?? 'No friend info',
          visibility: profileProvider.friendInfoVisibility,
          onEdit: () => _editFriendInfo(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'friendInfoVisibility', visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildMusicPreferencesSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Music',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.music_note, 
          title: 'Music Genres',
          value: profileProvider.musicPreferences?.isNotEmpty == true
              ? profileProvider.musicPreferences!.join(', ')
              : 'No preferences set',
          visibility: profileProvider.musicPreferencesVisibility,
          onEdit: () => _editMusicPreferences(profileProvider),
          onVisibilityChanged: (visibility) => _updateVisibility(profileProvider, 'musicPreferencesVisibility', visibility),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSocialAccountsSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Social',
      items: [
        if (profileProvider.socialType != null) ...[
          _buildInfoItem(
            icon: profileProvider.socialType == 'facebook' ? Icons.facebook : Icons.g_mobiledata,
            title: '${profileProvider.socialType} Account',
            value: profileProvider.socialName ?? profileProvider.socialEmail ?? 'Connected',
            isEditable: false,
          ),
        ] else
          AppWidgets.settingsItem(
            icon: Icons.link,
            title: 'Connect Social',
            subtitle: 'Link Facebook or Google',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SocialNetworkLinkScreen()),
            ),
          ),
      ],
    );
  }

  Widget _buildSecuritySection(ProfileProvider profileProvider) {
    if (!profileProvider.isPasswordUsable) {
      return const SizedBox.shrink();
    }
    return AppWidgets.settingsSection(
      title: 'Security',
      items: [
        AppWidgets.settingsItem(
          icon: Icons.password,
          title: 'Password',
          subtitle: 'Update password',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserPasswordChangeScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection() {
    return AppWidgets.settingsSection(
      title: 'Account',
      items: [
        AppWidgets.settingsItem(
          icon: Icons.admin_panel_settings,
          title: 'Admin Dashboard',
          subtitle: 'Access Django admin and API routes',
          onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
          color: Colors.blue,
        ),
        AppWidgets.settingsItem(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Exit account',
          onTap: _showSignOutDialog,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onEdit,
    bool isEditable = true,
    int maxLines = 1,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white70),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isEditable && onEdit != null
          ? IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20), 
              onPressed: onEdit
            ) 
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInfoItemWithVisibility({
    required IconData icon,
    required String title,
    required String value,
    required VisibilityLevel? visibility,
    VoidCallback? onEdit,
    Function(VisibilityLevel)? onVisibilityChanged,
    int maxLines = 1,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildVisibilityIcon(visibility),
        ],
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white70),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onVisibilityChanged != null)
            PopupMenuButton<VisibilityLevel>(
              icon: const Icon(Icons.visibility, color: Colors.grey, size: 20),
              onSelected: onVisibilityChanged,
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
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20), 
              onPressed: onEdit
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildInitialsAvatar(ProfileProvider profileProvider) {
    final name = profileProvider.name ?? profileProvider.username ?? 'User';
    final initials = _getInitials(name);
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.7),
            Colors.purple.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
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

  Future<void> _editAvatar(ProfileProvider profileProvider) async {
    try {
      final String? sourceType = await _showImageSourceDialog();
      if (sourceType == null) return;

      if (sourceType == 'remove') {
        final auth = context.read<AuthProvider>();
        await profileProvider.deleteAvatar(auth.token);
        showSuccess('Avatar removed successfully!');
        return;
      }

      Uint8List imageBytes;
      String mimeType = 'image/jpeg';

      if (sourceType == 'random_cat') {
        if (kDebugMode) {
          debugPrint('[ProfileScreen] Fetching random cat picture');
        }
        
        showSuccess('Fetching a cute cat picture...');
        
        try {
          http.Response? response;
          
          final catApis = [
            'https://cataas.com/cat?width=512&height=512',
            'https://placekitten.com/512/512',
            'https://loremflickr.com/512/512/cat',
          ];
          
          for (String apiUrl in catApis) {
            try {
              if (kDebugMode) {
                debugPrint('[ProfileScreen] Trying cat API: $apiUrl');
              }
              
              response = await http.get(
                Uri.parse(apiUrl),
                headers: {'User-Agent': 'Music Room App'},
              ).timeout(const Duration(seconds: 10));
              
              if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint('[ProfileScreen] Success with API: $apiUrl');
                }
                break;
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[ProfileScreen] Failed with API $apiUrl: $e');
              }
              continue;
            }
          }
          
          if (response?.statusCode == 200 && response?.bodyBytes.isNotEmpty == true) {
            imageBytes = response!.bodyBytes;
            mimeType = 'image/jpeg';
            
            if (kDebugMode) {
              debugPrint('[ProfileScreen] Successfully fetched cat picture: ${imageBytes.length} bytes');
            }
          } else {
            throw Exception('All cat picture APIs failed');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ProfileScreen] Error fetching cat picture: $e');
          }
          showError('Failed to fetch cat picture. Please check your internet connection and try again.');
          return;
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, 
          maxWidth: 512, 
          maxHeight: 512, 
          imageQuality: 80
        );
        if (image == null) return;

        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
        } else {
          final File file = File(image.path);
          imageBytes = await file.readAsBytes();
        }
        mimeType = image.mimeType ?? 'image/jpeg';
      }

      if (imageBytes.length > 5 * 1024 * 1024) {
        showError('Image too large. Please choose an image smaller than 5MB.');
        return;
      }

      final String base64Image = base64Encode(imageBytes);

      if (kDebugMode) {
        debugPrint('[ProfileScreen] Uploading avatar: size=${imageBytes.length} bytes, type=$mimeType');
        debugPrint('[ProfileScreen] Base64 image length: ${base64Image.length}');
        debugPrint('[ProfileScreen] Auth token: ${auth.token != null ? 'present' : 'null'}');
      }

      final success = await profileProvider.updateProfile(
        auth.token,
        avatarBase64: base64Image,
        mimeType: mimeType,
      );
      
      if (kDebugMode) {
        debugPrint('[ProfileScreen] Avatar upload result: $success');
      }

      if (success) {
        showSuccess('Avatar updated successfully!');
        await profileProvider.loadProfile(auth.token);
      } else {
        showError('Failed to update avatar - check network connection and try again');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileScreen] Avatar upload error: $e');
      }
      String errorMessage = 'Error updating avatar: ';
      if (e.toString().contains('DioException')) {
        if (e.toString().contains('401')) {
          errorMessage = 'Authentication failed - please login again';
        } else if (e.toString().contains('413')) {
          errorMessage = 'Image too large - please choose a smaller image';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid image format - please try a different image';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error - please try again later';
        } else {
          errorMessage = 'Network error - check your connection';
        }
      } else {
        errorMessage += e.toString();
      }
      showError(errorMessage);
    }
  }

  Future<String?> _showImageSourceDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                title: Text(
                  kIsWeb ? 'Choose File' : 'Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.pets, color: AppTheme.primary),
                title: const Text(
                  'Random Cat Picture',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'random_cat'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Avatar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editName(ProfileProvider profileProvider) => _editField(
    profileProvider: profileProvider,
    title: 'Edit Display Name',
    initialValue: profileProvider.name,
    hintText: 'Enter your display name (max 100 characters)',
    successMessage: 'Display name',
    validator: AppValidators.name,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, name: value),
  );

  Future<void> _editLocation(ProfileProvider profileProvider) => _editField(
    profileProvider: profileProvider,
    title: 'Edit Location',
    initialValue: profileProvider.location,
    hintText: 'Enter your location (max 100 characters)',
    successMessage: 'Location',
    validator: AppValidators.location,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, location: value),
  );

  Future<void> _editBio(ProfileProvider profileProvider) => _editField(
    profileProvider: profileProvider,
    title: 'Edit Bio',
    initialValue: profileProvider.bio,
    hintText: 'Tell us about yourself (max 500 characters)...',
    successMessage: 'Bio',
    validator: AppValidators.bio,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, bio: value),
    maxLines: 3,
  );

  Future<void> _editPhone(ProfileProvider profileProvider) => _editField(
    profileProvider: profileProvider,
    title: 'Edit Phone Number',
    initialValue: profileProvider.phone,
    hintText: 'Enter your phone number',
    successMessage: 'Phone number',
    validator: (value) => AppValidators.phoneNumber(value, false),
    updateFunction: (value) => profileProvider.updateProfile(auth.token, phone: value),
  );

  Future<void> _editFriendInfo(ProfileProvider profileProvider) => _editField(
    profileProvider: profileProvider,
    title: 'Edit Friend Info',
    initialValue: profileProvider.friendInfo,
    hintText: 'Share something about yourself with friends...',
    successMessage: 'Friend info',
    validator: null,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, friendInfo: value),
    maxLines: 3,
  );

  Future<void> _editMusicPreferences(ProfileProvider profileProvider) async {
    if (_musicPreferences.isEmpty) {
      showError('Music preferences not loaded');
      return;
    }

    final currentPreferenceIds = profileProvider.musicPreferenceIds ?? [];
    final selectedIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => MusicPreferenceDialog(
        availablePreferences: _musicPreferences,
        selectedIds: currentPreferenceIds,
      ),
    );

    if (selectedIds != null) {
      final success = await profileProvider.updateProfile(
        auth.token, 
        musicPreferencesIds: selectedIds
      );
      if (success) _handleUpdateSuccess('Music preferences', profileProvider);
    }
  }

  void _handleUpdateSuccess(String fieldName, ProfileProvider profileProvider) {
    showSuccess('$fieldName updated successfully');
    profileProvider.loadProfile(auth.token);
  }

  Future<void> _editField({
    required ProfileProvider profileProvider,
    required String title,
    required String? initialValue,
    required String hintText,
    required String successMessage,
    required String? Function(String?)? validator,
    required Future<bool> Function(String) updateFunction,
    int maxLines = 1,
  }) async {
    final value = await AppWidgets.showTextInputDialog(
      context,
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      validator: validator,
      maxLines: maxLines,
    );
    if (value != null && await updateFunction(value.trim())) {
      _handleUpdateSuccess(successMessage, profileProvider);
    }
  }

  Future<void> _updateVisibility(ProfileProvider profileProvider, String field, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(auth.token, 
      nameVisibility: field == 'nameVisibility' ? visibility : null,
      locationVisibility: field == 'locationVisibility' ? visibility : null,
      bioVisibility: field == 'bioVisibility' ? visibility : null,
      phoneVisibility: field == 'phoneVisibility' ? visibility : null,
      friendInfoVisibility: field == 'friendInfoVisibility' ? visibility : null,
      musicPreferencesVisibility: field == 'musicPreferencesVisibility' ? visibility : null,
    );
    if (success) {
      final fieldNames = {
        'nameVisibility': 'Name', 'locationVisibility': 'Location', 'bioVisibility': 'Bio',
        'phoneVisibility': 'Phone', 'friendInfoVisibility': 'Friend info', 'musicPreferencesVisibility': 'Music preferences',
      };
      showSuccess('${fieldNames[field]} visibility updated');
      profileProvider.loadProfile(auth.token);
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

