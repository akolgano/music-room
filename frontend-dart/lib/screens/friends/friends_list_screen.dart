// lib/screens/friends/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../config/theme.dart';
import '../../widgets/api_error_widget.dart';
import 'add_friend_screen.dart';
import 'friend_request_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  bool _isLoading = true;
  List<int> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      
      await friendProvider.fetchFriends(authProvider.token!);
      setState(() {
        _friends = friendProvider.friends;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load friends: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Friends',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const AddFriendScreen(),
                ),
              ).then((_) => _loadFriends());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const FriendRequestScreen(),
                ),
              ).then((_) => _loadFriends());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendProvider.hasConnectionError
              ? ApiErrorWidget(
                  message: friendProvider.errorMessage ?? 'Failed to load friends',
                  onRetry: _loadFriends,
                  isRetrying: friendProvider.isRetrying,
                )
              : _friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No friends found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const AddFriendScreen(),
                                ),
                              ).then((_) => _loadFriends());
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Friends'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.primaries[friendId % Colors.primaries.length].withOpacity(0.8),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          'Friend #$friendId',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'User ID: $friendId',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove, color: Colors.white),
          onPressed: () => _removeFriend(friendId),
        ),
      ),
    );
  }

  void _removeFriend(int friendId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Remove Friend',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove this friend? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final friendProvider = Provider.of<FriendProvider>(context, listen: false);
                
                final message = await friendProvider.removeFriend(
                  authProvider.token!,
                  friendId,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                  ),
                );
                
                _loadFriends();
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove friend: ${error.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }
}