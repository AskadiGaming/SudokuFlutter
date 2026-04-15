import 'dart:convert';

class UserSession {
  const UserSession({
    required this.isAuthenticated,
    this.userId,
    this.displayName,
    this.photoUrl,
  });

  const UserSession.authenticated({
    required String this.userId,
    this.displayName,
    this.photoUrl,
  }) : isAuthenticated = true;

  const UserSession.unauthenticated()
    : isAuthenticated = false,
      userId = null,
      displayName = null,
      photoUrl = null;

  final bool isAuthenticated;
  final String? userId;
  final String? displayName;
  final String? photoUrl;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isAuthenticated': isAuthenticated,
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  String toJson() => jsonEncode(toMap());

  static UserSession fromJson(String rawJson) {
    final Map<String, dynamic> json =
        jsonDecode(rawJson) as Map<String, dynamic>;
    return UserSession(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
