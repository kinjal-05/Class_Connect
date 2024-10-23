import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'CourseDetails.dart';

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  late String _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _editingCourseId;
  final _formKey = GlobalKey<FormState>();
  final _courseTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      final courseDoc = _firestore.collection('Course').doc(courseId);
      final courseData = await courseDoc.get();
      final instructorId = courseData['instructorId'];

      // Delete the course from the 'Course' collection
      await courseDoc.delete();

      // Remove courseId from the instructor's course list
      final instructorDoc = _firestore.collection('Teacher').doc(instructorId);
      final instructorData = await instructorDoc.get();
      List<String> courseIds = List<String>.from(instructorData['courseIds']);
      courseIds.remove(courseId);

      await instructorDoc.update({
        'courseIds': courseIds,
      });

      // Remove courseId from all students' enrolledCourseIds
      final studentQuery = await _firestore
          .collection('Student')
          .where('enrolledCourseIds', arrayContains: courseId)
          .get();

      for (var studentDoc in studentQuery.docs) {
        List<String> enrolledCourseIds = List<String>.from(studentDoc['enrolledCourseIds']);
        enrolledCourseIds.remove(courseId);

        await studentDoc.reference.update({
          'enrolledCourseIds': enrolledCourseIds,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course deleted successfully')),
      );
    } catch (e) {
      print('Error deleting course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting course')),
      );
    }
  }


  Future<void> _updateCourse(String courseId) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _firestore.collection('Course').doc(courseId).update({
          'courseTitle': _courseTitleController.text,
          'cDescription': _descriptionController.text,
          'duration': int.parse(_durationController.text),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course updated successfully')),
        );

        setState(() {
          _editingCourseId = null;
        });
      } catch (e) {
        print('Error updating course: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating course')),
        );
      }
    }
  }

  void _editCourse(String courseId, String courseTitle, String description, int duration) {
    setState(() {
      _editingCourseId = courseId;
      _courseTitleController.text = courseTitle;
      _descriptionController.text = description;
      _durationController.text = duration.toString();
    });
  }

  void _addLesson(String courseId) {
    Navigator.pushNamed(
      context,
      '/addLesson',
      arguments: courseId,
    );
  }

  void _navigateToCourseDetails(String courseId, String role) {
    Navigator.pushNamed(
      context,
      '/courseDetails',
        arguments:
        {
          "courseId": courseId,
          "role": role,
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text(
          'My Courses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            color: Colors.white, // Background color
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('Course')
                        .where('instructorId', isEqualTo: _userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No courses found'));
                      }

                      final courses = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final courseData = courses[index].data() as Map<String, dynamic>;
                          final courseId = courses[index].id; // Get the document ID
                          final courseTitle = courseData['courseTitle'] ?? 'No Title';
                          final description = courseData['cDescription'] ?? 'No Description';
                          final createdAt = (courseData['createdAt'] as Timestamp).toDate();
                          final duration = courseData['duration'] ?? 0;
                          final lessonIds = List<String>.from(courseData['lessonIds'] ?? []);
                          final lessonCount = lessonIds.length;

                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            elevation: 9,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.0),
                              title: Text(
                                courseTitle,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$description',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 20,
                                        color: Colors.indigo,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '$duration hours',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Lessons: $lessonCount',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'Created on: ${DateFormat('yyyy-MM-dd').format(createdAt)}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () => _navigateToCourseDetails(courseId, "teacher"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.add, color: Colors.indigo),
                                    onPressed: () => _addLesson(courseId),
                                  ),

                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editCourse(
                                          courseId,
                                          courseTitle,
                                          description,
                                          duration,
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmationDialog(courseId);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Container(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text('Edit'),
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Container(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text('Delete'),
                                            ),
                                          ),
                                        ),
                                      ];
                                    },
                                    icon: Icon(Icons.more_vert, color: Colors.indigo),
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_editingCourseId != null)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: _buildEditForm(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Edit Course',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigoAccent[200]),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _courseTitleController,
              decoration: InputDecoration(
                labelText: 'Course Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the course title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration (hours)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the duration';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Please enter a valid duration';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_editingCourseId != null) {
                  _updateCourse(_editingCourseId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent[200], // Background color of the button
              ),
              child: Text(
                'Update Course',
                style: TextStyle(
                  color: Colors.white, // Text color
                ),
              ),
            ),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _editingCourseId = null; // Hide the form
                });
              },
              child: Text(
                  'Cancel',
                style: TextStyle(
                color: Colors.white, // Text color
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Course'),
          content: Text('Are you sure you want to delete this course?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCourse(courseId);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
