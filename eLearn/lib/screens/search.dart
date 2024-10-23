import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  bool _isSearching = false;
  List<String> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchCourses);
    _fetchEnrolledCourses();
  }

  Future<void> _fetchEnrolledCourses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        final studentDoc = await FirebaseFirestore.instance
            .collection('Student')
            .doc(userId)
            .get();

        if (studentDoc.exists) {
          final enrolledCourseIds = studentDoc.data()?['enrolledCourseIds'] as List<dynamic>? ?? [];
          setState(() {
            _enrolledCourses = enrolledCourseIds.map((e) => e.toString()).toList();
          });
        }
      } catch (e) {
        print('Error fetching enrolled courses: $e');
      }
    }
  }

  Future<void> _searchCourses() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _courses = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final query = _searchController.text;

    try {
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Course')
          .where('courseTitle', isGreaterThanOrEqualTo: query)
          .where('courseTitle', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Retrieve course data and associated teacher data
      List<Map<String, dynamic>> coursesWithTeacherData = [];
      for (var doc in courseSnapshot.docs) {
        final courseData = doc.data() as Map<String, dynamic>;

        // Manually assign the document ID as the courseId
        final courseId = doc.id;

        final instructorId = courseData['instructorId'] as String?;

        if (instructorId != null) {
          final teacherSnapshot = await FirebaseFirestore.instance
              .collection('Teacher')
              .doc(instructorId)
              .get();

          final teacherData = teacherSnapshot.data() as Map<String, dynamic>?;

          if (teacherData != null && teacherData.containsKey('teacherName')) {
            coursesWithTeacherData.add({
              'type': 'course',
              ...courseData,
              'courseId': courseId,
              'instructorName': teacherData['teacherName'],
            });
          }
        }
      }

      setState(() {
        _courses = coursesWithTeacherData;
      });
    } catch (e) {
      print('Error searching courses: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _enrollInCourse(String? courseId) async {
    if (courseId == null) {
      print('Course ID is null, cannot enroll.');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        // Fetch the course document to get the instructorId
        DocumentSnapshot courseDoc = await FirebaseFirestore.instance
            .collection('Course')
            .doc(courseId)
            .get();

        if (!courseDoc.exists) {
          print('Course not found');
          return;
        }

        String? instructorId = courseDoc['instructorId'] as String?;

        if (instructorId == null) {
          print('Instructor ID is null');
          return;
        }

        // Update the student's enrolled courses
        await FirebaseFirestore.instance.collection('Student')
            .doc(userId)
            .update({
          'enrolledCourseIds': FieldValue.arrayUnion([courseId]),
        });

        // Update the teacher's studentIds array
        await FirebaseFirestore.instance.collection('Teacher')
            .doc(instructorId)
            .update({
          'studentIds': FieldValue.arrayUnion([userId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolled in the course successfully!')),
        );

        setState(() {
          _enrolledCourses.add(courseId);
        });

        Navigator.pop(context, true);
      } catch (e) {
        print('Error enrolling in course: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enroll in the course')),
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
        title: Text('Search Courses',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by course title',
                  border: OutlineInputBorder(),
                  suffixIcon: _isSearching ? CircularProgressIndicator() : null,
                ),
              ),
            ),
            if (_courses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Text(
                  'Courses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final data = _courses[index];
                    final courseId = data['courseId'] as String?;
                    final isEnrolled = courseId != null && _enrolledCourses.contains(courseId);

                    return ListTile(
                      title: Text(data['courseTitle'] ?? 'Unknown Course'),
                      subtitle: Text('Instructor: ${data['instructorName'] ?? 'Unknown Instructor'}'),
                      trailing: ElevatedButton(
                        onPressed: isEnrolled
                            ? null
                            : () => _enrollInCourse(courseId),
                        child: Text(isEnrolled ? 'Enrolled' : 'Enroll'),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_isSearching) ...[
              Center(child: CircularProgressIndicator()),
            ] else ...[
              Center(child: Text('No courses found')),
            ],
          ],
        ),
      )
    );
  }
}
