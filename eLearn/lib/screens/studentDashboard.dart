import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_app/screens/profile.dart';
import 'package:learning_app/screens/search.dart';
import 'bottombar.dart';
import '../models/Course.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  String studentName = 'Loading...';
  String? profilePictureUrl;
  String? userId;
  List<Course> courses = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
        });

        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('Student')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          setState(() {
            studentName = studentDoc['studentName'] ?? 'No Name';
            profilePictureUrl = studentDoc['profilePictureUrl'];
            List<String> enrolledCourseIds = List<String>.from(studentDoc['enrolledCourseIds'] ?? []);
            _fetchCourses(enrolledCourseIds);
          });
        } else {
          setState(() {
            studentName = 'Student not found';
          });
        }
      } else {
        setState(() {
          studentName = 'Not logged in';
        });
      }
    } catch (e) {
      setState(() {
        studentName = 'Error loading name';
      });
      print('Error: $e');
    }
  }

  Future<void> _fetchCourses(List<String> enrolledCourseIds) async {
    if (enrolledCourseIds.isNotEmpty) {
      try {
        QuerySnapshot courseSnapshot = await FirebaseFirestore.instance
            .collection('Course')
            .where(FieldPath.documentId, whereIn: enrolledCourseIds)
            .get();

        setState(() {
          courses = courseSnapshot.docs.map((doc) {
            return Course.fromFirestore(doc);
          }).toList();
        });
      } catch (e) {
        print('Error fetching courses: $e');
      }
    }
  }

  Widget _buildStudentProfile() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Background color
        borderRadius: BorderRadius.circular(12),

      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: profilePictureUrl!= null
                ? NetworkImage(profilePictureUrl!)
                : AssetImage('assets/images/user.png') as ImageProvider,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Student',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToSearchPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );

    if (result == true) {
      _fetchStudentData();
    }
  }



  void _onBottomBarTap(int index) {
    setState(() {
      _currentIndex = index;
      _buildStudentProfile();
      _fetchStudentData();

    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/studentDashboard');
        break;
      case 1:
        if (userId != null) {
          setState(() {
            _currentIndex = 0;
          });
          _navigateToSearchPage();
        }
        break;
      case 2:
        if (userId != null) {
          setState(() {
            _currentIndex = 0;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(role: 'student', userId: userId!),
            ),
          ).then((_) {
            _fetchStudentData();
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: (Colors.indigo),
        title: Text('Student Dashboard',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onBottomBarTap,
        isTeacher: false,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentProfile(),
            Divider(
              color: Colors.black,
              thickness: 2,
            ),
            SizedBox(height: 20),
            Expanded(
              child: _buildCourseSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSection() {
    if (courses.isEmpty) {
      return Center(
        child: Text(
          'You are not enrolled in any courses.',
          style: TextStyle(fontSize: 18, color: Colors.redAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index];
              return Card(
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    course.courseTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Title color
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.cDescription,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Duration: ${course.duration} hours',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Teacher').doc(course.instructorId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error');
                      } else if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('No Instructor');
                      } else {
                        return Text(
                          'Instructor: ${snapshot.data!['teacherName']}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/courseDetails',
                      arguments: {
                        'courseId': course.courseId,
                        'role': 'student',
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

