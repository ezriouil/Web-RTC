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
              child: Icon(Icons.arrow_circle_left_outlined, color: Colors.black)
          )
      ),
      body: Obx(
            () => controller.isLoading.value
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
                  child: controller.isJoined.isFalse
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
                      : RTCVideoView(
                      controller.remoteRenderer.value!,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
                Expanded(
                  child: RTCVideoView(controller.localRenderer.value!,
                      mirror: true,
                      objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ],
            ),
      ),
      // floatingActionButton: SizedBox(
      //   height: MediaQuery.of(context).size.height,
      //   width: MediaQuery.of(context).size.width,
      //   child: Padding(
      //     padding: EdgeInsets.only(left: 24),
      //     child: Column(
      //       mainAxisSize: MainAxisSize.max,
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       spacing: 12,
      //       children: [
      //         // FloatingActionButton(
      //         //     child: Icon(Icons.add_circle, color: Colors.black),
      //         //     onPressed: () { controller.createNewRoom(); }),
      //         // FloatingActionButton(
      //         //     child: Icon(Icons.video_call, color: Colors.black),
      //         //     onPressed: () { controller.joinTheRoom(roomId: '10'); }),
      //         FloatingActionButton(
      //             backgroundColor: Colors.red,
      //             onPressed: () async {
      //               controller.isLoading.value = true;
      //               try { controller.hangUpTheRoom(); }
      //               catch (_) {}
      //               finally { controller.isLoading.value = false; }
      //             },
      //             child: Icon(Icons.close, color: Colors.white)),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}