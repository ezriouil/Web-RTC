import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_rtc/video_call/video_call_controller.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoCallController controller = Get.put(VideoCallController());
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
              onTap: () { controller.hangUpTheRoom(); },
              child: Icon(Icons.arrow_circle_left_outlined, color: Colors.black, size: 30.0)
          ),
        actions: [
          InkWell(
              onTap: () { controller.hangUpTheRoom(); },
              child: Icon(Icons.arrow_circle_right_outlined, color: Colors.black, size: 30.0)
          ),
          SizedBox(width: 12.0)
        ],
      ),
      body: Obx(
            () => controller.isInitialising.value
            ? SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  CircularProgressIndicator(color: Colors.black, strokeWidth: 3.0),
                  Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: !controller.isJoined.value
                      ? SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 20,
                      children: [
                        CircularProgressIndicator(color: Colors.black, strokeWidth: 3.0),
                        Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                      : RTCVideoView(
                      controller.remoteRenderer.value!,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                  ),
                ),
                Divider(color: Colors.white, thickness: 5),
                Expanded(
                  child: RTCVideoView(controller.localRenderer.value!,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                  ),
                ),
              ],
            ),
      ),
    );
  }
}