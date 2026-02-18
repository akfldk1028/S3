// Auth domain models — plain Dart classes (no freezed required).
//
// These are kept intentionally simple since the codebase uses
// anonymous auth (/auth/anon) and the generated freezed mixins are
// incompatible with Dart 3.10 strict non_abstract_class_inherits_abstract_member.

class User {
  final String id;
  final String email;
  final String? name;
  final String? profileImage;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        profileImage: json['profileImage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (name != null) 'name': name,
        if (profileImage != null) 'profileImage': profileImage,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          profileImage == other.profileImage;

  @override
  int get hashCode => Object.hash(id, email, name, profileImage);

  @override
  String toString() =>
      'User(id: $id, email: $email, name: $name, profileImage: $profileImage)';
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
        email: json['email'] as String,
        password: json['password'] as String,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
}
