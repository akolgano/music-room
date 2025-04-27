class User {
  final String id;
  final String username;
  final String email;
  String? photoUrl;
  Map<String, dynamic> publicInfo;
  Map<String, dynamic> friendsOnlyInfo;
  Map<String, dynamic> privateInfo;
  List<String> musicPreferences;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    this.publicInfo = const {},
    this.friendsOnlyInfo = const {},
    this.privateInfo = const {},
    this.musicPreferences = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      photoUrl: json['photo_url'],
      publicInfo: json['public_info'] ?? {},
      friendsOnlyInfo: json['friends_only_info'] ?? {},
      privateInfo: json['private_info'] ?? {},
      musicPreferences: List<String>.from(json['music_preferences'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'photo_url': photoUrl,
      'public_info': publicInfo,
      'friends_only_info': friendsOnlyInfo,
      'private_info': privateInfo,
      'music_preferences': musicPreferences,
    };
  }
}