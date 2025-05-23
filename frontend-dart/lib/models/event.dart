// lib/models/event.dart
class Event {
  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final String creator;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  
  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.creator,
    required this.startTime,
    required this.endTime,
    this.location,
  });
  
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    isPublic: json['public'] ?? false,
    creator: json['creator'] ?? '',
    startTime: DateTime.parse(json['start_time']),
    endTime: DateTime.parse(json['end_time']),
    location: json['location'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'public': isPublic,
    'creator': creator,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'location': location,
  };
}
