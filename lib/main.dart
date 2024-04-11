
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

import 'dart:io';

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const VideoPlayerScreen({Key? key, required this.videoUrl, required this.videoTitle}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle),
      ),
      body: Column(
        children: [

          Expanded(
            child: Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : CircularProgressIndicator(),
            ),
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              LikeButton(),
              DislikeButton(),
              IconButton(
                onPressed: () {
                  // Share action
                },
                icon: Icon(Icons.share),
              ),
            ],
          ),
          SizedBox(height: 16),
          CommentBox(),
        ],
      ),

    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class LikeButton extends StatefulWidget {
  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
        color: _liked ? Colors.blue : null,
      ),
      onPressed: () {
        setState(() {
          _liked = !_liked;
        });
      },
    );
  }
}

class DislikeButton extends StatefulWidget {
  @override
  _DislikeButtonState createState() => _DislikeButtonState();
}

class _DislikeButtonState extends State<DislikeButton> {
  bool _disliked = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _disliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
        color: _disliked ? Colors.red : null,
      ),
      onPressed: () {
        setState(() {
          _disliked = !_disliked;
        });
      },
    );
  }
}

class CommentBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Write your comment here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Submit comment
              },
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoThumbnailPage extends StatefulWidget {
  final String videoFilePath;

  const VideoThumbnailPage({Key? key, required this.videoFilePath})
      : super(key: key);

  @override
  _VideoThumbnailPageState createState() => _VideoThumbnailPageState();
}

class _VideoThumbnailPageState extends State<VideoThumbnailPage> {
  late Uint8List _thumbnailData=Uint8List(0);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }




  Future<void> _generateThumbnail() async {
    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Convert latitude and longitude to a readable address
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

        String locality = placemarks[0].locality ?? '';
    String country = placemarks[0].country ?? '';
       String _locationName2 = '$locality,$country';

    String address = _locationName2 ?? 'Unknown';

    // Update the location controller with the address
    _locationController.text = address;

    // Generate thumbnail
    final thumbnailData = await video_thumbnail.VideoThumbnail.thumbnailData(
      video: widget.videoFilePath,
      imageFormat: video_thumbnail.ImageFormat.JPEG,
      maxWidth: 300,
      quality: 100,
    );

    setState(() {
      _thumbnailData = thumbnailData!;
    });
  }



  void _handlePost(BuildContext context) async {
    final title = _titleController.text;
    final location = _locationController.text;
    final category = _categoryController.text;
    final videoFilePath = widget.videoFilePath; // Get video file path

    try {
      File videoFile = File(videoFilePath);

      // Generate a unique filename for the video
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Reference to the Firebase Storage bucket
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('videos')
          .child(fileName + '.mp4');

      // Upload the video file to Firebase Storage
      await ref.putFile(videoFile);

      // Get the download URL of the uploaded video
      String downloadURL = await ref.getDownloadURL();

      // Upload video details to Firestore
      await FirebaseFirestore.instance.collection('videos').add({
        'title': title,
        'location': location,
        'category': category,
        'videoUrl': downloadURL, // Store the download URL in Firestore
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video posted successfully!'),
          duration: Duration(seconds: 2), // Adjust the duration as needed
        ),
      );

      // Return to the homepage
      Navigator.pop(context);
    } catch (error) {
      print('Error uploading video: $error');
      // Show an error message if upload fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post video. Please try again later.'),
          duration: Duration(seconds: 2), // Adjust the duration as needed
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Thumbnail'),
      ),
      body:SingleChildScrollView(child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildThumbnailImage(),
            _buildInputField(_titleController, 'Title'),
            _buildInputField(_locationController, 'Location'),
            _buildInputField(_categoryController, 'Category'),
            _buildPostButton(),
          ],
        ),
      ),)
    );
  }

  Widget _buildThumbnailImage() {
    return _thumbnailData != null
        ? Image.memory(_thumbnailData)
        : CircularProgressIndicator();
  }

  Widget _buildInputField(TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          _handlePost(context);
        },
        child: Text('Post'),
      ),
    );
  }


  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
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
class VideoDetails {
  final String title;
  final String location;
  final String category;
  final String videoUrl;

  VideoDetails({
    required this.title,
    required this.location,
    required this.category,
    required this.videoUrl,
  });

  factory VideoDetails.fromMap(Map<String, dynamic> map) {
    return VideoDetails(
      title: map['title'],
      location: map['location'],
      category: map['category'],
      videoUrl: map['videoUrl'],
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  MyHomePage({required this.cameras});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('videos').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No videos available'));
                }

                // Filter the list of videos based on the search query
                final filteredVideos = snapshot.data!.docs.map((DocumentSnapshot document) {
                  final data = document.data() as Map<String, dynamic>;
                  final videoDetails = VideoDetails.fromMap(data);
                  return videoDetails;
                }).where((video) {
                  final lowercaseQuery = _searchQuery.toLowerCase();
                  return video.title.toLowerCase().contains(lowercaseQuery) ||
                      video.location.toLowerCase().contains(lowercaseQuery);
                }).toList();

                if (filteredVideos.isEmpty) {
                  return Center(child: Text('No matching videos'));
                }

                return ListView(
                  children: filteredVideos.map((videoDetails) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle), // User icon
                          SizedBox(width: 8), // Add some space between icon and text
                          Expanded(
                            child: ListTile(
                              title: Text(videoDetails.title),
                              subtitle: Text(videoDetails.location),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: videoDetails.videoUrl, videoTitle: videoDetails.title,)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TextButton(
              onPressed: () async {
                final cameras=await availableCameras();
                // Navigate to the explore screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(cameras: cameras)), // Replace ExploreScreen with your explore screen widget
                );
              },
              child: Text("EXPLORE"),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoRecorderScreen(cameras: widget.cameras)),
                );
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
  bool _isRecording = false;
  bool _isLocationPermissionGranted = false;
  bool _hasRequestedPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (!_hasRequestedPermission) {
      _hasRequestedPermission = true;
      final locationStatus = await Permission.locationWhenInUse.request();
      if (locationStatus == PermissionStatus.granted) {
        setState(() {
          _isLocationPermissionGranted = true;
        });
        _initializeCamera();
      } else {
        // Handle the case where the user denied or didn't grant location permission
      }
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationPermissionGranted || _controller == null || !_controller.value.isInitialized) {

      _requestPermission();
      return Scaffold(
        appBar: AppBar(
          title: Text('Video Recorder'),
        ),
        body: Center(
          child: _isLocationPermissionGranted ? CircularProgressIndicator() : Text('GPS permission required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Recorder'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? Stack(
          children: <Widget>[
            CameraPreview(_controller),
          ],
        )
            : Container(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _switchCamera,
            child: Icon(Icons.switch_camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              if (_isRecording) {
                _onStopButtonPressed();
              } else {
                _onRecordButtonPressed();
              }
            },
            child: Icon(_isRecording ? Icons.stop : Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  void _onRecordButtonPressed() {
    _controller.startVideoRecording().then((value) {
      print('Recording started');
      setState(() {
        _isRecording = true;
      });
    }).catchError((error) {
      print('Error starting recording: $error');
    });
  }

  void _onStopButtonPressed() async {
    try {
      XFile videoFile = await _controller.stopVideoRecording();
      print('Recording stopped');

      setState(() {
        _isRecording = false;
      });

      // Get the directory for saving files
      Directory? appDocDir = await getExternalStorageDirectory();
      String appDocPath = appDocDir!.path;

      // Move the recorded video to a custom folder
      Directory customFolder = Directory('$appDocPath/RecordedVideos');
      if (!await customFolder.exists()) {
        customFolder.create(recursive: true);
      }
      String newFilePath = '${customFolder.path}/video_${DateTime.now()}.mp4';
      await videoFile.saveTo(newFilePath);

      print('Video saved at: $newFilePath');

      // Redirect to the video thumbnail page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoThumbnailPage(videoFilePath: newFilePath)),
      );
    } catch (error) {
      print('Error stopping recording: $error');
    }
  }

  void _switchCamera() async {
    final lensDirection = _controller.description.lensDirection;
    CameraDescription newCamera;

    if (lensDirection == CameraLensDirection.back) {
      newCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } else {
      newCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    }

    await _controller.dispose();
    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
    );
    await _controller.initialize();

    setState(() {});
  }
}






class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  late TwilioFlutter _twilioFlutter;
  late String _sentOTP = '';
  final accountSid = 'ACd1bf45f491869a2573bc0859700a6661';
  final authToken = '813ed4c5d36249d0a5553f0def929919';
  final verifySid = 'VA894ffee703ef7341a9ab40b2771e6c60';
  final phoneNumber = '';

  void _verifyPhoneNumber() async {
    final phoneNumber = _phoneNumberController.text.toString();
    // Perform phone number verification logic here
    // You can implement Twilio verification or any other method

    // Navigate to OTP screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OtpScreen(phoneNumber)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Authentication'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _verifyPhoneNumber,
              child: Text('Verify Phone Number'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatelessWidget {
  final String phoneNumber;

  OtpScreen(this.phoneNumber);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter OTP'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Enter OTP sent to $phoneNumber'),
            TextField(
              decoration: InputDecoration(labelText: 'OTP'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                final cameras= await availableCameras();
                Navigator.push(context, MaterialPageRoute(builder: (context)=>MyHomePage(cameras: cameras)));
                // Handle OTP verification
              },
              child: Text('Verify OTP'),
            ),
            Text("Resend otp?",style: TextStyle(color: Colors.blue),)
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  print('Firebase connected successfully!');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PhoneAuthScreen(),
  ));
}
