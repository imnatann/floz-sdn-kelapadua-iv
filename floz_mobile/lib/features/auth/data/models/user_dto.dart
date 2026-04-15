import '../../domain/entities/user.dart';

class UserDto {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      student: json['student'] is Map
          ? _studentFromJson(json['student'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] is Map
          ? _teacherFromJson(json['teacher'] as Map<String, dynamic>)
          : null,
    );
  }

  static StudentProfile _studentFromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      nis: json['nis']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      schoolClass: json['class'] is Map
          ? ClassInfo(
              id: (json['class'] as Map)['id'] as int,
              name: (json['class'] as Map)['name'] as String,
              homeroomTeacher: (json['class'] as Map)['homeroom_teacher'] as String?,
            )
          : null,
    );
  }

  static TeacherProfile _teacherFromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'] as int,
      nip: json['nip'] as String?,
      name: json['name'] as String,
    );
  }
}
