// lib/screens/friends/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../core/theme.dart';
import '../../widgets/common/base_widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _isLoading = true;
  List<int> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);

      await friendProvider.fetchFriends(authProvider.token!);
      setState(() => _friends = friendProvider.friends);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load friends: $error'),
          backgroundColor: Colors.red,
        ),
      );
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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.pushNamed(context, '/add_friend'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/friend_requests'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _friends.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people,
                  title: 'No friends found',
                  subtitle: 'Add friends to start sharing music!',
                )
              : RefreshIndicator(
                  onRefresh: _loadFriends,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (ctx, i) => _buildFriendItem(_friends[i]),
                  ),
                ),
    );
  }

  Widget _buildFriendItem(int friendId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[friendId % Colors.primaries.length],
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          'Friend #$friendId',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'User ID: $friendId',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showFriendOptions(friendId),
        ),
      ),
    );
  }

  void _showFriendOptions(int friendId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.message, color: Colors.white),
            title: const Text('Send Message', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messaging feature coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Share Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist sharing feature coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('Remove Friend', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _removeFriend(friendId);
            },
          ),
        ],
      ),
    );
  }

  void _removeFriend(int friendId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this friend?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final friendProvider = Provider.of<FriendProvider>(context, listen: false);
        
        await friendProvider.removeFriend(authProvider.token!, friendId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFriends();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
