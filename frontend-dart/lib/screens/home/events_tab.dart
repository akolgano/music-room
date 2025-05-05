// screens/home/events_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/event_item.dart';
import '../music/music_features_screen.dart';
import '../music/track_vote_screen.dart';
import '../music/control_delegation_screen.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<MusicProvider>(context).events;
    
    return Column(
      children: [
        _buildQuickActionsBar(context),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyEventsView(context)
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (ctx, i) => EventItem(event: events[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showCreateEventDialog(context);
              },
              icon: Icon(Icons.add),
              label: Text('New Event'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const MusicFeaturesScreen(),
                  ),
                );
              },
              icon: Icon(Icons.featured_play_list),
              label: Text('Features'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text('No events found'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showCreateEventDialog(context);
            },
            child: Text('Create Your First Event'),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const MusicTrackVoteScreen(),
                ),
              );
            },
            child: Text('Try Track Voting'),
          ),
        ],
      ),
    );
  }
  
  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Event'),
        content: const Text('Event creation would be implemented here'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MusicTrackVoteScreen(),
                ),
              );
            },
            child: const Text('Create Demo Event'),
          ),
        ],
      ),
    );
  }
}
