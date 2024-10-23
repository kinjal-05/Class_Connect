
class Student {
  String? studentId;
  final String studentName;
  final String email;
  final String password;
  final String gender;
  final String profilePictureUrl;
  final List<String> enrolledCourseIds; // Store course IDs instead of Course objects

  Student({
    this.studentId,
    required this.studentName,
    required this.email,
    required this.password,
    required this.gender,
    required this.profilePictureUrl,
    required this.enrolledCourseIds,
  });
}