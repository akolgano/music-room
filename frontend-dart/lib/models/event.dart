// models/event.dart
class Event {
  final String id;
  final String name;
  final bool isPublic;
  
  Event({
    required this.id,
    required this.name,
    required this.isPublic,
  });
  
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      isPublic: json['isPublic'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPublic': isPublic,
    };
  }
}
