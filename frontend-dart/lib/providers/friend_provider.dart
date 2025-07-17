import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/friend_service.dart';

class FriendProvider extends BaseProvider {
  final FriendService _friendService = getIt<FriendService>();
  
  List<int> _friends = [];
  List<Map<String, dynamic>> _receivedInvitations = [];
  List<Map<String, dynamic>> _sentInvitations = [];

  List<int> get friends => List.unmodifiable(_friends);
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

  Future<void> fetchAllFriendData(String token) async {
    await executeAsync(
      () async {
        await Future.wait([fetchFriends(token), fetchReceivedInvitations(token), fetchSentInvitations(token)]);
      },
      errorMessage: 'Failed to load friend data',
    );
  }

  Future<bool> sendFriendRequest(String token, int userId) async {
    return await executeBool(
      () async {
        await _friendService.sendFriendRequest(userId, token);
        await fetchSentInvitations(token);
      },
      successMessage: 'Friend request sent!',
      errorMessage: 'Failed to send friend request',
    );
  }

  Future<bool> acceptFriendRequest(String token, int friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.acceptFriendRequest(friendshipId, token);
        await fetchAllFriendData(token);
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<bool> rejectFriendRequest(String token, int friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.rejectFriendRequest(friendshipId, token);
        await fetchReceivedInvitations(token);
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject request',
    );
  }

  Future<bool> removeFriend(String token, int friendId) async {
    return await executeBool(
      () async {
        await _friendService.removeFriend(friendId, token);
        _friends.remove(friendId);
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

  int? getFriendshipId(Map<String, dynamic> invitation) {
    return invitation['id'] as int?;
  }

  int? getFromUserId(Map<String, dynamic> invitation) {
    return invitation['from_user'] as int?;
  }

  int? getToUserId(Map<String, dynamic> invitation) {
    return invitation['to_user'] as int?;
  }

  String? getInvitationStatus(Map<String, dynamic> invitation) {
    return invitation['status'] as String?;
  }

  String? getFromUsername(Map<String, dynamic> invitation) {
    return invitation['from_username'] as String?;
  }

  String? getToUsername(Map<String, dynamic> invitation) {
    return invitation['to_username'] as String?;
  }
}
