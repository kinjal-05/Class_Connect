import'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:learning_app/screens/AddCourse.dart';
import 'package:learning_app/screens/AddLesson.dart';
import 'package:learning_app/screens/CourseDetails.dart';
import 'package:learning_app/screens/Courses.dart';
import 'package:learning_app/screens/EditLesson.dart';
import 'package:learning_app/screens/EditProfile.dart';
import 'package:learning_app/screens/LoginScreen.dart';
import 'package:learning_app/screens/SignupScreen.dart';
import 'package:learning_app/screens/Students.dart';
import 'package:learning_app/screens/profile.dart';
import 'package:learning_app/screens/search.dart';
import 'package:learning_app/screens/studentDashboard.dart';
import 'package:learning_app/screens/teacherDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/Lesson.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if userId exists in SharedPreferences
  bool isLoggedIn = prefs.containsKey('userId');

  // Run the app with login state
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/' : '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/teacherDashboard': (context) => TeacherDashboard(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ProfilePage(role: args['role'], userId: args['userId']);
        },
        '/addCourse': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AddCourse(userId: args['userId']);
        },
        '/courses': (context) => CoursesPage(),
        '/addLesson': (context) {
          final courseId = ModalRoute.of(context)?.settings.arguments as String?;
          return AddLessonPage(courseId: courseId!);
        },
        '/courseDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final courseId = args['courseId'] as String?;
          final role = args['role'] as String?;
          return CourseDetails(courseId: courseId, role: role);
        },

        '/editLesson': (context) {
          final lesson = ModalRoute.of(context)!.settings.arguments as Lesson;
          return EditLesson(lesson: lesson);
        },
        '/editProfile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final String role = args['role'];
          final String userId = args['userId'];

          return EditProfile(role: role, userId: userId);
        },
        '/search': (context) => SearchPage(),
        '/students': (context) => StudentsPage(),
      },
    );
  }
}
