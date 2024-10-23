import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  String? teacherId;
  final String teacherName;
  final String email;
  final String password;
  final String gender;
  final String profilePictureUrl;
  final List<String> courseIds;
  final List<String> studentIds;

  Teacher({
    this.teacherId,
    required this.teacherName,
    required this.email,
    required this.password,
    required this.gender,
    required this.profilePictureUrl,
    required this.courseIds,
    required this.studentIds,
  });

  // Method to create a Teacher instance from Firestore document snapshot
  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Teacher(
      teacherId: doc.id, // The document ID becomes the teacherId
      teacherName: data['teacherName'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      gender: data['gender'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      courseIds: List<String>.from(data['courseIds'] ?? []), // Ensure it's a list of strings
      studentIds: List<String>.from(data['studentIds'] ?? []),
    );
  }
}

