class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profilePicUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'consumer',
      profilePicUrl: data['profilePicUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'profilePicUrl': profilePicUrl,
    };
  }
}
