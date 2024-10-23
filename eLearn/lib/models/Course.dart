import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  String? courseId;
  final String courseTitle;
  final String cDescription;
  final String instructorId; // ID of the teacher
  final DateTime createdAt;
  final int duration;
  final List<String> lessonIds; // Store lesson IDs instead of Lesson objects

  Course({
    this.courseId,
    required this.courseTitle,
    required this.cDescription,
    required this.instructorId,
    required this.createdAt,
    required this.duration,
    required this.lessonIds,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      courseId: doc.id,
      courseTitle: data['courseTitle'] ?? '', // Ensure the field name matches
      cDescription: data['cDescription'] ?? '', // Ensure the field name matches
      duration: data['duration']?.toInt() ?? 0, // Ensure it's converted to int if needed
      instructorId: data['instructorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(), // Convert Timestamp to DateTime
      lessonIds: List<String>.from(data['lessonIds'] ?? []), // Convert to List<String>
    );
  }
}
