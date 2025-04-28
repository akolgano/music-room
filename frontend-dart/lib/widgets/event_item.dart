// widgets/event_item.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../screens/music/track_vote_screen.dart';

class EventItem extends StatelessWidget {
  final Event event;
  
  const EventItem({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        title: Text(event.name),
        subtitle: Text(event.isPublic ? 'Public' : 'Private'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => MusicTrackVoteScreen(eventId: event.id),
            ),
          );
        },
      ),
    );
  }
}
