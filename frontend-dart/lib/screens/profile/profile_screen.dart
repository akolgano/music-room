// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';
import 'user_password_change_screen.dart';
import 'social_network_link_screen.dart';

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
        developer.log('Error loading music preferences: $e', name: 'ProfileScreen');
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(profileProvider), 
                const SizedBox(height: 16),
                _buildAccountInfoSection(profileProvider), 
                const SizedBox(height: 16),
                _buildPublicInfoSection(profileProvider), 
                const SizedBox(height: 16),
                _buildContactInfoSection(profileProvider), 
                const SizedBox(height: 16),
                _buildFriendInfoSection(profileProvider), 
                const SizedBox(height: 16),
                _buildMusicPreferencesSection(profileProvider), 
                const SizedBox(height: 16),
                _buildSocialAccountsSection(profileProvider), 
                const SizedBox(height: 16), 
                _buildSecuritySection(profileProvider), 
                const SizedBox(height: 16), 
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
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
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
                                    const Icon(Icons.person, size: 50, color: Colors.black),
                              )
                            : Image.network(
                                profileProvider.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 50, color: Colors.black),
                              ),
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.black),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: profileProvider.isLoading 
                      ? null 
                      : () => _editAvatar(profileProvider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
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
                        : const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                  ),
                ),
              ),
            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      title: 'Account Information',
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
      title: 'Public Information',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.person_outline,
          title: 'Display Name',
          value: profileProvider.name ?? 'Not set',
          visibility: profileProvider.nameVisibility,
          onEdit: () => _editName(profileProvider),
          onVisibilityChanged: (visibility) => _updateNameVisibility(profileProvider, visibility),
        ),
        _buildInfoItemWithVisibility(
          icon: Icons.location_on,
          title: 'Location',
          value: profileProvider.location ?? 'Not specified',
          visibility: profileProvider.locationVisibility,
          onEdit: () => _editLocation(profileProvider),
          onVisibilityChanged: (visibility) => _updateLocationVisibility(profileProvider, visibility),
        ),
        _buildInfoItemWithVisibility(
          icon: Icons.info,
          title: 'Bio',
          value: profileProvider.bio ?? 'No bio yet',
          visibility: profileProvider.bioVisibility,
          onEdit: () => _editBio(profileProvider),
          onVisibilityChanged: (visibility) => _updateBioVisibility(profileProvider, visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Contact Information',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.phone,
          title: 'Phone',
          value: profileProvider.phone ?? 'Not set',
          visibility: profileProvider.phoneVisibility,
          onEdit: () => _editPhone(profileProvider),
          onVisibilityChanged: (visibility) => _updatePhoneVisibility(profileProvider, visibility),
        ),
      ],
    );
  }

  Widget _buildFriendInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Friend Information',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.people,
          title: 'Friend Info',
          value: profileProvider.friendInfo ?? 'No friend info',
          visibility: profileProvider.friendInfoVisibility,
          onEdit: () => _editFriendInfo(profileProvider),
          onVisibilityChanged: (visibility) => _updateFriendInfoVisibility(profileProvider, visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildMusicPreferencesSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Music Preferences',
      items: [
        _buildInfoItemWithVisibility(
          icon: Icons.music_note, 
          title: 'Music Genres',
          value: profileProvider.musicPreferences?.isNotEmpty == true
              ? profileProvider.musicPreferences!.join(', ')
              : 'No preferences set',
          visibility: profileProvider.musicPreferencesVisibility,
          onEdit: () => _editMusicPreferences(profileProvider),
          onVisibilityChanged: (visibility) => _updateMusicPreferencesVisibility(profileProvider, visibility),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSocialAccountsSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Social Accounts',
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
            title: 'Link Social Account',
            subtitle: 'Connect Facebook or Google account',
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
          title: 'Change Password',
          subtitle: 'Change your account password',
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
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Future<void> _editAvatar(ProfileProvider profileProvider) async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source, 
        maxWidth: 512, 
        maxHeight: 512, 
        imageQuality: 80
      );
      if (image == null) return;

      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await image.readAsBytes();
      } else {
        final File file = File(image.path);
        imageBytes = await file.readAsBytes();
      }

      final String base64Image = base64Encode(imageBytes);
      final String mimeType = image.mimeType ?? 'image/jpeg';

      final success = await profileProvider.updateProfile(
        auth.token,
        avatarBase64: base64Image,
        mimeType: mimeType,
      );

      if (success) {
        showSuccess('Avatar updated successfully!');
        await profileProvider.loadProfile(auth.token);
      } else {
        showError('Failed to update avatar');
      }
    } catch (e) {
      showError('Error updating avatar: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
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
              if (!kIsWeb) 
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                  title: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                title: Text(
                  kIsWeb ? 'Choose File' : 'Gallery',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
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

  Future<void> _editName(ProfileProvider profileProvider) async {
    final name = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Display Name',
      initialValue: profileProvider.name,
      hintText: 'Enter your display name',
    );
    if (name != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        name: name.trim(),
      );
      if (success) {
        showSuccess('Display name updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editLocation(ProfileProvider profileProvider) async {
    final location = await AppWidgets.showTextInputDialog(
      context, 
      title: 'Edit Location',
      initialValue: profileProvider.location,
      hintText: 'Enter your location',
    );
    if (location != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        location: location.trim(),
      );
      if (success) {
        showSuccess('Location updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editBio(ProfileProvider profileProvider) async {
    final bio = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Bio',
      initialValue: profileProvider.bio,
      hintText: 'Tell us about yourself...',
      maxLines: 3,
    );
    if (bio != null) {
      final success = await profileProvider.updateProfile(
        auth.token, 
        bio: bio.trim()
      );
      if (success) {
        showSuccess('Bio updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editPhone(ProfileProvider profileProvider) async {
    final phone = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Phone Number',
      initialValue: profileProvider.phone,
      hintText: 'Enter your phone number',
      validator: (value) => AppValidators.phoneNumber(value, false),
    );
    if (phone != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        phone: phone.trim(),
      );
      if (success) {
        showSuccess('Phone number updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editFriendInfo(ProfileProvider profileProvider) async {
    final friendInfo = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Friend Info',
      initialValue: profileProvider.friendInfo,
      hintText: 'Share something about yourself with friends...',
      maxLines: 3,
    );
    if (friendInfo != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        friendInfo: friendInfo.trim(),
      );
      if (success) {
        showSuccess('Friend info updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editMusicPreferences(ProfileProvider profileProvider) async {
    if (_musicPreferences.isEmpty) {
      showError('Music preferences not loaded');
      return;
    }

    final currentPreferenceIds = profileProvider.musicPreferenceIds ?? [];
    final selectedIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => _MusicPreferenceDialog(
        availablePreferences: _musicPreferences,
        selectedIds: currentPreferenceIds,
      ),
    );

    if (selectedIds != null) {
      final success = await profileProvider.updateProfile(
        auth.token, 
        musicPreferencesIds: selectedIds
      );
      if (success) {
        showSuccess('Music preferences updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _updateNameVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      nameVisibility: visibility,
    );
    if (success) {
      showSuccess('Name visibility updated');
      profileProvider.loadProfile(auth.token);
    }
  }

  Future<void> _updateLocationVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      locationVisibility: visibility,
    );
    if (success) {
      showSuccess('Location visibility updated');
      profileProvider.loadProfile(auth.token);
    }
  }

  Future<void> _updateBioVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      bioVisibility: visibility,
    );
    if (success) {
      showSuccess('Bio visibility updated');
      profileProvider.loadProfile(auth.token);
    }
  }

  Future<void> _updatePhoneVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      phoneVisibility: visibility,
    );
    if (success) {
      showSuccess('Phone visibility updated');
      profileProvider.loadProfile(auth.token);
    }
  }

  Future<void> _updateFriendInfoVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      friendInfoVisibility: visibility,
    );
    if (success) {
      showSuccess('Friend info visibility updated');
      profileProvider.loadProfile(auth.token);
    }
  }

  Future<void> _updateMusicPreferencesVisibility(ProfileProvider profileProvider, VisibilityLevel visibility) async {
    final success = await profileProvider.updateVisibility(
      auth.token,
      musicPreferencesVisibility: visibility,
    );
    if (success) {
      showSuccess('Music preferences visibility updated');
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

class _MusicPreferenceDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availablePreferences;
  final List<int> selectedIds;

  const _MusicPreferenceDialog({
    required this.availablePreferences, 
    required this.selectedIds
  });

  @override
  State<_MusicPreferenceDialog> createState() => _MusicPreferenceDialogState();
}

class _MusicPreferenceDialogState extends State<_MusicPreferenceDialog> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Select Music Preferences', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availablePreferences.length,
          itemBuilder: (context, index) {
            final preference = widget.availablePreferences[index];
            final id = preference['id'] as int;
            final name = preference['name'] as String;
            final isSelected = _selectedIds.contains(id);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) _selectedIds.add(id);
                  else _selectedIds.remove(id);
                });
              },
              title: Text(name, style: const TextStyle(color: Colors.white)),
              activeColor: AppTheme.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel', style: TextStyle(color: Colors.grey))
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary, 
            foregroundColor: Colors.black
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
