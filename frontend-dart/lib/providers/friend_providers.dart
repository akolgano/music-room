import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/api_services.dart';
import '../models/api_models.dart';

class FriendService {
  final ApiService _api;
  FriendService(this._api);

  Future<List<Friend>> getFriends(String token) async {
    final response = await _api.getFriends(token); 
    return response.friends;
  }

  Future<String> acceptFriendRequest(String friendshipId, String token) async {
    final response = await _api.acceptFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<String> rejectFriendRequest(String friendshipId, String token) async {
    final response = await _api.rejectFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<void> removeFriend(String friendId, String token) async {
    await _api.removeFriend(friendId, token); 
  }

  Future<List<Map<String, dynamic>>> getReceivedInvitations(String token) async {
    final response = await _api.getReceivedInvitations(token);
    return response.invitations;
  }

  Future<List<Map<String, dynamic>>> getSentInvitations(String token) async {
    final response = await _api.getSentInvitations(token);
    return response.invitations;
  }
}

class FriendProvider extends BaseProvider {
  final FriendService _friendService = getIt<FriendService>();
  final ApiService _apiService = getIt<ApiService>();
  
  List<Friend> _friends = [];
  List<Map<String, dynamic>> _receivedInvitations = [];
  List<Map<String, dynamic>> _sentInvitations = [];

  List<Friend> get friends => List.unmodifiable(_friends);
  List<Map<String, dynamic>> get receivedInvitations => List.unmodifiable(_receivedInvitations);
  List<Map<String, dynamic>> get sentInvitations => List.unmodifiable(_sentInvitations);

  Future<void> fetchFriends(String token) async {
    final result = await executeAsync(
      () => _friendService.getFriends(token),
      errorMessage: 'Failed to load friends',
    );
    if (result != null) _friends = result;
  }

  Future<void> fetchReceivedInvitations(String token) async {
    final result = await executeAsync(
      () => _friendService.getReceivedInvitations(token),
      errorMessage: 'Failed to load received invitations',
    );
    if (result != null) _receivedInvitations = result;
  }

  Future<void> fetchSentInvitations(String token) async {
    final result = await executeAsync(
      () => _friendService.getSentInvitations(token),
      errorMessage: 'Failed to load sent invitations',
    );
    if (result != null) _sentInvitations = result;
  }


  Future<bool> sendFriendRequest(String token, String userId) async {
    return await executeBool(
      () async {
        await _apiService.sendFriendRequest(userId, token);
        await fetchSentInvitations(token);
      },
      successMessage: 'Friend request sent!',
    );
  }

  Future<bool> acceptFriendRequest(String token, String friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.acceptFriendRequest(friendshipId, token);
        await Future.wait([fetchFriends(token), fetchReceivedInvitations(token), fetchSentInvitations(token)]);
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<bool> rejectFriendRequest(String token, String friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.rejectFriendRequest(friendshipId, token);
        await fetchReceivedInvitations(token);
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject request',
    );
  }

  Future<bool> removeFriend(String token, String friendId) async {
    return await executeBool(
      () async {
        await _friendService.removeFriend(friendId, token);
        _friends.removeWhere((friend) => friend.id == friendId);
      },
      successMessage: 'Friend removed',
      errorMessage: 'Failed to remove friend',
    );
  }

  void clearFriends() {
    _friends.clear();
    _receivedInvitations.clear();
    _sentInvitations.clear();
    notifyListeners();
  }

  String? getFriendshipId(Map<String, dynamic> invitation) {
    return invitation['friendship_id']?.toString() ?? invitation['id']?.toString();
  }

  String? getFromUserId(Map<String, dynamic> invitation) {
    return invitation['friend_id'] as String? ?? invitation['from_user'] as String?;
  }

  String? getToUserId(Map<String, dynamic> invitation) {
    return invitation['friend_id'] as String? ?? invitation['to_user'] as String?;
  }

  String? getInvitationStatus(Map<String, dynamic> invitation) {
    return invitation['status'] as String?;
  }

  String? getFromUsername(Map<String, dynamic> invitation) {
    return invitation['friend_username'] as String? ?? invitation['from_username'] as String?;
  }

  String? getToUsername(Map<String, dynamic> invitation) {
    return invitation['friend_username'] as String? ?? invitation['to_username'] as String?;
  }
}
