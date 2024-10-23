import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentsPage extends StatefulWidget {
  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch the current teacher's document
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Teacher')
          .doc(user.uid)
          .get();

      if (!teacherDoc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get the list of student IDs associated with this teacher
      List<String> studentIds = List<String>.from(teacherDoc.get('studentIds') ?? []);

      if (studentIds.isNotEmpty) {
        // Fetch the students associated with these IDs
        QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('Student')
            .where(FieldPath.documentId, whereIn: studentIds)
            .get();

        // Fetch the course details for each student
        List<Map<String, dynamic>> studentsWithCourses = [];
        for (var studentDoc in studentSnapshot.docs) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final enrolledCourseIds = List<String>.from(studentData['enrolledCourseIds'] ?? []);

          List<Map<String, dynamic>> courses = [];
          if (enrolledCourseIds.isNotEmpty) {
            final courseSnapshot = await FirebaseFirestore.instance
                .collection('Course')
                .where(FieldPath.documentId, whereIn: enrolledCourseIds)
                .get();

            courses = courseSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          }

          studentsWithCourses.add({
            ...studentData,
            'courses': courses,
          });
        }

        setState(() {
          students = studentsWithCourses;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        isLoading = false;
      });
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
        title: Text(
            'Students List',
            style: TextStyle(
            color: Colors.white,
              fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:Container(
        color: Colors.white,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : students.isEmpty
            ? Center(child: Text('No students found for this teacher.'))
            : ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final courses = student['courses'] as List<Map<String, dynamic>>;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 19),
              elevation: 6,
              child: ExpansionTile(
                title: Text(student['studentName'] ?? 'Unknown Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),),
                leading: CircleAvatar(
                  backgroundImage: student['profilePictureUrl'] != null
                      ? NetworkImage(student['profilePictureUrl'])
                      : AssetImage('assets/images/user.png') as ImageProvider,
                ),
                subtitle: Text('Email: ${student['email'] ?? 'Unknown Email'}'),
                children: courses.isNotEmpty
                    ? courses.map((course) {
                  return ListTile(
                    title: Text(course['courseTitle'] ?? 'Unknown Course'),
                    subtitle: Text('Duration: ${course['duration']  ?? 'Unknown Duration'} hours' ),
                  );
                }).toList()
                    : [ListTile(title: Text('No courses enrolled'))],
              ),
            );
          },
        ),
      )
    );
  }
}
