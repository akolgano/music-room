// lib/models/api_models.dart
import 'models.dart';

class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class SignupRequest {
  final String username;
  final String email;
  final String password;

  const SignupRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
  };
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

class ChangePasswordRequest {
  final String email;
  final int otp;
  final String password;

  const ChangePasswordRequest({
    required this.email,
    required this.otp,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
    'password': password,
  };
}

class SocialLoginRequest {
  final String? accessToken;
  final String? idToken;
  final String? type;

  const SocialLoginRequest({
    this.accessToken,
    this.idToken,
    this.type,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (type != null) {
      json['type'] = type;
    }
    
    if (accessToken != null) {
      json['access_token'] = accessToken;
    }
    
    if (idToken != null) {
      json['id_token'] = idToken;
    }
    
    if (idToken != null) {
      json['token'] = idToken;
    } else if (accessToken != null) {
      json['token'] = accessToken;
    }
    
    return json;
  }
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;
  final String? tokenType;

  SocialLoginResult.success(this.token, this.provider, {this.tokenType}) 
      : success = true, error = null;
  
  SocialLoginResult.error(this.error) 
      : success = false, token = null, provider = null, tokenType = null;
  
  @override
  String toString() {
    if (success) {
      return 'SocialLoginResult.success(token: ${token?.substring(0, 20)}..., provider: $provider, tokenType: $tokenType)';
    } else {
      return 'SocialLoginResult.error($error)';
    }
  }
}

class SocialLinkRequest {
  final String? accessToken;
  final String? idToken;
  final String? type;

  const SocialLinkRequest({this.accessToken, this.idToken, this.type});

  Map<String, dynamic> toJson() => {'access_token': accessToken, 'id_token': idToken, 'type': type};
}

class CreatePlaylistRequest {
  final String name;
  final String description;
  final bool public;
  final String? deviceUuid;

  const CreatePlaylistRequest({required this.name, required this.description, required this.public, this.deviceUuid});

  Map<String, dynamic> toJson() {
    final json = { 'name': name, 'description': description, 'public': public };
    if (deviceUuid != null) json['device_uuid'] = deviceUuid!;
    return json;
  }
}

class UpdatePlaylistRequest {
  final String? name;
  final String? description;
  final bool? public;

  const UpdatePlaylistRequest({
    this.name,
    this.description,
    this.public,
  });

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'public': public};
}

class VisibilityRequest {
  final bool public;
  const VisibilityRequest({required this.public});
  Map<String, dynamic> toJson() => {'public': public};
}

class AddDeezerTrackRequest {
  final String deezerTrackId;
  const AddDeezerTrackRequest({required this.deezerTrackId});
  Map<String, dynamic> toJson() => {'deezer_track_id': deezerTrackId};
}

class AddTrackRequest {
  final String trackId;
  final String? deviceUuid;
  const AddTrackRequest({required this.trackId, this.deviceUuid});
  Map<String, dynamic> toJson() {
    final json = <String, dynamic> { 'deezer_id': trackId };
    if (deviceUuid != null) json['device_uuid'] = deviceUuid;
    return json;
  }
}

class MoveTrackRequest {
  final int rangeStart;
  final int insertBefore;
  final int? rangeLength;

  const MoveTrackRequest({required this.rangeStart, required this.insertBefore, this.rangeLength});

  Map<String, dynamic> toJson() => { 'range_start': rangeStart, 'insert_before': insertBefore, 'range_length': rangeLength };
}

class InviteUserRequest {
  final int userId;
  const InviteUserRequest({required this.userId});
  Map<String, dynamic> toJson() => {'user_id': userId};
}

class FriendRequestRequest {
  final int userId;
  const FriendRequestRequest({required this.userId});
  Map<String, dynamic> toJson() => {'user_id': userId};
}

class FriendRequestActionRequest {
  final int friendshipId;

  const FriendRequestActionRequest({required this.friendshipId});

  Map<String, dynamic> toJson() => {'friendship_id': friendshipId};
}

class RemoveFriendRequest {
  final int friendId;

  const RemoveFriendRequest({required this.friendId});

  Map<String, dynamic> toJson() => {'friend_id': friendId};
}

class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;

  const PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}

class AvatarUpdateRequest {
  final String? avatar;
  final String? mimeType;

  const AvatarUpdateRequest({
    this.avatar,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'mime_type': mimeType,
  };
}

class PublicBasicUpdateRequest {
  final String? gender;
  final String? location;

  const PublicBasicUpdateRequest({
    this.gender,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'location': location,
  };
}

class BioUpdateRequest {
  final String? bio;

  const BioUpdateRequest({this.bio});

  Map<String, dynamic> toJson() => {'bio': bio};
}

class PrivateInfoUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? street;
  final String? country;
  final String? postalCode;

  const PrivateInfoUpdateRequest({
    this.firstName,
    this.lastName,
    this.phone,
    this.street,
    this.country,
    this.postalCode,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'street': street,
    'country': country,
    'postal_code': postalCode,
  };
}

class FriendInfoUpdateRequest {
  final String? dob;
  final List<String>? hobbies;
  final String? friendInfo;

  const FriendInfoUpdateRequest({
    this.dob,
    this.hobbies,
    this.friendInfo,
  });

  Map<String, dynamic> toJson() => {
    'dob': dob,
    'hobbies': hobbies,
    'friend_info': friendInfo,
  };
}

class MusicPreferencesUpdateRequest {
  final List<String>? musicPreferences;

  const MusicPreferencesUpdateRequest({this.musicPreferences});

  Map<String, dynamic> toJson() => {'music_preferences': musicPreferences};
}

class AuthResult {
  final String token;
  final User user;

  const AuthResult({
    required this.token,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class PlaylistsResponse {
  final List<Playlist> playlists;

  const PlaylistsResponse({required this.playlists});

  factory PlaylistsResponse.fromJson(Map<String, dynamic> json) => PlaylistsResponse(
    playlists: (json['playlists'] as List<dynamic>)
        .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

class PlaylistDetailResponse {
  final Playlist playlist;

  const PlaylistDetailResponse({required this.playlist});

  factory PlaylistDetailResponse.fromJson(Map<String, dynamic> json) {
    dynamic playlistData = json['playlist'];
    
    if (playlistData is List && playlistData.isNotEmpty) playlistData = playlistData[0];
    
    return PlaylistDetailResponse(playlist: Playlist.fromJson(playlistData as Map<String, dynamic>));
  }
}

class CreatePlaylistResponse {
  final String playlistId;

  const CreatePlaylistResponse({required this.playlistId});

  factory CreatePlaylistResponse.fromJson(Map<String, dynamic> json) {
    if (json['playlist_id'] == null) {
      throw Exception('playlist_id is null in response: $json');
    }
    return CreatePlaylistResponse(
      playlistId: json['playlist_id'].toString(),
    );
  }
}

class TrackSearchResponse {
  final List<Track> tracks;

  const TrackSearchResponse({required this.tracks});

  factory TrackSearchResponse.fromJson(Map<String, dynamic> json) => TrackSearchResponse(
    tracks: (json['tracks'] as List<dynamic>)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

class DeezerSearchResponse {
  final List<Track> data;

  const DeezerSearchResponse({required this.data});

  factory DeezerSearchResponse.fromJson(Map<String, dynamic> json) => DeezerSearchResponse(
    data: (json['data'] as List<dynamic>)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

class PlaylistTracksResponse {
  final List<PlaylistTrack> tracks;

  const PlaylistTracksResponse({required this.tracks});

  factory PlaylistTracksResponse.fromJson(Map<String, dynamic> json) => PlaylistTracksResponse(
    tracks: (json['tracks'] as List<dynamic>)
        .map((t) => PlaylistTrack.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}

class FriendsResponse {
  final List<int> friends;

  const FriendsResponse({required this.friends});

  factory FriendsResponse.fromJson(Map<String, dynamic> json) => FriendsResponse(
    friends: (json['friends'] as List<dynamic>).cast<int>(),
  );
}

class PendingRequestsResponse {
  final List<Map<String, dynamic>> requests;

  const PendingRequestsResponse({required this.requests});

  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) => PendingRequestsResponse(
    requests: (json['requests'] as List<dynamic>).cast<Map<String, dynamic>>(),
  );
}

class MessageResponse {
  final String message;

  const MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) => MessageResponse(
    message: json['message'] as String,
  );
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
  final String? avatar;
  final String? gender;
  final String? location;
  final String? bio;

  const ProfilePublicResponse({
    this.avatar,
    this.gender,
    this.location,
    this.bio,
  });

  factory ProfilePublicResponse.fromJson(Map<String, dynamic> json) => ProfilePublicResponse(
    avatar: json['avatar'] as String?,
    gender: json['gender'] as String?,
    location: json['location'] as String?,
    bio: json['bio'] as String?,
  );
}

class ProfilePrivateResponse {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? street;
  final String? country;
  final String? postalCode;

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

  factory ProfileFriendResponse.fromJson(Map<String, dynamic> json) => ProfileFriendResponse(
    dob: json['dob'] as String?,
    hobbies: (json['hobbies'] as List<dynamic>?)?.cast<String>(),
    friendInfo: json['friend_info'] as String?,
  );
}

class ProfileMusicResponse {
  final List<String>? musicPreferences;
  const ProfileMusicResponse({this.musicPreferences});

  factory ProfileMusicResponse.fromJson(Map<String, dynamic> json) => ProfileMusicResponse(
    musicPreferences: (json['music_preferences'] as List<dynamic>?)?.cast<String>(),
  );
}

class EmailOtpRequest {
  final String email;

  const EmailOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class SignupWithOtpRequest {
  final String username;
  final String email;
  final String password;
  final int otp;

  const SignupWithOtpRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'otp': otp,
  };
}

class RegisterDeviceRequest {
  final String uuid;
  final String licenseKey;
  final String deviceName;

  const RegisterDeviceRequest({
    required this.uuid,
    required this.licenseKey,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'license_key': licenseKey,
    'device_name': deviceName,
  };
}

class DelegateControlRequest {
  final String deviceUuid;
  final int delegateUserId;
  final bool canControl;

  const DelegateControlRequest({
    required this.deviceUuid,
    required this.delegateUserId,
    required this.canControl,
  });

  Map<String, dynamic> toJson() => {
    'device_uuid': deviceUuid,
    'delegate_user_id': delegateUserId,
    'can_control': canControl,
  };
}

class DevicesResponse {
  final List<Device> devices;

  const DevicesResponse({required this.devices});

  factory DevicesResponse.fromJson(Map<String, dynamic> json) => DevicesResponse(
    devices: (json['devices'] as List<dynamic>?)
        ?.map((d) => Device.fromJson(d as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class DeviceResponse {
  final Device device;

  const DeviceResponse({required this.device});

  factory DeviceResponse.fromJson(Map<String, dynamic> json) => DeviceResponse(
    device: Device.fromJson(json['device'] as Map<String, dynamic>),
  );
}

class PermissionResponse {
  final bool canControl;

  const PermissionResponse({required this.canControl});

  factory PermissionResponse.fromJson(Map<String, dynamic> json) => PermissionResponse(
    canControl: json['can_control'] as bool,
  );
}
