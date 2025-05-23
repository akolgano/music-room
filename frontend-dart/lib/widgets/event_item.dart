// lib/widgets/event_item.dart
import 'package:flutter/material.dart';
import '../models/event.dart';

class EventItem extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventItem({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: event.isPublic ? Colors.green : Colors.blue,
          child: Icon(
            event.isPublic ? Icons.public : Icons.lock,
            color: Colors.white,
          ),
        ),
        title: Text(event.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 4),
            Text(
              'By ${event.creator}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${_formatDate(event.startTime)} - ${_formatDate(event.endTime)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
