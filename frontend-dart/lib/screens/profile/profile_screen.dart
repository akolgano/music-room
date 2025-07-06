// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/profile_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

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
  bool get showBackButton => !widget.isEmbedded;
  
  @override
  bool get showMiniPlayer => !widget.isEmbedded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadProfile();
    });
  }

  Future<void> _checkAuthAndLoadProfile() async {
    if (!auth.isLoggedIn || auth.token == null) {
      print('User not authenticated, redirecting to auth screen');
      if (mounted) {
        showError('Please log in to view your profile');
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      }
      return;
    }
    
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileProvider = getProvider<ProfileProvider>();
    
    try {
      final success = await profileProvider.loadProfile(auth.token);
      if (!success && mounted) {
        if (profileProvider.errorMessage?.contains('Authentication') == true ||
            profileProvider.errorMessage?.contains('Unauthorized') == true) {
          showError('Session expired. Please log in again.');
          Navigator.pushReplacementNamed(context, AppRoutes.auth);
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        showError('Failed to load profile. Please try again.');
      }
    }
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<ProfileProvider>(
      builder: (context, profileProvider) {
        if (!auth.isLoggedIn || auth.token == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Required',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please log in to view your profile',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
                  child: const Text('Log In'),
                ),
              ],
            ),
          );
        }

        if (profileProvider.isLoading) {
          return buildLoadingState(message: 'Loading profile...');
        }

        if (profileProvider.hasError) {
          String errorMessage = profileProvider.errorMessage ?? 'Failed to load profile';
          
          if (errorMessage.contains('Authentication') || errorMessage.contains('Unauthorized')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Session Expired',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please log in again to access your profile',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.auth),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            );
          }

          return buildErrorState(
            message: errorMessage,
            onRetry: _loadProfile,
            retryText: 'Try Again',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(profileProvider),
                const SizedBox(height: 16),
                _buildAccountInfoSection(profileProvider),
                const SizedBox(height: 16),
                _buildBasicInfoSection(profileProvider),
                const SizedBox(height: 16),
                _buildContactInfoSection(profileProvider),
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
                      : LinearGradient(
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
                child: _buildAvatarImage(profileProvider),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildAvatarEditButton(profileProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileProvider.username ?? auth.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                  'ID: ${profileProvider.userId ?? auth.userId ?? "Unknown"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvatarImage(ProfileProvider profileProvider) {
    if (profileProvider.avatarUrl?.isNotEmpty == true) {
      return ClipOval(
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
      );
    }
    return const Icon(Icons.person, size: 50, color: Colors.black);
  }
  
  Widget _buildAvatarEditButton(ProfileProvider profileProvider) {
    return GestureDetector(
      onTap: profileProvider.isLoading ? null : () => _editAvatar(profileProvider),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: profileProvider.isLoading ? Colors.grey : AppTheme.primary,
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
  
  Widget _buildBasicInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Basic Information',
      items: [
        _buildInfoItem(
          icon: Icons.person_outline,
          title: 'Name',
          value: profileProvider.name ?? 'Not set',
          onEdit: () => _editField(
            title: 'Edit Name',
            initialValue: profileProvider.name,
            onSave: (value) => profileProvider.updateBasicInfo(auth.token, name: value),
          ),
        ),
        _buildInfoItem(
          icon: Icons.location_on,
          title: 'Location',
          value: profileProvider.location ?? 'Not set',
          onEdit: () => _editField(
            title: 'Edit Location',
            initialValue: profileProvider.location,
            onSave: (value) => profileProvider.updateBasicInfo(auth.token, location: value),
          ),
        ),
        _buildInfoItem(
          icon: Icons.info,
          title: 'Bio',
          value: profileProvider.bio ?? 'No bio yet',
          onEdit: () => _editField(
            title: 'Edit Bio',
            initialValue: profileProvider.bio,
            maxLines: 3,
            onSave: (value) => profileProvider.updateBasicInfo(auth.token, bio: value),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
  
  Widget _buildContactInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Contact Information',
      items: [
        _buildInfoItem(
          icon: Icons.phone,
          title: 'Phone',
          value: profileProvider.phone ?? 'Not set',
          onEdit: () => _editField(
            title: 'Edit Phone Number',
            initialValue: profileProvider.phone,
            validator: (value) => AppValidators.phoneNumber(value, false),
            onSave: (value) => profileProvider.updateContactInfo(auth.token, phone: value),
          ),
        ),
        _buildInfoItem(
          icon: Icons.people,
          title: 'Friend Info',
          value: profileProvider.friendInfo ?? 'No friend info',
          onEdit: () => _editField(
            title: 'Edit Friend Info',
            initialValue: profileProvider.friendInfo,
            maxLines: 3,
            onSave: (value) => profileProvider.updateContactInfo(auth.token, friendInfo: value),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
  
  Widget _buildMusicPreferencesSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Music Preferences',
      items: [
        _buildInfoItem(
          icon: Icons.music_note,
          title: 'Music Genres',
          value: profileProvider.musicPreferences.isNotEmpty
              ? profileProvider.musicPreferences.join(', ')
              : 'No preferences set',
          onEdit: () => _editMusicPreferences(profileProvider),
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
            icon: profileProvider.socialType == 'facebook' 
                ? Icons.facebook 
                : Icons.g_mobiledata,
            title: '${profileProvider.socialType} Account',
            value: profileProvider.socialName ?? 
                   profileProvider.socialEmail ?? 
                   'Connected',
            isEditable: false,
          ),
        ] else
          AppWidgets.settingsItem(
            icon: Icons.link,
            title: 'Link Social Account',
            subtitle: 'Connect Facebook or Google account',
            onTap: () => navigateTo(AppRoutes.socialNetworkLink),
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
          onTap: () => navigateTo(AppRoutes.userPasswordChange),
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
              onPressed: onEdit,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
  
  Future<void> _editAvatar(ProfileProvider profileProvider) async {
    await runAsyncAction(
      () async {
        final ImageSource? source = await _showImageSourceDialog();
        if (source == null) return;
        
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
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
        await profileProvider.updateAvatar(auth.token, base64Image);
      },
      successMessage: 'Avatar updated successfully!',
      errorMessage: 'Failed to update avatar',
    );
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
  
  Future<void> _editField({
    required String title,
    String? initialValue,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Future<bool> Function(String) onSave,
  }) async {
    final value = await AppWidgets.showTextInputDialog(
      context,
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      maxLines: maxLines,
      validator: validator,
    );
    
    if (value != null) {
      await runAsyncAction(
        () async {
          final success = await onSave(value.trim());
          if (success) {
            await _loadProfile();
          }
        },
        successMessage: '${title.replaceAll('Edit ', '')} updated successfully',
        errorMessage: 'Failed to update ${title.replaceAll('Edit ', '').toLowerCase()}',
      );
    }
  }
  
  Future<void> _editMusicPreferences(ProfileProvider profileProvider) async {
    final availableGenres = ['Classical', 'Jazz', 'Pop', 'Rock', 'Rap', 'R&B', 'Techno'];
    final currentPreferences = profileProvider.musicPreferences;
    
    final selectedPreferences = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Music Preferences',
        items: availableGenres,
        selectedItems: currentPreferences,
      ),
    );
    
    if (selectedPreferences != null) {
      await runAsyncAction(
        () async {
          final ids = profileProvider.getMusicPreferenceIds(selectedPreferences);
          final success = await profileProvider.updateMusicPreferences(auth.token, ids);
          if (success) {
            await _loadProfile();
          }
        },
        successMessage: 'Music preferences updated successfully',
        errorMessage: 'Failed to update music preferences',
      );
    }
  }
  
  void _showSignOutDialog() async {
    final confirmed = await showConfirmDialog(
      'Sign Out',
      AppStrings.confirmLogout,
      isDangerous: true,
    );
    
    if (confirmed) {
      await runAsyncAction(
        () => auth.logout(),
        successMessage: 'Signed out successfully',
      );
    }
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> selectedItems;
  
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selectedItems,
  });
  
  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selectedItems;
  
  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = _selectedItems.contains(item);
            
            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
              title: Text(item, style: const TextStyle(color: Colors.white)),
              activeColor: AppTheme.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
