// lib/models/friendship.dart
class Friendship {
  final String id;
  final String fromUser;
  final String toUser;
  final String status;
  final DateTime? createdAt;
  
  Friendship({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    this.createdAt,
  });
  
  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'].toString(),
      fromUser: json['from_user'].toString(),
      toUser: json['to_user'].toString(),
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user': fromUser,
      'to_user': toUser,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}