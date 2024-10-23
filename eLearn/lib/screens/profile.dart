import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'EditProfile.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String userId;

  ProfilePage({required this.role, required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;

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
        setState(() {
          profileData = profileDoc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          profileData = null;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      setState(() {
        profileData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (profileData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('Loading profile...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),

        backgroundColor: Colors.indigo,
        title: Text('Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfile(userId: widget.userId, role: widget.role),
                ),
              ).then((_) {
                _fetchProfileData();
              });


              if (result == true) {
                _fetchProfileData();

              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: FadeInImage(
                    placeholder: AssetImage('assets/images/spinner.gif'),
                    image: profileData!['profilePictureUrl'] != null &&
                        profileData!['profilePictureUrl'].isNotEmpty
                        ? NetworkImage(profileData!['profilePictureUrl'])
                        : AssetImage('assets/images/user.png') as ImageProvider,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration(milliseconds: 200),
                    fadeOutDuration: Duration(milliseconds: 100),
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/images/user.png', fit: BoxFit.cover);
                    },
                  ),
                ),
              ),

              SizedBox(height: 16),
              // Divider line
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: 16),
              // Profile details
              Expanded(
                child: ListView(
                  children: <Widget>[
                    _buildProfileDetailRow(
                      label: 'Name',
                      value: widget.role.toLowerCase() == 'teacher'
                          ? profileData!['teacherName'] ?? 'No Name'
                          : profileData!['studentName'] ?? 'No Name',
                    ),
                    _buildProfileDetailRow(
                      label: 'Email',
                      value: profileData!['email'] ?? 'No Email',
                    ),
                    if (widget.role.toLowerCase() == 'teacher') ...[
                      _buildProfileDetailRow(
                        label: 'Courses',
                        value: '${profileData!['courseIds']?.length ?? 0}',
                      ),
                      _buildProfileDetailRow(
                        label: 'Students',
                        value: '${profileData!['studentIds']?.length ?? 0}',
                      ),
                      _buildProfileDetailRow(
                        label: 'Gender',
                        value: profileData!['gender'] ?? 'Not Specified',
                      ),
                    ] else ...[
                      _buildProfileDetailRow(
                        label: 'Gender',
                        value: profileData!['gender'] ?? 'Not Specified',
                      ),
                      _buildProfileDetailRow(
                        label: 'Enrolled Courses',
                        value: '${profileData!['enrolledCourseIds']?.length ?? 0}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildProfileDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
