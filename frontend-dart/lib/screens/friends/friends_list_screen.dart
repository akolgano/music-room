// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/common/base_widgets.dart';
import '../base_screen.dart';
import '../../utils/dialog_helper.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends BaseScreen<FriendsListScreen> {
  List<int> _friends = [];

  @override
  String get screenTitle => 'Friends';

  @override
  PreferredSizeWidget? buildAppBar() => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(screenTitle),
    actions: [
      IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: () => Navigator.pushNamed(context, '/add_friend').then((_) => _loadFriends()),
      ),
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => Navigator.pushNamed(context, '/friend_requests').then((_) => _loadFriends()),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    await runAsync(() async {
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      await friendProvider.fetchFriends(auth.token!);
      setState(() => _friends = friendProvider.friends);
    });
  }

  Future<void> _removeFriend(int friendId) async {
    final confirm = await DialogHelper.showConfirm(
      context,
      title: 'Remove Friend',
      message: 'Are you sure you want to remove this friend?',
      confirmText: 'Remove',
      isDangerous: true,
    );
    
    if (confirm == true) {
      await runAsync(() async {
        final friendProvider = Provider.of<FriendProvider>(context, listen: false);
        await friendProvider.removeFriend(auth.token!, friendId);
        showSuccess('Friend removed');
        _loadFriends();
      });
    }
  }

  @override
  Widget buildBody() {
    return _friends.isEmpty
        ? EmptyStateWidget(
            icon: Icons.people,
            title: 'No friends found',
            buttonText: 'Add Friends',
            onButtonPressed: () => Navigator.pushNamed(context, '/add_friend').then((_) => _loadFriends()),
          )
        : RefreshIndicator(
            onRefresh: _loadFriends,
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _friends.length,
              itemBuilder: (ctx, i) => _buildFriendItem(_friends[i]),
            ),
          );
  }

  Widget _buildFriendItem(int friendId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[friendId % Colors.primaries.length].withOpacity(0.8),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text('Friend #$friendId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text('User ID: $friendId', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove, color: Colors.white),
          onPressed: () => _removeFriend(friendId),
        ),
      ),
    );
  }
}
