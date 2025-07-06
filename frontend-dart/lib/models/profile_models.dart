// lib/models/profile_models.dart
class Profile {
  final String? avatar;
  final String? name;
  final String? location;
  final String? bio;
  final String? phone;
  final String? friendInfo;
  final String avatarVisibility;
  final String nameVisibility;
  final String locationVisibility;
  final String bioVisibility;
  final String phoneVisibility;
  final String friendInfoVisibility;
  final String musicPreferencesVisibility;
  final List<String> musicPreferences;

  const Profile({
    this.avatar,
    this.name,
    this.location,
    this.bio,
    this.phone,
    this.friendInfo,
    this.avatarVisibility = 'public',
    this.nameVisibility = 'public',
    this.locationVisibility = 'public',
    this.bioVisibility = 'public',
    this.phoneVisibility = 'private',
    this.friendInfoVisibility = 'friends',
    this.musicPreferencesVisibility = 'public',
    this.musicPreferences = const [],
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      avatar: json['avatar'] as String?,
      name: json['name'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      friendInfo: json['friend_info'] as String?,
      avatarVisibility: json['avatar_visibility'] as String? ?? 'public',
      nameVisibility: json['name_visibility'] as String? ?? 'public',
      locationVisibility: json['location_visibility'] as String? ?? 'public',
      bioVisibility: json['bio_visibility'] as String? ?? 'public',
      phoneVisibility: json['phone_visibility'] as String? ?? 'private',
      friendInfoVisibility: json['friend_info_visibility'] as String? ?? 'friends',
      musicPreferencesVisibility: json['music_preferences_visibility'] as String? ?? 'public',
      musicPreferences: (json['music_preferences'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'name': name,
    'location': location,
    'bio': bio,
    'phone': phone,
    'friend_info': friendInfo,
    'avatar_visibility': avatarVisibility,
    'name_visibility': nameVisibility,
    'location_visibility': locationVisibility,
    'bio_visibility': bioVisibility,
    'phone_visibility': phoneVisibility,
    'friend_info_visibility': friendInfoVisibility,
    'music_preferences_visibility': musicPreferencesVisibility,
    'music_preferences': musicPreferences,
  };
}

class MusicPreference {
  final int id;
  final String name;

  const MusicPreference({
    required this.id,
    required this.name,
  });

  factory MusicPreference.fromJson(Map<String, dynamic> json) {
    return MusicPreference(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

enum VisibilityLevel {
  public,
  friends,
  private;

  String get value => name;

  static VisibilityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return VisibilityLevel.public;
      case 'friends':
        return VisibilityLevel.friends;
      case 'private':
        return VisibilityLevel.private;
      default:
        return VisibilityLevel.public;
    }
  }
}

class ProfileUpdateRequest {
  final String? avatar;
  final String? name;
  final String? location;
  final String? bio;
  final String? phone;
  final String? friendInfo;
  final String? avatarVisibility;
  final String? nameVisibility;
  final String? locationVisibility;
  final String? bioVisibility;
  final String? phoneVisibility;
  final String? friendInfoVisibility;
  final String? musicPreferencesVisibility;
  final List<int>? musicPreferencesIds;

  const ProfileUpdateRequest({
    this.avatar,
    this.name,
    this.location,
    this.bio,
    this.phone,
    this.friendInfo,
    this.avatarVisibility,
    this.nameVisibility,
    this.locationVisibility,
    this.bioVisibility,
    this.phoneVisibility,
    this.friendInfoVisibility,
    this.musicPreferencesVisibility,
    this.musicPreferencesIds,
  });

  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{};
    
    if (avatar != null) formData['avatar'] = avatar;
    if (name != null) formData['name'] = name;
    if (location != null) formData['location'] = location;
    if (bio != null) formData['bio'] = bio;
    if (phone != null) formData['phone'] = phone;
    if (friendInfo != null) formData['friend_info'] = friendInfo;
    if (avatarVisibility != null) formData['avatar_visibility'] = avatarVisibility;
    if (nameVisibility != null) formData['name_visibility'] = nameVisibility;
    if (locationVisibility != null) formData['location_visibility'] = locationVisibility;
    if (bioVisibility != null) formData['bio_visibility'] = bioVisibility;
    if (phoneVisibility != null) formData['phone_visibility'] = phoneVisibility;
    if (friendInfoVisibility != null) formData['friend_info_visibility'] = friendInfoVisibility;
    if (musicPreferencesVisibility != null) formData['music_preferences_visibility'] = musicPreferencesVisibility;
    if (musicPreferencesIds != null) formData['music_preferences_ids'] = musicPreferencesIds;

    return formData;
  }
}
