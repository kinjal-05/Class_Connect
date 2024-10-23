import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/Lesson.dart';

class EditLesson extends StatefulWidget {
  final Lesson lesson;

  EditLesson({required this.lesson});

  @override
  _EditLessonState createState() => _EditLessonState();
}

class _EditLessonState extends State<EditLesson> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _fileName;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson.lessonTitle);
    _fileName = _getFileNameFromUrl(widget.lesson.content);
    _contentController = TextEditingController(text: _fileName);
  }

  String? _getFileNameFromUrl(String url) {
    return Uri.parse(url).pathSegments.isNotEmpty ? Uri.parse(url).pathSegments.last : null;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
          _fileName = _selectedFile!.name;
          _contentController.text = _fileName!;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file')),
      );
    }
  }

  Future<String> _uploadFile() async {
    if (_selectedFile != null) {
      try {
        final file = _selectedFile!;
        final storageRef = FirebaseStorage.instance.ref().child('lessons/${file.name}');
        final uploadTask = storageRef.putData(file.bytes!);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file')),
        );
      }
    }
    return widget.lesson.content;
  }

  Future<void> _updateLesson() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final newFileUrl = await _uploadFile();

        await FirebaseFirestore.instance
            .collection('Lesson')
            .doc(widget.lesson.lessonId)
            .update({
          'lessonTitle': _titleController.text,
          'content': newFileUrl,
        });

        Navigator.pop(context, true);
      } catch (e) {
        print('Error updating lesson: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lesson')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text('Edit Lesson',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
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
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Lesson Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the lesson title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: 'File Name'),
                  readOnly: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text('Choose File'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateLesson,
                  child: Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
