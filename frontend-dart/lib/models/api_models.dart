// lib/models/api_models.dart
import 'models.dart';

class LoginRequest {
  final String username;
  final String password;
  const LoginRequest({required this.username, required this.password});
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class SignupWithOtpRequest {
  final String username;
  final String email;
  final String password;
  final int otp;
  const SignupWithOtpRequest({ required this.username, required this.email, required this.password, required this.otp });
  Map<String, dynamic> toJson() => {'username': username, 'email': email, 'password': password, 'otp': otp};
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
  const ChangePasswordRequest({ required this.email, required this.otp, required this.password });
  Map<String, dynamic> toJson() => { 'email': email, 'otp': otp, 'password': password };
}

class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;
  const PasswordChangeRequest({ required this.currentPassword, required this.newPassword });
  Map<String, dynamic> toJson() => { 'current_password': currentPassword, 'new_password': newPassword };
}

class EmailOtpRequest {
  final String email;
  const EmailOtpRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class SocialLoginRequest {
  final String? fbAccessToken; 
  final String? idToken;       
  final String? type;          
  const SocialLoginRequest({ this.fbAccessToken, this.idToken, this.type });
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fbAccessToken != null) json['fbAccessToken'] = fbAccessToken;
    if (idToken != null) json['idToken'] = idToken;
    if (type != null) json['type'] = type;
    return json;
  }
}

class SocialLinkRequest {
  final String? fbAccessToken; 
  final String? idToken;       
  final String? type;          
  const SocialLinkRequest({ this.fbAccessToken, this.idToken, this.type });
  Map<String, dynamic> toJson() => {
    if (fbAccessToken != null) 'fbAccessToken': fbAccessToken,
    if (idToken != null) 'idToken': idToken,
    if (type != null) 'type': type,
  };
}

class CreatePlaylistRequest {
  final String name;
  final String description;
  final bool public;
  final String? deviceUuid;
  const CreatePlaylistRequest({
    required this.name, 
    required this.description, 
    required this.public, 
    this.deviceUuid
  });
  Map<String, dynamic> toJson() {
    final json = { 
      'name': name, 
      'description': description, 
      'public': public 
    };
    if (deviceUuid != null) json['device_uuid'] = deviceUuid!;
    return json;
  }
}

class UpdatePlaylistRequest {
  final String? name;
  final String? description;
  final bool? public;
  const UpdatePlaylistRequest({this.name, this.description, this.public});
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (public != null) 'public': public,
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
  Map<String, dynamic> toJson() {
    final json = <String, dynamic> { 'track_id': trackId };
    if (deviceUuid != null) json['device_uuid'] = deviceUuid;
    return json;
  }
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
  final int userId;
  const InviteUserRequest({required this.userId});
  Map<String, dynamic> toJson() => {'user_id': userId};
}

class PlaylistLicenseRequest {
  final String licenseType;
  final List<int>? invitedUsers;
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
  final List<int> invitedUsers;
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
        invitedUsers: (json['invited_users'] as List<dynamic>?)?.cast<int>() ?? [],
        voteStartTime: json['vote_start_time'] as String?,
        voteEndTime: json['vote_end_time'] as String?,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        allowedRadiusMeters: json['allowed_radius_meters'] as int?,
      );
}

class VoteRequest {
  final int rangeStart;
  const VoteRequest({ required this.rangeStart });
  Map<String, dynamic> toJson() => { 'range_start': rangeStart };
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
  factory PlaylistsResponse.fromJson(Map<String, dynamic> json) => 
      PlaylistsResponse(
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
    if (playlistData is List && playlistData.isNotEmpty) {
      playlistData = playlistData[0];
    }
    return PlaylistDetailResponse(
        playlist: Playlist.fromJson(playlistData as Map<String, dynamic>));
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

class DeezerSearchResponse {
  final List<Track> data;
  const DeezerSearchResponse({required this.data});
  factory DeezerSearchResponse.fromJson(Map<String, dynamic> json) => 
      DeezerSearchResponse(
        data: (json['data'] as List<dynamic>)
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class PlaylistTracksResponse {
  final List<PlaylistTrack> tracks;
  const PlaylistTracksResponse({required this.tracks});
  factory PlaylistTracksResponse.fromJson(Map<String, dynamic> json) => 
      PlaylistTracksResponse(
        tracks: (json['tracks'] as List<dynamic>)
            .map((t) => PlaylistTrack.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class FriendsResponse {
  final List<int> friends;
  const FriendsResponse({required this.friends});
  factory FriendsResponse.fromJson(Map<String, dynamic> json) => 
      FriendsResponse(
        friends: (json['friends'] as List<dynamic>).cast<int>(),
      );
}

class PendingRequestsResponse {
  final List<Map<String, dynamic>> requests;
  const PendingRequestsResponse({required this.requests});
  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) => 
      PendingRequestsResponse(
        requests: (json['requests'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
}

class MessageResponse {
  final String message;
  const MessageResponse({required this.message});
  factory MessageResponse.fromJson(Map<String, dynamic> json) => 
      MessageResponse(message: json['message'] as String);
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
