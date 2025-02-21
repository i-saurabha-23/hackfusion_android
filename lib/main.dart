import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';
import 'package:hackfusion_android/pages/SideMenuPages/CampusBooking/booking.dart';
import 'auth/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the UserController globally
  Get.put(UserController(), permanent: true);

  runApp(const MyApp());
  debugPrint('✅ Firebase Connected');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: SplashScreen(),
    );
  }
}
