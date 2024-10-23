import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // Mobile
import 'package:file_picker/file_picker.dart'; // Web
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfile extends StatefulWidget {
  final String userId;
  final String role;

  EditProfile({required this.userId, required this.role});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers for form fields
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  String? selectedGender;
  String? profilePictureUrl;
  List<String>? courseIds;
  List<String>? studentIds;
  List<String>? enrolledCourseIds;

  File? _imageFile; // For mobile
  Uint8List? _webImage; // For web

  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection(widget.role.toLowerCase() == 'teacher' ? 'Teacher' : 'Student')
          .doc(widget.userId)
          .get();

      if (profileDoc.exists) {
        var data = profileDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data[widget.role.toLowerCase() == 'teacher' ? 'teacherName' : 'studentName'];
          emailController.text = data['email'];
          selectedGender = data['gender'];
          profilePictureUrl = data['profilePictureUrl'];
          if (widget.role.toLowerCase() == 'teacher') {
            courseIds = List<String>.from(data['courseIds'] ?? []);
            studentIds = List<String>.from(data['studentIds'] ?? []);
          } else {
            enrolledCourseIds = List<String>.from(data['enrolledCourseIds'] ?? []);
          }
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      // Web: Use file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _webImage = result.files.first.bytes; // Web image in bytes
        });
      }
    } else {
      // Mobile: Use image picker
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes(); // Read file as bytes
        setState(() {
          _imageFile = file; // Store the File
          _webImage = bytes; // Store the image bytes
        });
      }
    }
  }

  Future<String?> _uploadProfilePicture() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${widget.userId}.jpg');
      if (kIsWeb && _webImage != null) {
        // Web: Use putData for uploading bytes
        await storageRef.putData(_webImage!);
      } else if (_imageFile != null) {
        // Mobile: Use putFile for uploading a file
        await storageRef.putFile(_imageFile!);
      } else {
        return profilePictureUrl; // No new image picked
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Start loading
      });

      try {

        String? newProfilePicUrl = await _uploadProfilePicture();

        await FirebaseFirestore.instance
            .collection(widget.role.toLowerCase() == 'teacher' ? 'Teacher' : 'Student')
            .doc(widget.userId)
            .update({
          widget.role.toLowerCase() == 'teacher' ? 'teacherName' : 'studentName': nameController.text,
          'email': emailController.text,
          'gender': selectedGender,
          'profilePictureUrl': newProfilePicUrl,
          if (widget.role.toLowerCase() == 'teacher') ...{
            'courseIds': courseIds,
            'studentIds': studentIds,
          } else
            'enrolledCourseIds': enrolledCourseIds,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));


        Navigator.pop(context);
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        color: Colors.white,
        child: profileForm(),
      ),
    );
  }

  Widget profileForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[

            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!) // Mobile
                  : (_webImage != null
                  ? MemoryImage(_webImage!) // Web
                  : (profilePictureUrl != null
                  ? NetworkImage(profilePictureUrl!)
                  : AssetImage('assets/images/user.png'))) as ImageProvider,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                final source = await showDialog<ImageSource>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Select Image Source'),
                      actions: [
                        TextButton(
                          child: Text('Camera'),
                          onPressed: () => Navigator.pop(context, ImageSource.camera),
                        ),
                        TextButton(
                          child: Text('Gallery'),
                          onPressed: () => Navigator.pop(context, ImageSource.gallery),
                        ),
                      ],
                    );
                  },
                );
                if (source != null) {
                  _pickImage(source);
                }
              },
            ),

            // Editable name
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
            ),
            SizedBox(height: 10),

            // Editable email
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
            ),
            SizedBox(height: 10),

            // Gender selection (with radio buttons)
            Text('Gender', style: TextStyle(fontSize: 16)),
            Row(
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
