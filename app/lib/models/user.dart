class User {
  final String id;
  final String name;
  final String? email;
  final String role;
  final bool active;

  const User({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    required this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        role: json['role'] as String,
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'active': active,
      };
}
