class User {
  String id;
  String userName;
  String email;
  String aiPalName;
  bool hasSeenWelcome;
  List<String> personalityTraits;
  String? avatarUrl;
  String? aiAvatarUrl;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.aiPalName,
    this.hasSeenWelcome = false,
    this.personalityTraits = const [],
    this.avatarUrl,
    this.aiAvatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      aiPalName: json['aiPalName'],
      hasSeenWelcome: json['hasSeenWelcome'] ?? false,
      personalityTraits: List<String>.from(json['personalityTraits'] ?? []),
      avatarUrl: json['avatarUrl'],
      aiAvatarUrl: json['aiAvatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'aiPalName': aiPalName,
      'hasSeenWelcome': hasSeenWelcome,
      'personalityTraits': personalityTraits,
      'avatarUrl': avatarUrl,
      'aiAvatarUrl': aiAvatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? userName,
    String? email,
    String? aiPalName,
    bool? hasSeenWelcome,
    List<String>? personalityTraits,
    String? avatarUrl,
    String? aiAvatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      aiPalName: aiPalName ?? this.aiPalName,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aiAvatarUrl: aiAvatarUrl ?? this.aiAvatarUrl,
    );
  }
}