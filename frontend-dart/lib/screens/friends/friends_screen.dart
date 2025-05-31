// lib/screens/friends/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import 'components/friends_tab_view.dart';
import 'components/friend_requests_tab_view.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendsData();
  }

  Future<void> _loadFriendsData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      await Future.wait([
        friendProvider.fetchFriends(authProvider.token!),
        friendProvider.fetchPendingRequests(authProvider.token!),
      ]);
      
      setState(() {
        _friends = friendProvider.friends;
        _pendingRequests = friendProvider.pendingRequests;
      });
    } catch (e) {
      _showSnackBar('Unable to load friends data. Please check your connection.', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Friends'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
            icon: const Icon(Icons.person_add, color: AppTheme.primary),
            label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Friends (${_friends.length})'),
            Tab(text: 'Requests (${_pendingRequests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                FriendsTabView(
                  friends: _friends,
                  onRefresh: _loadFriendsData,
                  onSharePlaylist: _sharePlaylistWithFriend,
                  onRemoveFriend: _removeFriend,
                  onAddFriend: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                ),
                FriendRequestsTabView(
                  pendingRequests: _pendingRequests,
                  onRefresh: _loadFriendsData,
                  onAcceptRequest: _acceptRequest,
                  onRejectRequest: _rejectRequest,
                ),
              ],
            ),
    );
  }

  void _sharePlaylistWithFriend(int friendId) {
    _showSnackBar('Playlist sharing coming soon!');
  }

  void _acceptRequest(String friendshipId) async {
    _showSnackBar('Friend request accepted!');
    _loadFriendsData();
  }

  void _rejectRequest(String friendshipId) async {
    _showSnackBar('Friend request declined.');
    _loadFriendsData();
  }

  Future<void> _removeFriend(int friendId) async {
    _showSnackBar('Friend removed.');
    _loadFriendsData();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    showAppSnackBar(context, message, isError: isError);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
