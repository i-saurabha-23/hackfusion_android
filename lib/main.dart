import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion_android/auth/login.dart';
import 'package:hackfusion_android/pages/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());

  print('✅ Firebase Connected');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Dashboard(),
    );
  }
}

