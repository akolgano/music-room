// lib/models/friend_models.dart
class FriendData {
  final int friendId;
  final String friendUsername;
  final String? profilePictureUrl;

  const FriendData({
    required this.friendId,
    required this.friendUsername,
    this.profilePictureUrl,
  });

  factory FriendData.fromJson(Map<String, dynamic> json) {
    return FriendData(
      friendId: json['friend_id'] as int,
      friendUsername: json['friend_username'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }
}

class FriendInvitation {
  final int friendId;
  final String friendUsername;
  final int friendshipId;
  final String? profilePictureUrl;
  final String status;

  const FriendInvitation({
    required this.friendId,
    required this.friendUsername,
    required this.friendshipId,
    this.profilePictureUrl,
    required this.status,
  });

  factory FriendInvitation.fromJson(Map<String, dynamic> json) {
    return FriendInvitation(
      friendId: json['friend_id'] as int,
      friendUsername: json['friend_username'] as String,
      friendshipId: json['friendship_id'] as int,
      profilePictureUrl: json['profile_picture_url'] as String?,
      status: json['status'] as String,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

class FriendsListResponse {
  final List<FriendData> friends;

  const FriendsListResponse({required this.friends});

  factory FriendsListResponse.fromJson(Map<String, dynamic> json) {
    return FriendsListResponse(
      friends: (json['friends'] as List<dynamic>?)
          ?.map((item) => FriendData.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ReceivedInvitationsResponse {
  final List<FriendInvitation> receivedInvitations;

  const ReceivedInvitationsResponse({required this.receivedInvitations});

  factory ReceivedInvitationsResponse.fromJson(Map<String, dynamic> json) {
    return ReceivedInvitationsResponse(
      receivedInvitations: (json['received_invitations'] as List<dynamic>?)
          ?.map((item) => FriendInvitation.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class SentInvitationsResponse {
  final List<FriendInvitation> sentInvitations;

  const SentInvitationsResponse({required this.sentInvitations});

  factory SentInvitationsResponse.fromJson(Map<String, dynamic> json) {
    return SentInvitationsResponse(
      sentInvitations: (json['sent_invitations'] as List<dynamic>?)
          ?.map((item) => FriendInvitation.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class FriendRequestResponse {
  final String message;
  final int friendId;
  final int friendshipId;

  const FriendRequestResponse({required this.message, required this.friendId, required this.friendshipId});

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      message: json['message'] as String,
      friendId: json['friend_id'] as int,
      friendshipId: json['friendship_id'] as int,
    );
  }
}

class FriendInvitationsResponse {
  final List<FriendInvitation> invitations;
  
  const FriendInvitationsResponse({required this.invitations});
  
  factory FriendInvitationsResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> invitationsList = [];
    if (json.containsKey('received_invitations')) {
      invitationsList = json['received_invitations'] as List<dynamic>;
    } else if (json.containsKey('sent_invitations')) {
      invitationsList = json['sent_invitations'] as List<dynamic>;
    }
    
    return FriendInvitationsResponse(
      invitations: invitationsList
          .map((item) => FriendInvitation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
