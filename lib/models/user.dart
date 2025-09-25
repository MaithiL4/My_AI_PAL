class User {
  String id;
  String userName;
  String email;
  String aiPalName;
  bool hasSeenWelcome;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.aiPalName,
    this.hasSeenWelcome = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      aiPalName: json['aiPalName'],
      hasSeenWelcome: json['hasSeenWelcome'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'aiPalName': aiPalName,
      'hasSeenWelcome': hasSeenWelcome,
    };
  }
}