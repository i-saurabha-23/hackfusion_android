import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/auth/login.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';
import 'package:hackfusion_android/pages/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash screen delay

    // Check if user is already logged in
    await userController.loadUserEmail();

    if (userController.userEmail.value.isNotEmpty) {
      Get.offAll(() => Dashboard());  // User is logged in, go to Dashboard
    } else {
      Get.offAll(() => LoginPage());  // User is not logged in, go to Login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 100,
              color: Colors.red[700],
            ),
            const SizedBox(height: 20),
            const Text(
              'HACKFUSION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}