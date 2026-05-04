class User {
  final String name;
  final String npm;
  final String email;

  User({required this.name, required this.npm, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      npm: json['npm'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'npm': npm,
      'email': email,
    };
  }
}
