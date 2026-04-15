class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'student' | 'teacher' | 'school_admin'
  final String? avatarUrl;
  final bool isActive;
  final StudentProfile? student;
  final TeacherProfile? teacher;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.student,
    this.teacher,
  });

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isSchoolAdmin => role == 'school_admin';
}

class StudentProfile {
  final int id;
  final String nis;
  final String nisn;
  final ClassInfo? schoolClass;

  const StudentProfile({
    required this.id,
    required this.nis,
    required this.nisn,
    this.schoolClass,
  });
}

class ClassInfo {
  final int id;
  final String name;
  final String? homeroomTeacher;

  const ClassInfo({required this.id, required this.name, this.homeroomTeacher});
}

class TeacherProfile {
  final int id;
  final String? nip;
  final String name;

  const TeacherProfile({required this.id, this.nip, required this.name});
}
