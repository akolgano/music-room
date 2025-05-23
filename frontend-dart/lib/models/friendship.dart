// lib/models/friendship.dart
class Friendship {
  final String id;
  final int fromUser;
  final int toUser;
  final String status;
  final DateTime createdAt;
  
  Friendship({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
  });
  
  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'].toString(),
    fromUser: json['from_user'],
    toUser: json['to_user'],
    status: json['status'] ?? 'pending',
    createdAt: DateTime.parse(json['created_at']),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'from_user': fromUser,
    'to_user': toUser,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}
