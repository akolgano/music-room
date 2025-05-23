// lib/models/user.dart
class User {
  final String id;
  final String username;
  final String? email;
  
  User({required this.id, required this.username, this.email});
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    username: json['username'],
    email: json['email'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (email != null) 'email': email,
  };
}
