// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_helper.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  List<int> _friends = [];
  bool _isLoading = false;

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading friends: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _removeFriend(int friendId) async {
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            onPressed: () => Navigator.pushNamed(context, '/add_friend').then((_) => _loadFriends()),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/friend_requests').then((_) => _loadFriends()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _friends.isEmpty
              ? const EmptyState(
                  icon: Icons.people,
                  title: 'No friends found',
                  subtitle: 'Add friends to start sharing music!',
                )
              : RefreshIndicator(
                  onRefresh: _loadFriends,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
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
