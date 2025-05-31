// lib/screens/friends/components/friends_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../widgets/unified_widgets.dart';

class FriendsTabView extends StatelessWidget {
  final List<int> friends;
  final Future<void> Function() onRefresh;
  final Function(int) onSharePlaylist;
  final Function(int) onRemoveFriend;
  final VoidCallback onAddFriend;

  const FriendsTabView({
    Key? key,
    required this.friends,
    required this.onRefresh,
    required this.onSharePlaylist,
    required this.onRemoveFriend,
    required this.onAddFriend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return EmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        subtitle: 'Add friends to start sharing music together!',
        buttonText: 'Add Friend',
        onButtonPressed: onAddFriend,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friendId = friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
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
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      onSharePlaylist(friendId);
                      break;
                    case 'remove':
                      _showRemoveDialog(context, friendId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_play, size: 16),
                        SizedBox(width: 8),
                        Text('Share Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Friend', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, int friendId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove Friend #$friendId?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveFriend(friendId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
