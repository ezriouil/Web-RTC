import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:web_rtc/video_call/video_call_screen.dart';

import 'firebase_options.dart';

// adb pair 192.168.3.71:
// adb connect 192.168.3.71:

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
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
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
            child: ElevatedButton(
                onPressed: () async {
                  while (true) {
                    Map<String, dynamic>? isBack = await Get.to(() => VideoCallScreen());
                    print('=====');
                    print(isBack.toString());
                    print('=====');
                    if(isBack == null) break;
                    if(isBack['result'] == false) break;
                    if(isBack['isMeTheCaller']!) { await Future.delayed(Duration(milliseconds: 3000)); }
                    else { await Future.delayed(Duration(milliseconds: 2000)); }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12.0,
                  children: [
                    Icon(Icons.video_call_outlined, color: Colors.white, size: 20),
                    Text("New Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
            )
        ),
      ),
    );
  }
}
