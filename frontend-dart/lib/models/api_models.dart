import 'music_models.dart';

class LoginRequest {
  final String username, password;
  const LoginRequest({required this.username, required this.password});
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LogoutRequest {
  final String username;
  const LogoutRequest({required this.username});
  Map<String, dynamic> toJson() => {'username': username};
}

class ForgotPasswordRequest {
  final String email;
  const ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class SignupWithOtpRequest {
  final String username, email, password, otp;
  const SignupWithOtpRequest({required this.username, required this.email, required this.password, required this.otp});
  Map<String, dynamic> toJson() => {'username': username, 'email': email, 'password': password, 'otp': otp};
}

class ChangePasswordRequest {
  final String email, password, otp;
  const ChangePasswordRequest({required this.email, required this.otp, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'otp': otp, 'password': password};
}

class PasswordChangeRequest {
  final String currentPassword, newPassword;
  const PasswordChangeRequest({required this.currentPassword, required this.newPassword});
  Map<String, dynamic> toJson() => {'current_password': currentPassword, 'new_password': newPassword};
}

class EmailOtpRequest {
  final String email;
  const EmailOtpRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class SocialLoginRequest {
  final String? fbAccessToken, idToken, socialId, socialName, socialEmail;
  const SocialLoginRequest({this.fbAccessToken, this.idToken, this.socialId, this.socialName, this.socialEmail});
  Map<String, dynamic> toJson() => {
    if (fbAccessToken != null) 'fbAccessToken': fbAccessToken,
    if (idToken != null) 'idToken': idToken,
    if (socialId != null) 'socialId': socialId,
    if (socialName != null) 'socialName': socialName,
    if (socialEmail != null) 'socialEmail': socialEmail,
  };
}

class SocialLinkRequest {
  final String? fbAccessToken, idToken, socialId, socialName, socialEmail;
  const SocialLinkRequest({this.fbAccessToken, this.idToken, this.socialId, this.socialName, this.socialEmail});
  Map<String, dynamic> toJson() => {
    if (fbAccessToken != null) 'fbAccessToken': fbAccessToken,
    if (idToken != null) 'idToken': idToken,
    if (socialId != null) 'socialId': socialId,
    if (socialName != null) 'socialName': socialName,
    if (socialEmail != null) 'socialEmail': socialEmail,
  };
}

class ProfileUpdateRequest {
  final String? avatar;
  final String? mimeType;
  final String? name;
  final String? location;
  final String? bio;
  final String? phone;
  final String? friendInfo;
  final List<int>? musicPreferencesIds;
  final String? avatarVisibility;
  final String? nameVisibility;
  final String? locationVisibility;
  final String? bioVisibility;
  final String? phoneVisibility;
  final String? friendInfoVisibility;
  final String? musicPreferencesVisibility;

  const ProfileUpdateRequest({this.avatar, this.mimeType, this.name, this.location, this.bio, this.phone, this.friendInfo,
    this.musicPreferencesIds,
    this.avatarVisibility,
    this.nameVisibility,
    this.locationVisibility,
    this.bioVisibility,
    this.phoneVisibility,
    this.friendInfoVisibility,
    this.musicPreferencesVisibility,
  });

  Map<String, dynamic> toJson() => {
    if (avatar != null) 'avatar': avatar,
    if (mimeType != null) 'mime_type': mimeType,
    if (name != null) 'name': name,
    if (location != null) 'location': location,
    if (bio != null) 'bio': bio,
    if (phone != null) 'phone': phone,
    if (friendInfo != null) 'friend_info': friendInfo,
    if (musicPreferencesIds != null) 'music_preferences_ids': musicPreferencesIds,
    if (avatarVisibility != null) 'avatar_visibility': avatarVisibility,
    if (nameVisibility != null) 'name_visibility': nameVisibility,
    if (locationVisibility != null) 'location_visibility': locationVisibility,
    if (bioVisibility != null) 'bio_visibility': bioVisibility,
    if (phoneVisibility != null) 'phone_visibility': phoneVisibility,
    if (friendInfoVisibility != null) 'friend_info_visibility': friendInfoVisibility,
    if (musicPreferencesVisibility != null) 'music_preferences_visibility': musicPreferencesVisibility,
  };
}

class ProfileResponse {
  final String? avatar;
  final String? name;
  final String? location;
  final String? bio;
  final String? phone;
  final String? friendInfo;
  final List<String>? musicPreferences;
  final List<int>? musicPreferencesIds;
  final String? avatarVisibility;
  final String? nameVisibility;
  final String? locationVisibility;
  final String? bioVisibility;
  final String? phoneVisibility;
  final String? friendInfoVisibility;
  final String? musicPreferencesVisibility;

  const ProfileResponse({
    this.avatar,
    this.name,
    this.location,
    this.bio,
    this.phone,
    this.friendInfo,
    this.musicPreferences,
    this.musicPreferencesIds,
    this.avatarVisibility,
    this.nameVisibility,
    this.locationVisibility,
    this.bioVisibility,
    this.phoneVisibility,
    this.friendInfoVisibility,
    this.musicPreferencesVisibility,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
    avatar: json['avatar'] as String?,
    name: json['name'] as String?,
    location: json['location'] as String?,
    bio: json['bio'] as String?,
    phone: json['phone'] as String?,
    friendInfo: json['friend_info'] as String?,
    musicPreferences: (json['music_preferences'] as List<dynamic>?)?.cast<String>(),
    musicPreferencesIds: (json['music_preferences_ids'] as List<dynamic>?)?.cast<int>(),
    avatarVisibility: json['avatar_visibility'] as String?,
    nameVisibility: json['name_visibility'] as String?,
    locationVisibility: json['location_visibility'] as String?,
    bioVisibility: json['bio_visibility'] as String?,
    phoneVisibility: json['phone_visibility'] as String?,
    friendInfoVisibility: json['friend_info_visibility'] as String?,
    musicPreferencesVisibility: json['music_preferences_visibility'] as String?,
  );

}

class PublicInfoUpdateRequest {
  final String? avatarBase64, mimeType, gender, location, bio;
  const PublicInfoUpdateRequest({this.avatarBase64, this.mimeType, this.gender, this.location, this.bio});
  Map<String, dynamic> toJson() => {
    if (avatarBase64 != null) 'avatar_base64': avatarBase64,
    if (mimeType != null) 'mime_type': mimeType,
    if (gender != null) 'gender': gender,
    if (location != null) 'location': location,
    if (bio != null) 'bio': bio,
  };
}

class PrivateInfoUpdateRequest {
  final String? firstName, lastName, phone, street, country, postalCode;
  const PrivateInfoUpdateRequest({this.firstName, this.lastName, this.phone, this.street, this.country, this.postalCode});
  Map<String, dynamic> toJson() => {
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (phone != null) 'phone': phone,
    if (street != null) 'street': street,
    if (country != null) 'country': country,
    if (postalCode != null) 'postal_code': postalCode,
  };
}

class FriendInfoUpdateRequest {
  final String? dob, friendInfo;
  final List<String>? hobbies;
  const FriendInfoUpdateRequest({this.dob, this.hobbies, this.friendInfo});
  Map<String, dynamic> toJson() => {
    if (dob != null) 'dob': dob,
    if (hobbies != null) 'hobbies': hobbies,
    if (friendInfo != null) 'friend_info': friendInfo,
  };
}

class MusicPreference {
  final int id;
  final String name;
  const MusicPreference({required this.id, required this.name});
  factory MusicPreference.fromJson(Map<String, dynamic> json) => MusicPreference(
    id: json['id'] as int,
    name: json['name'] as String,
  );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ProfileByIdResponse {
  final String id;
  final String user;
  final String? avatar;
  final String? name;
  final String? location;
  final String? bio;
  final String? phone;
  final String? friendInfo;
  final List<String>? musicPreferences;
  final List<int>? musicPreferencesIds;
  final String? avatarVisibility;
  final String? nameVisibility;
  final String? locationVisibility;
  final String? bioVisibility;
  final String? phoneVisibility;
  final String? friendInfoVisibility;
  final String? musicPreferencesVisibility;

  const ProfileByIdResponse({
    required this.id,
    required this.user,
    this.avatar,
    this.name,
    this.location,
    this.bio,
    this.phone,
    this.friendInfo,
    this.musicPreferences,
    this.musicPreferencesIds,
    this.avatarVisibility,
    this.nameVisibility,
    this.locationVisibility,
    this.bioVisibility,
    this.phoneVisibility,
    this.friendInfoVisibility,
    this.musicPreferencesVisibility,
  });

  factory ProfileByIdResponse.fromJson(Map<String, dynamic> json) => ProfileByIdResponse(
    id: json['id'].toString(),
    user: json['user'] as String,
    avatar: json['avatar'] as String?,
    name: json['name'] as String?,
    location: json['location'] as String?,
    bio: json['bio'] as String?,
    phone: json['phone'] as String?,
    friendInfo: json['friend_info'] as String?,
    musicPreferences: (json['music_preferences'] as List<dynamic>?)?.cast<String>(),
    musicPreferencesIds: (json['music_preferences_ids'] as List<dynamic>?)?.cast<int>(),
    avatarVisibility: json['avatar_visibility'] as String?,
    nameVisibility: json['name_visibility'] as String?,
    locationVisibility: json['location_visibility'] as String?,
    bioVisibility: json['bio_visibility'] as String?,
    phoneVisibility: json['phone_visibility'] as String?,
    friendInfoVisibility: json['friend_info_visibility'] as String?,
    musicPreferencesVisibility: json['music_preferences_visibility'] as String?,
  );

}

class AvatarUpdateRequest {
  final String? avatar, mimeType;
  const AvatarUpdateRequest({this.avatar, this.mimeType});
  Map<String, dynamic> toJson() => {
    if (avatar != null) 'avatar_base64': avatar,
    if (mimeType != null) 'mime_type': mimeType,
  };
}

class PublicBasicUpdateRequest {
  final String? gender, location;
  const PublicBasicUpdateRequest({this.gender, this.location});
  Map<String, dynamic> toJson() => {
    if (gender != null) 'gender': gender,
    if (location != null) 'location': location,
  };
}

class BioUpdateRequest {
  final String? bio;
  const BioUpdateRequest({this.bio});
  Map<String, dynamic> toJson() => {if (bio != null) 'bio': bio};
}

class CreatePlaylistRequest {
  final String name;
  final String description;
  final bool public;
  final String? deviceUuid;
  final String licenseType;
  final bool event;
  
  const CreatePlaylistRequest({
    required this.name, 
    required this.description, 
    required this.public, 
    this.deviceUuid,
    this.licenseType = 'open',
    this.event = false,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'public': public,
    'license_type': licenseType, 'event': event,
    if (deviceUuid != null) 'device_uuid': deviceUuid!,
  };
}

class UpdatePlaylistRequest {
  final String? name;
  final String? description;
  final bool? isEvent;
  
  const UpdatePlaylistRequest({
    this.name,
    this.description,
    this.isEvent,
  });
  
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (isEvent != null) 'event': isEvent,
  };
}

class VisibilityRequest {
  final bool public;
  const VisibilityRequest({required this.public});
  Map<String, dynamic> toJson() => {'public': public};
}

class AddTrackRequest {
  final String trackId;
  final String? deviceUuid;
  const AddTrackRequest({required this.trackId, this.deviceUuid});
  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    if (deviceUuid != null) 'device_uuid': deviceUuid,
  };
}

class MoveTrackRequest {
  final int rangeStart;
  final int insertBefore;
  final int? rangeLength;
  
  const MoveTrackRequest({
    required this.rangeStart, 
    required this.insertBefore, 
    this.rangeLength
  });
  
  Map<String, dynamic> toJson() => { 
    'range_start': rangeStart, 
    'insert_before': insertBefore, 
    if (rangeLength != null) 'range_length': rangeLength 
  };
}

class InviteUserRequest {
  final String userId;
  const InviteUserRequest({required this.userId});
  Map<String, dynamic> toJson() => {'user_id': userId};
}

class PlaylistLicenseRequest {
  final String licenseType;
  final List<String>? invitedUsers;
  final String? voteStartTime;
  final String? voteEndTime;
  final double? latitude;
  final double? longitude;
  final int? allowedRadiusMeters;
  
  const PlaylistLicenseRequest({
    required this.licenseType,
    this.invitedUsers,
    this.voteStartTime,
    this.voteEndTime,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
  });
  
  Map<String, dynamic> toJson() => {
    'license_type': licenseType,
    if (invitedUsers != null) 'invited_users': invitedUsers,
    if (voteStartTime != null) 'vote_start_time': voteStartTime,
    if (voteEndTime != null) 'vote_end_time': voteEndTime,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (allowedRadiusMeters != null) 'allowed_radius_meters': allowedRadiusMeters,
  };
}

class PlaylistLicenseResponse {
  final String licenseType;
  final List<String> invitedUsers;
  final String? voteStartTime;
  final String? voteEndTime;
  final double? latitude;
  final double? longitude;
  final int? allowedRadiusMeters;
  
  const PlaylistLicenseResponse({
    required this.licenseType,
    required this.invitedUsers,
    this.voteStartTime,
    this.voteEndTime,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters,
  });
  
  factory PlaylistLicenseResponse.fromJson(Map<String, dynamic> json) => 
      PlaylistLicenseResponse(
        licenseType: json['license_type'] as String,
        invitedUsers: (json['invited_users'] as List<dynamic>?)?.cast<String>() ?? [],
        voteStartTime: json['vote_start_time'] as String?,
        voteEndTime: json['vote_end_time'] as String?,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        allowedRadiusMeters: json['allowed_radius_meters'] as int?,
      );
}

class VoteRequest {
  final int rangeStart;
  final double? latitude;
  final double? longitude;
  
  const VoteRequest({ 
    required this.rangeStart,
    this.latitude,
    this.longitude,
  });
  
  Map<String, dynamic> toJson() => {
    'range_start': rangeStart,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

class VoteResponse {
  final String message;
  final List<PlaylistInfoWithVotes> playlist;
  
  const VoteResponse({ required this.message, required this.playlist });
  
  factory VoteResponse.fromJson(Map<String, dynamic> json) => VoteResponse(
    message: json['message'] as String? ?? 'Vote recorded',
    playlist: (json['playlist'] as List<dynamic>?)
        ?.map((item) => PlaylistInfoWithVotes.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class FriendRequestRequest {
  final String userId;
  const FriendRequestRequest({required this.userId});
  Map<String, dynamic> toJson() => {'user_id': userId};
}

class FriendRequestActionRequest {
  final String friendshipId;
  const FriendRequestActionRequest({required this.friendshipId});
  Map<String, dynamic> toJson() => {'friendship_id': friendshipId};
}

class RemoveFriendRequest {
  final String friendId;
  const RemoveFriendRequest({required this.friendId});
  Map<String, dynamic> toJson() => {'friend_id': friendId};
}

class AuthResult {
  final String token;
  final User user;
  
  const AuthResult({required this.token, required this.user});
  
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class PlaylistsResponse {
  final List<Playlist> playlists;
  const PlaylistsResponse({required this.playlists});
  factory PlaylistsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['playlists'] ?? json['events'] ?? []) as List<dynamic>;
    return PlaylistsResponse(
      playlists: dataList.map((p) => Playlist.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class PlaylistDetailResponse {
  final Playlist playlist;
  const PlaylistDetailResponse({required this.playlist});
  factory PlaylistDetailResponse.fromJson(Map<String, dynamic> json) {
    dynamic data = json['playlist'];
    if (data is List && data.isNotEmpty) data = data[0];
    return PlaylistDetailResponse(playlist: Playlist.fromJson(data as Map<String, dynamic>));
  }
}

class CreatePlaylistResponse {
  final String playlistId;
  const CreatePlaylistResponse({required this.playlistId});
  factory CreatePlaylistResponse.fromJson(Map<String, dynamic> json) {
    if (json['playlist_id'] == null) throw Exception('playlist_id is null in response: $json');
    return CreatePlaylistResponse(playlistId: json['playlist_id'].toString());
  }
}

class DeezerSearchResponse {
  final List<Track> data;
  const DeezerSearchResponse({required this.data});
  factory DeezerSearchResponse.fromJson(Map<String, dynamic> json) => DeezerSearchResponse(
    data: (json['data'] as List<dynamic>).map((t) => Track.fromJson(t as Map<String, dynamic>)).toList(),
  );
}

class PlaylistTracksResponse {
  final List<PlaylistTrack> tracks;
  const PlaylistTracksResponse({required this.tracks});
  factory PlaylistTracksResponse.fromJson(Map<String, dynamic> json) => PlaylistTracksResponse(
    tracks: (json['tracks'] as List<dynamic>).map((t) => PlaylistTrack.fromJson(t as Map<String, dynamic>)).toList(),
  );
}

class Friend {
  final String id, username;
  final String? email;
  final String? profilePictureUrl;
  const Friend({required this.id, required this.username, this.email, this.profilePictureUrl});
  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    id: (json['friend_id'] ?? json['id'])?.toString() ?? '',
    username: json['friend_username'] as String? ?? json['username'] as String? ?? 'Unknown User',
    email: json['email'] as String?,
    profilePictureUrl: json['profile_picture_url'] as String?,
  );
}

class FriendsResponse {
  final List<Friend> friends;
  
  const FriendsResponse({required this.friends});
  
  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    final friendsList = json['friends'] as List<dynamic>? ?? [];
    return FriendsResponse(
      friends: friendsList.map((item) {
        if (item is Map<String, dynamic>) {
          return Friend.fromJson(item);
        } else {
          return Friend(
            id: item.toString(),
            username: item.toString(),
          );
        }
      }).toList(),
    );
  }
}

class Friendship {
  final String id;
  final int fromUser;
  final int toUser;
  final String status;
  final DateTime createdAt;

  const Friendship({required this.id, required this.fromUser, required this.toUser, required this.status, required this.createdAt});

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'].toString(),
    fromUser: json['from_user'] as int,
    toUser: json['to_user'] as int,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class PendingRequestsResponse {
  final List<Map<String, dynamic>> requests;
  const PendingRequestsResponse({required this.requests});
  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) => 
      PendingRequestsResponse(requests: (json['requests'] as List<dynamic>).cast<Map<String, dynamic>>());
}

class MessageResponse {
  final String message;
  const MessageResponse({required this.message});
  factory MessageResponse.fromJson(Map<String, dynamic> json) => MessageResponse(message: json['message'] as String);
}

class UserResponse {
  final String id;
  final String username;
  final String? email;
  final bool? isPasswordUsable;
  final bool? hasSocialAccount;
  final Map<String, dynamic>? social;
  
  const UserResponse({
    required this.id,
    required this.username,
    this.email,
    this.isPasswordUsable,
    this.hasSocialAccount,
    this.social,
  });
  
  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'].toString(),
    username: json['username'] as String,
    email: json['email'] as String?,
    isPasswordUsable: json['is_password_usable'] as bool?,
    hasSocialAccount: json['has_social_account'] as bool?,
    social: json['social'] as Map<String, dynamic>?,
  );
}

class ProfilePublicResponse {
  final String? avatar, gender, location, bio;
  const ProfilePublicResponse({this.avatar, this.gender, this.location, this.bio});
  factory ProfilePublicResponse.fromJson(Map<String, dynamic> json) => ProfilePublicResponse(
    avatar: json['avatar'] as String?,
    gender: json['gender'] as String?,
    location: json['location'] as String?,
    bio: json['bio'] as String?,
  );
}

class ProfilePrivateResponse {
  final String? firstName, lastName, phone, street, country, postalCode;
  const ProfilePrivateResponse({this.firstName, this.lastName, this.phone, this.street, this.country, this.postalCode});
  factory ProfilePrivateResponse.fromJson(Map<String, dynamic> json) => ProfilePrivateResponse(
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    phone: json['phone'] as String?,
    street: json['street'] as String?,
    country: json['country'] as String?,
    postalCode: json['postal_code'] as String?,
  );
}

class ProfileFriendResponse {
  final String? dob;
  final List<String>? hobbies;
  final String? friendInfo;
  
  const ProfileFriendResponse({this.dob, this.hobbies, this.friendInfo});
  
  factory ProfileFriendResponse.fromJson(Map<String, dynamic> json) => 
      ProfileFriendResponse(
        dob: json['dob'] as String?,
        hobbies: (json['hobbies'] as List<dynamic>?)?.cast<String>(),
        friendInfo: json['friend_info'] as String?,
      );
}

class ProfileMusicResponse {
  final List<String>? musicPreferences;
  
  const ProfileMusicResponse({this.musicPreferences});
  
  factory ProfileMusicResponse.fromJson(Map<String, dynamic> json) => 
      ProfileMusicResponse(musicPreferences: (json['music_preferences'] as List<dynamic>?)?.cast<String>());
}

class FriendInvitationsResponse {
  final List<Map<String, dynamic>> invitations;
  
  const FriendInvitationsResponse({required this.invitations});
  
  factory FriendInvitationsResponse.fromJson(Map<String, dynamic> json) {
    final possibleKeys = ['received_invitations', 'sent_invitations', 'invitations'];
    
    for (final key in possibleKeys) {
      final rawList = json[key] as List<dynamic>?;
      if (rawList != null && rawList.isNotEmpty) {
        return FriendInvitationsResponse(
          invitations: rawList.whereType<Map<String, dynamic>>().toList(),
        );
      }
    }
    
    return const FriendInvitationsResponse(invitations: []);
  }
}

class BatchLibraryAddResult {
  final int totalTracks;
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final List<String> successfulTracks;

  const BatchLibraryAddResult({required this.totalTracks, required this.successCount, required this.failureCount, this.errors = const [], this.successfulTracks = const []});

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks && failureCount == 0;
  
  String get summaryMessage => isCompleteSuccess ? 'All $totalTracks tracks added to your library successfully!'
    : hasPartialSuccess ? '$successCount/$totalTracks tracks added to your library'
    : 'Failed to add tracks to your library';

  String get detailedMessage => [
    if (successCount > 0) '$successCount added',
    if (failureCount > 0) '$failureCount failed',
  ].join(', ');
}

class ActivityLogRequest {
  final String action;
  final String? details;
  final Map<String, dynamic>? metadata;
  
  const ActivityLogRequest({
    required this.action, 
    this.details, 
    this.metadata
  });
  
  Map<String, dynamic> toJson() => {
    'action': action,
    if (details != null) 'details': details,
    if (metadata != null) 'metadata': metadata,
  };
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  const SocialLoginResult._({required this.success, this.token, this.provider, this.error});

  factory SocialLoginResult.success(String token, String provider) => 
      SocialLoginResult._(success: true, token: token, provider: provider);

  factory SocialLoginResult.error(String error) => 
      SocialLoginResult._(success: false, error: error);
}

class AddTrackResult {
  final bool success;
  final String message;
  final bool isDuplicate;

  const AddTrackResult({ required this.success, required this.message, this.isDuplicate = false });

  factory AddTrackResult.fromJson(Map<String, dynamic> json) => AddTrackResult(
    success: json['success'] as bool,
    message: json['message'] as String,
    isDuplicate: json['is_duplicate'] ?? false,
  );
}

class BatchAddResult {
  final int totalTracks;
  final int successCount;
  final int duplicateCount;
  final int failureCount;
  final List<String> errors;

  const BatchAddResult({
    required this.totalTracks,
    required this.successCount,
    required this.duplicateCount,
    required this.failureCount,
    this.errors = const [],
  });

  factory BatchAddResult.fromJson(Map<String, dynamic> json) => BatchAddResult(
    totalTracks: json['total_tracks'] as int,
    successCount: json['success_count'] as int,
    duplicateCount: json['duplicate_count'] as int,
    failureCount: json['failure_count'] as int,
    errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks;
  
  String get summaryMessage => isCompleteSuccess ? 'All $totalTracks tracks added successfully!'
    : hasPartialSuccess ? '$successCount/$totalTracks tracks added successfully'
    : 'Failed to add tracks to playlist';

  String get detailedMessage => [
    if (successCount > 0) '$successCount added',
    if (duplicateCount > 0) '$duplicateCount duplicates',
    if (failureCount > 0) '$failureCount failed',
  ].join(', ');
}
