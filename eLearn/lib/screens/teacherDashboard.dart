import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_app/screens/profile.dart';
import '../models/Course.dart';
import 'bottombar.dart';

class TeacherDashboard extends StatefulWidget {

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();

}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherName = '';
  String? profilePictureUrl;
  int _currentIndex = 0;
  String? userId;
  List<Course> courses = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
    _fetchCourses();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        final doc = await FirebaseFirestore.instance
            .collection('Teacher')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            teacherName = doc['teacherName'] ?? 'No Name';
            profilePictureUrl = doc['profilePictureUrl']; // Fetch the profile picture URL
          });
        } else {
          setState(() {
            teacherName = 'Teacher not found';
          });
        }
      } else {
        setState(() {
          teacherName = 'Not logged in';
        });
      }
    } on FirebaseAuthException catch (e) {
      print('Error fetching teacher data (FirebaseAuth): $e');
      handleError(context, 'Error fetching teacher data');
    } on FirebaseException catch (e) {
      print('Error fetching teacher data (Firestore): $e');
      handleError(context, 'Error fetching teacher data');
    } catch (e) {
      print('Error fetching teacher data: $e');
      handleError(context, 'An error occurred');
    }
  }

  Future<void> _fetchCourses() async {
    if (userId != null) {
      try {
        FirebaseFirestore.instance
            .collection('Course')
            .where('instructorId', isEqualTo: userId)
            .snapshots()
            .listen((snapshot) {
          setState(() {
            courses = snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
          });
        });
      } on FirebaseException catch (e) {
        print('Error fetching courses: $e');
        handleError(context, 'Error fetching courses');
      }
    }
  }

  Widget _buildTeacherProfile() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),

      child: Row(

        children: [

          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: profilePictureUrl != null
                ? NetworkImage(profilePictureUrl!)
                : AssetImage('assets/images/user.png') as ImageProvider,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Instructor',
                style: TextStyle(fontSize: 18, color: Colors.grey[500]),
              ),

            ],
          ),

        ],

      ),


    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white, // Background color of the card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Title color
              ),
            ),
            SizedBox(height: 8),
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
      ),
    );
  }

  void _onBottomBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/teacherDashboard');
        _fetchTeacherData();
        _fetchCourses();
        _buildTeacherProfile();
        break;
      case 1:
        setState(() {
          _currentIndex = 0;
        });
        Navigator.pushNamed(context, '/courses');
        break;
      case 2:
        setState(() {
          _currentIndex = 0;
        });
        Navigator.pushNamed(
          context,
          '/addCourse',
          arguments: {'userId': userId},
        );
        break;
      case 3:
        setState(() {
          _currentIndex = 0;
        });
        Navigator.pushNamed(context, '/students');
        break;
      case 4:
        setState(() {
          _currentIndex = 0;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(role: 'teacher', userId: userId!),
          ),
        ).then((_) {
          _fetchTeacherData();
        });

        break;
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void handleError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
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
        title: Text('Teacher Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeacherProfile(),
            Divider(
              color: Colors.black,
              thickness: 2,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/courseDetails',
                        arguments: {
                          'courseId': course.courseId,
                          'role': 'teacher',
                        },
                      );
                    },
                    child: _buildCourseCard(course),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onBottomBarTap,
        isTeacher: true,
      ),
    );
  }
}
