__Class_Conect__

-This is a Flutter-based application designed for teachers to create lessons in the form of PDFs and videos and track student enrollment. 
-Students can browse available lessons, view them, and enroll. 
-The app also provides a dashboard to manage lessons and view the number of students enrolled.

- __Teacher features__:
  - Upload lessons in PDF or video format.
  - View the number of students enrolled in each lesson.
    
- __Student features__:
  - Browse and view available lessons.
  - Enroll in lessons.
- Both teacher and student roles supported with role-based access.

  __Before you begin, ensure you have met the following requirements__:
- Flutter SDK installed.
- Dart installed.
- A Firebase project with Firestore enabled.

__Installation__
1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd lesson-management-app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Set up Firebase:
   - Create a Firebase project.
   - Add `google-services.json` for Android and `GoogleService-Info.plist` for iOS in the respective directories.
   - Enable Firestore and Authentication in the Firebase console.
5. Run the project:
   ```bash
   flutter run
   ```


