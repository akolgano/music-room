// lib/models/event.dart
class Event {
  final String id;
  final String name;
  final bool isPublic;
  
  Event({required this.id, required this.name, required this.isPublic});
  
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    isPublic: json['isPublic'] ?? false,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isPublic': isPublic,
  };
}
