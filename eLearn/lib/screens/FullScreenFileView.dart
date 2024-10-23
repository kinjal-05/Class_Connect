import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/Lesson.dart';
import 'VideoPlayerScreen.dart';

class FullScreenFileView extends StatelessWidget {
  final String fileUrl;
  final LessonType type;

  const FullScreenFileView({required this.fileUrl, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.indigo,
        title: Text(
            'File Preview',
            style: TextStyle(
            color: Colors.white,
            fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SizedBox(
          width: double.maxFinite,
          height: double.maxFinite,
          child: type == LessonType.pdf
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('PDF File',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (await canLaunch(fileUrl)) {
                    await launch(fileUrl);
                  } else {
                    throw 'Could not launch $fileUrl';
                  }
                },
                child: Text('Open PDF'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (await canLaunch(fileUrl)) {
                    await launch(fileUrl);
                  } else {
                    throw 'Could not launch $fileUrl';
                  }
                },
                child: Text('Download PDF'),
              ),
            ],
          )
              : type == LessonType.video
              ? VideoPlayerScreen(fileUrl)
              : Text('Unsupported file type'),
        ),
      ),
    );
  }
}
