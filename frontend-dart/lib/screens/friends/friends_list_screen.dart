// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/core.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/app_widgets.dart';  
import '../base_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends BaseScreen<FriendsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  String get screenTitle => 'Friends';

  @override
  List<Widget> get actions => [
    TextButton.icon(
      onPressed: () => navigateTo(AppRoutes.addFriend),
      icon: const Icon(Icons.person_add, color: AppTheme.primary),
      label: const Text('Add Friend', style: TextStyle(color: AppTheme.primary)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriendsData());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<FriendProvider>(
      builder: (context, friendProvider) {
        return buildTabContent(
          tabs: [
            Tab(text: 'Friends (${friendProvider.friends.length})'),
            const Tab(text: 'Requests'),
          ],
          tabViews: [
            _buildFriendsTab(friendProvider),
            _buildRequestsTab(),
          ],
          controller: _tabController,
        );
      },
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    return buildListContent<int>(
      items: friendProvider.friends,
      itemBuilder: (friendId, index) => _buildFriendCard(friendId),
      onRefresh: _loadFriendsData,
      emptyState: buildEmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        subtitle: 'Add friends to start sharing music together!',
        buttonText: 'Add Friend',
        onButtonPressed: () => navigateTo(AppRoutes.addFriend),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return buildEmptyState(
      icon: Icons.info_outline,
      title: 'Requests Not Available',
      subtitle: 'The API doesn\'t currently support retrieving pending friend requests. Friend requests must be managed externally.',
    );
  }

  Widget _buildFriendCard(int friendId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          'User ID: $friendId', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        subtitle: Text(
          'Friend since you connected', 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFriendAction(value, friendId),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share', 
              child: Row(children: [Icon(Icons.playlist_play, size: 16), SizedBox(width: 8), Text('Share Playlist')])
            ),
            const PopupMenuItem(
              value: 'remove', 
              child: Row(children: [
                Icon(Icons.person_remove, size: 16, color: Colors.red), 
                SizedBox(width: 8), 
                Text('Remove Friend', style: TextStyle(color: Colors.red))
              ])
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFriendsData() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchFriends(auth.token!);
      },
      errorMessage: 'Unable to load friends data',
    );
  }

  void _handleFriendAction(String action, int friendId) {
    switch (action) {
      case 'share': 
        showInfo('Playlist sharing coming soon!'); 
        break;
      case 'remove': 
        _showRemoveDialog(friendId); 
        break;
    }
  }

  void _showRemoveDialog(int friendId) async {
    final confirmed = await showConfirmDialog(
      'Remove Friend', 
      'Are you sure you want to remove User ID $friendId from your friends?', 
      isDangerous: true
    );
    if (confirmed) await _removeFriend(friendId);
  }

  Future<void> _removeFriend(int friendId) async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.removeFriend(auth.token!, friendId);
        await _loadFriendsData();
      },
      successMessage: 'Friend removed',
      errorMessage: 'Failed to remove friend',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
