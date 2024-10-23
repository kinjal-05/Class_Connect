
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/Lesson.dart';

class AddLessonPage extends StatefulWidget {
  final String courseId;

  AddLessonPage({required this.courseId});

  @override
  _AddLessonPageState createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final _formKey = GlobalKey<FormState>();
  final _lessonTitleController = TextEditingController();
  LessonType _selectedType = LessonType.pdf;
  DateTime _createdAt = DateTime.now();
  String _fileName = '';
  Uint8List? _fileBytes; // For web file bytes
  File? _file; // For mobile/desktop file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text('Add Lesson',
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
                  controller: _lessonTitleController,
                  decoration: InputDecoration(labelText: 'Lesson Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the lesson title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<LessonType>(
                  value: _selectedType,
                  onChanged: (LessonType? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                      _fileName = ''; // Clear the file name when type changes
                    });
                  },
                  items: LessonType.values.map((LessonType type) {
                    return DropdownMenuItem<LessonType>(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Lesson Type'),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: Text('Upload File'),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(_fileName.isEmpty ? 'No file selected' : _fileName),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Created At: ${DateFormat('yyyy-MM-dd').format(_createdAt)}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addLesson,
                  child: Text('Add Lesson'),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result;
      if (kIsWeb) {
        // Web platform
        result = await FilePicker.platform.pickFiles(
          type: _selectedType == LessonType.pdf ? FileType.custom : FileType.custom, // Use FileType.custom for web
          allowedExtensions: _selectedType == LessonType.pdf ? ['pdf'] : ['mp4', 'avi'],
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _fileBytes = result?.files.first.bytes;
            _fileName = result!.files.first.name;
          });
        }
      } else {
        // Mobile/desktop platform
        result = await FilePicker.platform.pickFiles(
          type: _selectedType == LessonType.pdf ? FileType.custom : FileType.custom, // Use FileType.custom here as well
          allowedExtensions: _selectedType == LessonType.pdf ? ['pdf'] : ['mp4', 'avi'],
        );

        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _file = File(result!.files.single.path!);
            _fileName = result!.files.single.name;
          });
        }
      }

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No file selected')));
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file')));
    }
  }


// Function to upload file to Firebase Storage
  Future<String?> _uploadFileToStorage() async {
    try {
      // Prepare the reference for Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('lessons/$_fileName'); // Access FirebaseStorage instance directly
      print('Storage reference created: $storageRef');

      // Upload based on platform (web vs mobile/desktop)
      if (kIsWeb) {
        if (_fileBytes != null) {
          await storageRef.putData(_fileBytes!); // For web file bytes
          print('File uploaded from web');
        } else {
          print('No file bytes available for upload on web');
        }
      } else {
        if (_file != null) {
          await storageRef.putFile(_file!); // For mobile/desktop file
          print('File uploaded from mobile/desktop');
        } else {
          print('No file available for upload on mobile/desktop');
        }
      }


      String downloadUrl = await storageRef.getDownloadURL();
      print('Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      return null;
    }
  }


  Future<void> _addLesson() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        print('Starting file upload');
        String? fileUrl = await _uploadFileToStorage();

        if (fileUrl == null) {
          print('File upload failed');
          return;
        }

        print('File uploaded successfully: $fileUrl');

        // Generate a new lesson ID
        String newLessonId = FirebaseFirestore.instance.collection('Lesson').doc().id;
        print('Generated new lesson ID: $newLessonId');

        // Create the lesson object
        Lesson lesson = Lesson(
          lessonId: newLessonId,
          lessonTitle: _lessonTitleController.text,
          content: fileUrl,
          type: _selectedType,
          createdAt: _createdAt,
          liveLectureIds: [],
          courseId: widget.courseId,
        );

        // Add the lesson to Firestore
        await FirebaseFirestore.instance.collection('Lesson').doc(newLessonId).set({
          'lessonTitle': lesson.lessonTitle,
          'content': lesson.content,
          'type': lesson.type.toString().split('.').last,
          'createdAt': lesson.createdAt,
          'liveLectureIds': lesson.liveLectureIds,
          'courseId': lesson.courseId,
        });
        print('Lesson added to Firestore');

        // Update course with the new lesson ID
        DocumentSnapshot courseSnapshot = await FirebaseFirestore.instance.collection('Course').doc(widget.courseId).get();
        if (courseSnapshot.exists) {
          await FirebaseFirestore.instance.collection('Course').doc(widget.courseId).update({
            'lessonIds': FieldValue.arrayUnion([newLessonId]),
          });
          print('Course updated with new lesson ID');
        } else {
          print('Course not found');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course not found')));
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lesson added successfully')));
        Navigator.pop(context);
      } catch (e) {
        print('Error adding lesson: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding lesson: $e')));
      }
    }
  }

}
