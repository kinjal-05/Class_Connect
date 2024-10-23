import 'dart:core';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/Course.dart';

class AddCourse extends StatefulWidget {
  final String userId;

  AddCourse({required this.userId});

  @override
  _AddCourseState createState() => _AddCourseState();
}

class _AddCourseState extends State<AddCourse> {
  final _formKey = GlobalKey<FormState>();
  final _courseTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _createdAt = DateTime.now();
  List<String> _lessonIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text('Add Course',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _courseTitleController,
                  decoration: InputDecoration(labelText: 'Course Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the course title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _durationController,
                  decoration: InputDecoration(labelText: 'Duration (hours)'),
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
                Text('Created At: ${DateFormat('yyyy-MM-dd').format(_createdAt)}'),
                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _addCourse,
                  child: Text('Add Course'),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Create the course
        final courseId = FirebaseFirestore.instance.collection('Course').doc().id;
        final course = Course(
          courseId: courseId,
          courseTitle: _courseTitleController.text,
          cDescription: _descriptionController.text,
          instructorId: widget.userId,
          createdAt: _createdAt,
          duration: int.parse(_durationController.text),
          lessonIds: _lessonIds,
        );

        await FirebaseFirestore.instance.collection('Course').doc(courseId).set({
          'courseTitle': course.courseTitle,
          'cDescription': course.cDescription,
          'instructorId': course.instructorId,
          'createdAt': course.createdAt,
          'duration': course.duration,
          'lessonIds': course.lessonIds,
        });

        // Update the teacher's courseIds list
        final teacherDocRef = FirebaseFirestore.instance.collection('Teacher').doc(widget.userId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final teacherDoc = await transaction.get(teacherDocRef);
          if (teacherDoc.exists) {
            final teacherData = teacherDoc.data()!;
            final List<String> courseIds = List<String>.from(teacherData['courseIds'] ?? []);
            courseIds.add(courseId);
            transaction.update(teacherDocRef, {'courseIds': courseIds});
          } else {
            throw Exception('Teacher document does not exist');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course added successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error adding course: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding course')),
        );
      }
    }
  }
}
