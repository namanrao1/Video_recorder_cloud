import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(cameras: cameras),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyHomePage({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bottom App Bar Example'),
      ),
      body: Center(
        child: Text('Body content goes here'),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoRecorderScreen(cameras: cameras)),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Add functionality for button 2
                print('Button 2 pressed');
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Add functionality for button 3
                print('Button 3 pressed');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VideoRecorderScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  VideoRecorderScreen({required this.cameras});

  @override
  _VideoRecorderScreenState createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0], // Use the first camera in the list
      ResolutionPreset.high,
    );
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Video Recorder'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Recorder'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: CameraPreview(_controller),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onRecordButtonPressed();
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  void _onRecordButtonPressed() {
    _controller.startVideoRecording().then((value) {
      print('Recording started');
    }).catchError((error) {
      print('Error starting recording: $error');
    });
  }
}
