class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final Map<String, dynamic>? studentData;
  final Map<String, dynamic>? teacherData;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.studentData,
    this.teacherData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      studentData: json['student'],
      teacherData: json['teacher'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'student': studentData,
      'teacher': teacherData,
    };
  }

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';
}
