// screens/home/events_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/event_item.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = Provider.of<MusicProvider>(context).events;
    
    return events.isEmpty
        ? const Center(child: Text('No events found'))
        : ListView.builder(
            itemCount: events.length,
            itemBuilder: (ctx, i) => EventItem(event: events[i]),
          );
  }
}
