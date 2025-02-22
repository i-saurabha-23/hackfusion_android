import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/auth/login.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';
import 'package:hackfusion_android/pages/dashboard.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final UserController userController = Get.find<UserController>();

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Particle> particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();

    // Rotation animation for the code icon
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Fade and scale animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    await userController.loadUserEmail();

    if (userController.userEmail.value.isNotEmpty) {
      Get.offAll(() => Dashboard());
    } else {
      Get.offAll(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated particles in background
          ...particles.map((particle) => AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              final progress = _particleController.value;
              final offset = particle.getPosition(progress);
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 1.0,
                    end: 0.0,
                  ).animate(_particleController),
                  child: Container(
                    width: particle.size,
                    height: particle.size,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          )).toList(),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotating and pulsing code icon
                AnimatedBuilder(
                  animation: Listenable.merge([_rotationController, _pulseController]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.2),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 20 + (_pulseController.value * 10),
                                spreadRadius: 5 + (_pulseController.value * 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.code,
                            size: 100,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Animated text with fade and scale
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [Colors.red[700]!, Colors.red[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'HACKFUSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Custom loading indicator
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: SweepGradient(
                            colors: [
                              Colors.red.withOpacity(0),
                              Colors.red[700]!,
                            ],
                            stops: const [0.8, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class for background animation
class Particle {
  final double size = math.Random().nextDouble() * 4 + 2;
  final Offset startPosition = Offset(
    math.Random().nextDouble() * Get.width,
    math.Random().nextDouble() * Get.height,
  );
  final Offset endPosition = Offset(
    math.Random().nextDouble() * Get.width,
    math.Random().nextDouble() * Get.height,
  );

  Offset getPosition(double progress) {
    return Offset.lerp(startPosition, endPosition, progress)!;
  }
}