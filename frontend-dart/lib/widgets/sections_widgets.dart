import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:form_validator/form_validator.dart';
import '../providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import '../core/theme_core.dart';
import '../core/constants_core.dart';
import '../widgets/app_widgets.dart';
import '../widgets/location_widgets.dart';
import '../screens/profile/password_profile.dart';
import '../screens/profile/social_profile.dart';

class ProfileSectionsWidget extends StatelessWidget {
  final ProfileProvider profileProvider;
  final AuthProvider auth;
  final List<Map<String, dynamic>> musicPreferences;
  final Function(String, ProfileProvider) handleUpdateSuccess;
  final Function(ProfileProvider, String, VisibilityLevel) updateVisibility;
  final VoidCallback showSignOutDialog;

  const ProfileSectionsWidget({
    super.key,
    required this.profileProvider,
    required this.auth,
    required this.musicPreferences,
    required this.handleUpdateSuccess,
    required this.updateVisibility,
    required this.showSignOutDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAccountInfoSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildPublicInfoSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildContactInfoSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildFriendInfoSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildMusicPreferencesSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildSocialAccountsSection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildSecuritySection(context),
        SizedBox(height: ThemeUtils.getResponsivePadding(context) * 2),
        _buildAccountActionsSection(context),
      ],
    );
  }

  Widget _buildAccountInfoSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Account Info',
      items: [
        _buildInfoItem(
          icon: Icons.person,
          title: 'Username',
          value: (profileProvider.username?.isEmpty ?? true) ? 'No username set' : profileProvider.username!,
          isEditable: false,
        ),
        _buildInfoItem(
          icon: Icons.email,
          title: 'Email',
          value: (profileProvider.userEmail?.isEmpty ?? true) ? 'No email provided' : profileProvider.userEmail!,
          isEditable: false,
        ),
      ],
    );
  }

  Widget _buildPublicInfoSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Public Info',
      items: [
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.person_outline,
          title: 'Name',
          value: (profileProvider.name?.isEmpty ?? true) ? 'No display name set' : profileProvider.name!,
          visibility: profileProvider.nameVisibility,
          onEdit: () => _editName(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'nameVisibility', visibility),
        ),
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.location_on,
          title: 'Location',
          value: (profileProvider.location?.isEmpty ?? true) ? 'No location specified' : profileProvider.location!,
          visibility: profileProvider.locationVisibility,
          onEdit: () => _editLocation(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'locationVisibility', visibility),
        ),
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.info,
          title: 'Bio',
          value: (profileProvider.bio?.isEmpty ?? true) ? 'No bio added yet' : profileProvider.bio!,
          visibility: profileProvider.bioVisibility,
          onEdit: () => _editBio(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'bioVisibility', visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Contact',
      items: [
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.phone,
          title: 'Phone',
          value: (profileProvider.phone?.isEmpty ?? true) ? 'No phone number provided' : profileProvider.phone!,
          visibility: profileProvider.phoneVisibility,
          onEdit: () => _editPhone(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'phoneVisibility', visibility),
        ),
      ],
    );
  }

  Widget _buildFriendInfoSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Friends',
      items: [
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.people,
          title: 'Friend Info',
          value: (profileProvider.friendInfo?.isEmpty ?? true) ? 'No friend information added' : profileProvider.friendInfo!,
          visibility: profileProvider.friendInfoVisibility,
          onEdit: () => _editFriendInfo(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'friendInfoVisibility', visibility),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildMusicPreferencesSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Music',
      items: [
        _buildInfoItemWithVisibility(
          context,
          icon: Icons.music_note,
          title: 'Music Genres',
          value: profileProvider.musicPreferences?.isNotEmpty == true
              ? profileProvider.musicPreferences!.join(', ')
              : 'No music preferences selected',
          visibility: profileProvider.musicPreferencesVisibility,
          onEdit: () => _editMusicPreferences(context),
          onVisibilityChanged: (visibility) => updateVisibility(profileProvider, 'musicPreferencesVisibility', visibility),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSocialAccountsSection(BuildContext context) {
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

  Widget _buildSecuritySection(BuildContext context) {
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

  Widget _buildAccountActionsSection(BuildContext context) {
    return AppWidgets.settingsSection(
      title: 'Actions',
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
          onTap: showSignOutDialog,
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

  Widget _buildInfoItemWithVisibility(
    BuildContext context, {
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

  Future<void> _editName(BuildContext context) => _editField(
    context,
    title: 'Edit Display Name',
    initialValue: profileProvider.name,
    hintText: 'Enter your display name (max 100 characters)',
    successMessage: 'Display name',
    validator: AppValidators.name,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, name: value),
  );

  Future<void> _editLocation(BuildContext context) async {
    String? selectedLocation = profileProvider.location;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Location', style: TextStyle(color: Colors.white)),
        content: IntrinsicHeight(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: LocationAutocompleteField(
            initialValue: profileProvider.location,
            labelText: 'Location',
            hintText: 'Search for your city or location',
            onLocationSelected: (location) {
              selectedLocation = location;
            },
            validator: (value) => ValidationBuilder().maxLength(100, 'Location must be less than 100 characters').build()(value),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedLocation?.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      final success = await profileProvider.updateProfile(auth.token, location: result);
      if (success) {
        handleUpdateSuccess('Location', profileProvider);
      }
    }
  }

  Future<void> _editBio(BuildContext context) => _editField(
    context,
    title: 'Edit Bio',
    initialValue: profileProvider.bio,
    hintText: 'Tell us about yourself (max 500 characters)...',
    successMessage: 'Bio',
    validator: AppValidators.bio,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, bio: value),
    maxLines: 3,
  );

  Future<void> _editPhone(BuildContext context) => _editField(
    context,
    title: 'Edit Phone Number',
    initialValue: profileProvider.phone,
    hintText: 'Enter your phone number',
    successMessage: 'Phone number',
    validator: (value) => AppValidators.phoneNumber(value, false),
    updateFunction: (value) => profileProvider.updateProfile(auth.token, phone: value),
  );

  Future<void> _editFriendInfo(BuildContext context) => _editField(
    context,
    title: 'Edit Friend Info',
    initialValue: profileProvider.friendInfo,
    hintText: 'Share something about yourself with friends...',
    successMessage: 'Friend info',
    validator: null,
    updateFunction: (value) => profileProvider.updateProfile(auth.token, friendInfo: value),
    maxLines: 3,
  );

  Future<void> _editMusicPreferences(BuildContext context) async {
    if (musicPreferences.isEmpty) {
      return;
    }

    if (!context.mounted) {
      if (kDebugMode) {
        print('[DEBUG] Context not mounted at start - cannot edit music preferences');
      }
      return;
    }

    List<int> currentPreferenceIds = [];
    
    
    final rawPreferenceIds = profileProvider.musicPreferenceIds;
    if (rawPreferenceIds != null && rawPreferenceIds.isNotEmpty) {
      currentPreferenceIds = rawPreferenceIds.map((id) {
        return id is int ? id : int.tryParse(id.toString()) ?? 0;
      }).toList();
    } else if (profileProvider.musicPreferences != null && profileProvider.musicPreferences!.isNotEmpty) {
      currentPreferenceIds = [];
      for (final prefName in profileProvider.musicPreferences!) {
        final matchingPref = musicPreferences.firstWhere(
          (pref) => pref['name']?.toString().toLowerCase() == prefName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (matchingPref.isNotEmpty && matchingPref['id'] != null) {
          final id = matchingPref['id'] is int ? matchingPref['id'] as int : int.tryParse(matchingPref['id'].toString()) ?? 0;
          if (id > 0) currentPreferenceIds.add(id);
        }
      }
    }

    
    if (currentPreferenceIds.isEmpty && (profileProvider.musicPreferences?.isEmpty ?? true) && (profileProvider.musicPreferenceIds?.isEmpty ?? true)) {
      bool isLoadingDialogShown = false;
      late NavigatorState navigator;
      
      try {
        navigator = Navigator.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        isLoadingDialogShown = true;

        if (kDebugMode) {
          print('[DEBUG] Loading dialog shown, refreshing profile data...');
        }

        await profileProvider.loadProfile(auth.token).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('Profile loading timed out'),
        );
        
        
        final newRawPreferenceIds = profileProvider.musicPreferenceIds;
        if (newRawPreferenceIds != null && newRawPreferenceIds.isNotEmpty) {
          currentPreferenceIds = newRawPreferenceIds.map((id) {
            return id is int ? id : int.tryParse(id.toString()) ?? 0;
          }).toList();
        } else if (profileProvider.musicPreferences != null && profileProvider.musicPreferences!.isNotEmpty) {
          currentPreferenceIds = [];
          for (final prefName in profileProvider.musicPreferences!) {
            final matchingPref = musicPreferences.firstWhere(
              (pref) => pref['name']?.toString().toLowerCase() == prefName.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            if (matchingPref.isNotEmpty && matchingPref['id'] != null) {
              final id = matchingPref['id'] is int ? matchingPref['id'] as int : int.tryParse(matchingPref['id'].toString()) ?? 0;
              if (id > 0) currentPreferenceIds.add(id);
            }
          }
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('[DEBUG] Error loading preferences: $e');
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load music preferences: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (isLoadingDialogShown && navigator.mounted) {
          try {
            navigator.pop();
            if (kDebugMode) {
              print('[DEBUG] Loading dialog dismissed');
            }
          } catch (e) {
            if (kDebugMode) {
              print('[DEBUG] Error dismissing dialog: $e');
            }
          }
        }
      }
    }

    if (!context.mounted) {
      if (kDebugMode) {
        print('[DEBUG] Context not mounted after loading - cannot show dialog');
      }
      return;
    }

    if (kDebugMode) {
      print('[DEBUG] Loaded preference IDs: $currentPreferenceIds');
      print('[DEBUG] Showing music preference dialog...');
    }

    try {
      final selectedIds = await showDialog<List<int>>(
        context: context,
        builder: (context) => MusicPreferenceDialog(
          availablePreferences: musicPreferences,
          selectedIds: currentPreferenceIds,
        ),
      );

      if (selectedIds != null && context.mounted) {
        final success = await profileProvider.updateProfile(
          auth.token,
          musicPreferencesIds: selectedIds,
          availableMusicPreferences: musicPreferences,
        );
        if (success && context.mounted) {
          handleUpdateSuccess('Music preferences', profileProvider);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] Error showing music preference dialog: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening music preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editField(
    BuildContext context, {
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
      handleUpdateSuccess(successMessage, profileProvider);
    }
  }
}

class MusicPreferenceDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availablePreferences;
  final List<int> selectedIds;

  const MusicPreferenceDialog({
    super.key,
    required this.availablePreferences,
    required this.selectedIds
  });

  @override
  State<MusicPreferenceDialog> createState() => _MusicPreferenceDialogState();
}

class _MusicPreferenceDialogState extends State<MusicPreferenceDialog> {
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
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.builder(
          itemCount: widget.availablePreferences.length,
          itemBuilder: (context, index) {
            final preference = widget.availablePreferences[index];
            final dynamic rawId = preference['id'];
            final int id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
            final name = preference['name'] as String;
            final isSelected = _selectedIds.contains(id);
            
            if (kDebugMode && index < 5) {  
              print('[DEBUG] Preference "$name" (rawId: $rawId, id: $id, type: ${id.runtimeType}) - isSelected: $isSelected');
              print('[DEBUG] _selectedIds contains $id: ${_selectedIds.contains(id)}, _selectedIds: $_selectedIds');
            }

            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
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