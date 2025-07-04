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
  bool get showBackButton => !widget.isEmbedded;

  @override
  bool get showMiniPlayer => !widget.isEmbedded;

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
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading) return buildLoadingState(message: 'Loading profile...');

        return RefreshIndicator(
          onRefresh: () => profileProvider.loadProfile(auth.token),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(profileProvider), const SizedBox(height: 16),
                _buildAccountInfoSection(profileProvider), const SizedBox(height: 16),
                _buildPublicInfoSection(profileProvider), const SizedBox(height: 16),
                _buildPrivateInfoSection(profileProvider), const SizedBox(height: 16),
                _buildFriendInfoSection(profileProvider), const SizedBox(height: 16),
                _buildMusicPreferencesSection(profileProvider), const SizedBox(height: 16),
                _buildSocialAccountsSection(profileProvider), const SizedBox(height: 16), 
                _buildSecuritySection(profileProvider), const SizedBox(height: 16), 
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
        _buildInfoItem(
          icon: Icons.person_outline,
          title: 'Gender',
          value: profileProvider.gender ?? 'Not specified',
          onEdit: () => _editGender(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.location_on,
          title: 'Location',
          value: profileProvider.location ?? 'Not specified',
          onEdit: () => _editLocation(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.info,
          title: 'Bio',
          value: profileProvider.bio ?? 'No bio yet',
          onEdit: () => _editBio(profileProvider),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPrivateInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Private Information',
      items: [
        _buildInfoItem(
          icon: Icons.badge,
          title: 'First Name',
          value: profileProvider.firstName ?? 'Not set',
          onEdit: () => _editFirstName(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.badge,
          title: 'Last Name',
          value: profileProvider.lastName ?? 'Not set',
          onEdit: () => _editLastName(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.phone,
          title: 'Phone',
          value: profileProvider.phone ?? 'Not set',
          onEdit: () => _editPhone(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.home,
          title: 'Street Address',
          value: profileProvider.street ?? 'Not set',
          onEdit: () => _editStreet(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.public,
          title: 'Country',
          value: profileProvider.country ?? 'Not set',
          onEdit: () => _editCountry(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.mail,
          title: 'Postal Code',
          value: profileProvider.postalCode ?? 'Not set',
          onEdit: () => _editPostalCode(profileProvider),
        ),
      ],
    );
  }

  Widget _buildFriendInfoSection(ProfileProvider profileProvider) {
    return AppWidgets.settingsSection(
      title: 'Friend Information',
      items: [
        _buildInfoItem(
          icon: Icons.cake,
          title: 'Date of Birth',
          value: profileProvider.dob != null ? DateFormat('yyyy-MM-dd').format(profileProvider.dob!) : 'Not set',
          onEdit: () => _editDateOfBirth(profileProvider),
        ),
        _buildInfoItem(
          icon: Icons.interests,
          title: 'Hobbies',
          value: profileProvider.hobbies?.isNotEmpty == true
              ? profileProvider.hobbies!.join(', ')
              : 'No hobbies listed',
          onEdit: () => _editHobbies(profileProvider),
          maxLines: 2,
        ),
        _buildInfoItem(
          icon: Icons.people,
          title: 'Friend Info',
          value: profileProvider.friendInfo ?? 'No friend info',
          onEdit: () => _editFriendInfo(profileProvider),
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
          value: profileProvider.musicPreferences?.isNotEmpty == true
              ? profileProvider.musicPreferences!.join(', ')
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

  Future<void> _editGender(ProfileProvider profileProvider) async {
    final genders = ['male', 'female'];
    final selectedIndex = await AppWidgets.showSelectionDialog<String>(
      context: context,
      title: 'Select Gender', 
      items: genders,
      itemTitle: (gender) => gender.substring(0, 1).toUpperCase() + gender.substring(1),
    );

    if (selectedIndex != null) {
      final success = await profileProvider.updateProfile(
        auth.token, 
        gender: genders[selectedIndex], 
        location: profileProvider.location
      );
      if (success) {
        showSuccess('Gender updated successfully');
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
        gender: profileProvider.gender,
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

  Future<void> _editFirstName(ProfileProvider profileProvider) async {
    final firstName = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit First Name',
      initialValue: profileProvider.firstName,
      hintText: 'Enter your first name',
    );

    if (firstName != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        firstName: firstName.trim(),
      );
      if (success) {
        showSuccess('First name updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editLastName(ProfileProvider profileProvider) async {
    final lastName = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Last Name',
      initialValue: profileProvider.lastName,
      hintText: 'Enter your last name',
    );

    if (lastName != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        lastName: lastName.trim(),
      );
      if (success) {
        showSuccess('Last name updated successfully');
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

  Future<void> _editStreet(ProfileProvider profileProvider) async {
    final street = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Street Address',
      initialValue: profileProvider.street,
      hintText: 'Enter your street address',
    );

    if (street != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        street: street.trim(),
      );
      if (success) {
        showSuccess('Street address updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editCountry(ProfileProvider profileProvider) async {
    final countries = [
      'Singapore',
      'Malaysia', 
      'Indonesia',
      'Thailand',
      'United States',
      'Canada',
      'United Kingdom',
      'Australia'
    ];

    final selectedIndex = await AppWidgets.showSelectionDialog<String>(
      context: context,
      title: 'Select Country',
      items: countries,
      itemTitle: (country) => country,
    );

    if (selectedIndex != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        country: countries[selectedIndex],
      );
      if (success) {
        showSuccess('Country updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editPostalCode(ProfileProvider profileProvider) async {
    final postalCode = await AppWidgets.showTextInputDialog(
      context,
      title: 'Edit Postal Code',
      initialValue: profileProvider.postalCode,
      hintText: 'Enter your postal code',
    );

    if (postalCode != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        postalCode: postalCode.trim(),
      );
      if (success) {
        showSuccess('Postal code updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editDateOfBirth(ProfileProvider profileProvider) async {
    final currentDate = profileProvider.dob ?? DateTime.now().subtract(const Duration(days: 6570)); 

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        dob: DateFormat('yyyy-MM-dd').format(selectedDate),
      );
      if (success) {
        showSuccess('Date of birth updated successfully');
        profileProvider.loadProfile(auth.token);
      }
    }
  }

  Future<void> _editHobbies(ProfileProvider profileProvider) async {
    final availableHobbies = ['Sport', 'Movie', 'Music', 'Travel'];
    final currentHobbies = profileProvider.hobbies ?? [];

    final selectedHobbies = await showDialog<List<String>>(
      context: context,
      builder: (context) => _HobbySelectionDialog(
        availableHobbies: availableHobbies,
        selectedHobbies: currentHobbies,
      ),
    );

    if (selectedHobbies != null) {
      final success = await profileProvider.updateProfile(
        auth.token,
        hobbies: selectedHobbies,
      );
      if (success) {
        showSuccess('Hobbies updated successfully');
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
    final availableGenres = ['Classical', 'Jazz', 'Pop', 'Rock', 'Rap', 'R&B', 'Techno'];
    final currentPreferences = profileProvider.musicPreferences ?? [];

    final selectedPreferences = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MusicPreferenceDialog(
        availableGenres: availableGenres,
        selectedGenres: currentPreferences,
      ),
    );

    if (selectedPreferences != null) {
      final success = await profileProvider.updateProfile(
        auth.token, 
        musicPreferences: selectedPreferences
      );
      if (success) {
        showSuccess('Music preferences updated successfully');
        profileProvider.loadProfile(auth.token);
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

class _HobbySelectionDialog extends StatefulWidget {
  final List<String> availableHobbies;
  final List<String> selectedHobbies;

  const _HobbySelectionDialog({
    required this.availableHobbies,
    required this.selectedHobbies,
  });

  @override
  State<_HobbySelectionDialog> createState() => _HobbySelectionDialogState();
}

class _HobbySelectionDialogState extends State<_HobbySelectionDialog> {
  late List<String> _selectedHobbies;

  @override
  void initState() {
    super.initState();
    _selectedHobbies = List.from(widget.selectedHobbies);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Select Hobbies', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availableHobbies.length,
          itemBuilder: (context, index) {
            final hobby = widget.availableHobbies[index];
            final isSelected = _selectedHobbies.contains(hobby);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedHobbies.add(hobby);
                  } else {
                    _selectedHobbies.remove(hobby);
                  }
                });
              },
              title: Text(hobby, style: const TextStyle(color: Colors.white)),
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
          onPressed: () => Navigator.pop(context, _selectedHobbies),
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

class _MusicPreferenceDialog extends StatefulWidget {
  final List<String> availableGenres;
  final List<String> selectedGenres;

  const _MusicPreferenceDialog({
    required this.availableGenres, 
    required this.selectedGenres
  });

  @override
  State<_MusicPreferenceDialog> createState() => _MusicPreferenceDialogState();
}

class _MusicPreferenceDialogState extends State<_MusicPreferenceDialog> {
  late List<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.selectedGenres);
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
          itemCount: widget.availableGenres.length,
          itemBuilder: (context, index) {
            final genre = widget.availableGenres[index];
            final isSelected = _selectedGenres.contains(genre);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) _selectedGenres.add(genre);
                  else _selectedGenres.remove(genre);
                });
              },
              title: Text(genre, style: const TextStyle(color: Colors.white)),
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
          onPressed: () => Navigator.pop(context, _selectedGenres),
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
