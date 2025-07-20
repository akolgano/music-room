class Friendship {
  final String id;
  final int fromUser;
  final int toUser;
  final String status;
  final DateTime createdAt;

  const Friendship({required this.id, required this.fromUser, required this.toUser, required this.status, required this.createdAt});

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'].toString(),
    fromUser: json['from_user'] as int,
    toUser: json['to_user'] as int,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {'id': id, 'from_user': fromUser, 'to_user': toUser, 'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}