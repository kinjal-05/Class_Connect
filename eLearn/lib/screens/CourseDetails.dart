import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/Course.dart';
import '../models/Lesson.dart';
import '../models/Teacher.dart';
import 'EditLesson.dart';
import 'FullScreenFileView.dart';
import 'VideoPlayerScreen.dart';

class CourseDetails extends StatefulWidget {
  final String? courseId;
  final String? role; // Added role

  CourseDetails({this.courseId, this.role});

  @override
  _CourseDetailsState createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<CourseDetails> {
  Course? course;
  String? role;
  Teacher? teacher;
  List<Lesson> lessons = [];

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _fetchCourseDetails(widget.courseId!);
    }
    role = widget.role;
  }

  Future<void> _fetchCourseDetails(String courseId) async {
    try {
      // Fetch course details
      DocumentSnapshot courseDoc = await FirebaseFirestore.instance
          .collection('Course')
          .doc(courseId)
          .get();

      if (courseDoc.exists) {
        setState(() {
          course = Course.fromFirestore(courseDoc);
        });

        // Fetch the teacher details if role is student
        if (role == 'student' && course != null) {
          _fetchTeacherDetails(course!.instructorId);
        }
      }

      // Fetch lessons
      _fetchLessons(courseId);
    } catch (e) {
      print('Error fetching course or lessons: $e');
    }
  }

  Future<void> _fetchTeacherDetails(String teacherId) async {
    try {
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Teacher')
          .doc(teacherId)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          teacher = Teacher.fromFirestore(teacherDoc);
        });
      }
    } catch (e) {
      print('Error fetching teacher details: $e');
    }
  }

  Future<void> _fetchLessons(String courseId) async {
    try {
      QuerySnapshot lessonSnapshot = await FirebaseFirestore.instance
          .collection('Lesson')
          .where('courseId', isEqualTo: courseId)
          .get();

      setState(() {
        lessons = lessonSnapshot.docs.map((doc) => Lesson.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error fetching lessons: $e');
    }
  }

  Future<void> _deleteLesson(String lessonId) async {
    try {
      await FirebaseFirestore.instance.collection('Lesson').doc(lessonId).delete();

      if (course != null && course!.lessonIds != null) {
        List<String> updatedLessonIds = List.from(course!.lessonIds!);
        updatedLessonIds.remove(lessonId);

        await FirebaseFirestore.instance
            .collection('Course')
            .doc(course!.courseId)
            .update({'lessonIds': updatedLessonIds});

        setState(() {
          lessons.removeWhere((lesson) => lesson.lessonId == lessonId);
          course = Course(
            courseId: course!.courseId,
            courseTitle: course!.courseTitle,
            cDescription: course!.cDescription,
            duration: course!.duration,
            lessonIds: updatedLessonIds,
            instructorId: course!.instructorId,
            createdAt: course!.createdAt,
          );
        });
      }
    } catch (e) {
      print('Error deleting lesson: $e');
    }
  }

  void _editLesson(Lesson lesson) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLesson(lesson: lesson),
      ),
    );

    if (result == true) {
      if (course != null) {
        _fetchLessons(course!.courseId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStudent = widget.role == 'student';

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text(
          'Course Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course != null) ...[
                Text(
                  'Course Title: ${course!.courseTitle}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Description: ${course!.cDescription}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Duration: ${course!.duration} hours',
                  style: TextStyle(fontSize: 16),
                ),
                if (isStudent && teacher != null) ...[
                  SizedBox(height: 10),
                  Text(
                    'Instructor: ${teacher!.teacherName}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Instructor\'s email: ${teacher!.email}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ],
              SizedBox(height: 20),
              Text(
                'Lessons:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          lesson.type == LessonType.pdf
                              ? Icons.picture_as_pdf
                              : lesson.type == LessonType.video
                              ? Icons.video_library
                              : Icons.insert_drive_file,
                          color: Colors.blue[700],
                        ),
                        title: Text(
                          lesson.lessonTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'File: ${Uri.parse(lesson.content).pathSegments.last}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isStudent
                            ? null
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editLesson(lesson);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteLesson(lesson.lessonId!);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _showFile(lesson.content, lesson.type);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isStudent
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        onPressed: () {
          _navigateToAddLesson();
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        tooltip: 'Add Lesson',
      ),
    );
  }

  void _showFile(String fileUrl, LessonType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenFileView(fileUrl: fileUrl, type: type),
      ),
    );
  }

  void _navigateToAddLesson() {
    if (course != null) {
      Navigator.pushNamed(context, '/addLesson', arguments: course!.courseId).then((_) {
        if (course != null) {
          _fetchLessons(course!.courseId!);
        }
      });
    }
  }
}
