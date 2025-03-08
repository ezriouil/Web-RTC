import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_rtc/video_call/video_call_screen.dart';

import 'firebase_options.dart';
import 'signaling_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(onPressed: (){ Get.to( () => VideoCallScreen() ); }, child: Text('Start Call')),
      ))),
    );
  }
}

class VideoChatScreen extends StatefulWidget {
  const VideoChatScreen({super.key});

  @override
  VideoChatScreenState createState() => VideoChatScreenState();
}

class VideoChatScreenState extends State<VideoChatScreen> {

  final Signaling _signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _localRenderer.initialize();
    _remoteRenderer.initialize();

    _signaling.onAddRemoteStream = (stream) { setState(() { _remoteRenderer.srcObject = stream; }); };

    openUserMedia();
  }

  void openUserMedia() async {
    await _signaling.openUserMedia(_localRenderer, _remoteRenderer);
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: isLoading
          ? SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
            CircularProgressIndicator(color: Colors.black),
            Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
          )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _signaling.remoteStream == null
                ? SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
                : RTCVideoView(_remoteRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
          Expanded(
            child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () async {
                setState(() { isLoading = true; });
                await _signaling.hangUpTheCall();
                setState(() { isLoading = false; });
              },
              child: Icon(Icons.close, color: Colors.white)),
          FloatingActionButton(
              child: Icon(Icons.video_call, color: Colors.black),
              onPressed: () { _signaling.joinTheCall(_remoteRenderer); }),
          FloatingActionButton(
              child: Icon(Icons.add_circle, color: Colors.black),
              onPressed: () { _signaling.createNewCall(_remoteRenderer); })
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

}