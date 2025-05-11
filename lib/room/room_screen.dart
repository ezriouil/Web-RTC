import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_rtc/room/room_controller.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomController controller = Get.put(RoomController());
    return Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {  },
              child: Icon(Icons.arrow_circle_left_outlined, color: Colors.black, size: 30.0)
          ),
        actions: [
          InkWell(
              onTap: () {  },
              child: Icon(Icons.arrow_circle_right_outlined, color: Colors.black, size: 30.0)
          ),
          SizedBox(width: 12.0)
        ],
      ),
      // body: Obx(
      //       () => controller.isLoading.value
      //       ? SizedBox(
      //         height: MediaQuery.of(context).size.height,
      //         width: MediaQuery.of(context).size.width,
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           spacing: 20,
      //           children: [
      //             CircularProgressIndicator(color: Colors.black),
      //             Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
      //           ],
      //         ),
      //       )
      //       : Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: [
      //           Expanded(
      //             child: !controller.isJoined.value
      //                 ? SizedBox(
      //               height: MediaQuery.of(context).size.height,
      //               width: MediaQuery.of(context).size.width,
      //               child: Column(
      //                 mainAxisAlignment: MainAxisAlignment.center,
      //                 spacing: 20,
      //                 children: [
      //                   CircularProgressIndicator(color: Colors.black),
      //                   Text("Looking For Someone Else", style: TextStyle(fontWeight: FontWeight.bold)),
      //                 ],
      //               ),
      //             )
      //                 : RTCVideoView(
      //                 controller.remoteRenderer.value!,
      //                 mirror: true,
      //                 objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
      //           ),
      //           Expanded(
      //             child: RTCVideoView(controller.localRenderer.value!,
      //                 mirror: true,
      //                 objectFit:
      //                 RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
      //           ),
      //         ],
      //       ),
      // ),

    );
  }
}