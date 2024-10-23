import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  String? lessonId;
  final String lessonTitle;
  final String content; // URL to content
  final LessonType type; // Type of content (PDF, Video, etc.)
  final DateTime createdAt;
  final List<String> liveLectureIds; // Store live lecture IDs
  final String courseId;

  Lesson({
    this.lessonId,
    required this.lessonTitle,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.liveLectureIds,
    required this.courseId,
  });

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Lesson(
      lessonId: doc.id,
      lessonTitle: data['lessonTitle'] ?? '',
      content: data['content'] ?? '',
      type: LessonType.values.firstWhere(
            (e) => e.toString() == 'LessonType.${data['type']}',
        orElse: () => LessonType.pdf,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      liveLectureIds: List<String>.from(data['liveLectureIds'] ?? []),
      courseId: data['courseId'] ?? '',
    );
  }
}

enum LessonType {
  pdf, // For PDFs
  video, // For recorded lectures
}
