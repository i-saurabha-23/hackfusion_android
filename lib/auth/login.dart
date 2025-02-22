import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/pages/dashboard.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final UserController userController = Get.find<UserController>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Loading Animation Dots
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  ((_animationController.value + (index / 3)) % 1.0),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var studentDoc = await _firestore
          .collection('Students')
          .doc(_emailController.text)
          .get();

      if (studentDoc.exists) {
        if (studentDoc['password'] == _passwordController.text) {
          setState(() => _isLoading = false);
          await userController.setUserEmail(_emailController.text);

          // Success Snackbar
          Get.snackbar(
            'Success',
            'Welcome back to your student portal!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(10),
            borderRadius: 10,
            icon: Icon(Icons.check_circle, color: Colors.white),
          );

          Get.offAll(() => Dashboard());
        } else {
          _showError('Invalid password');
        }
      } else {
        _showError('User not found');
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(10),
      borderRadius: 10,
      icon: Icon(Icons.error_outline, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87,
              Colors.black54,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(seconds: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    spreadRadius: 5,
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.school,
                                size: 70,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 40),

                      // Welcome Text with Animation
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.3, 0.6),
                        )),
                        child: Column(
                          children: [
                            Text(
                              'Student Portal',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 50),

                      // Input Fields with Animation
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.4, 0.7),
                        )),
                        child: Column(
                          children: [
                            // Email Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Student Email',
                                  hintStyle: TextStyle(color: Colors.white60),
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(color: Colors.white60),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Login Button with Animation
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.6, 0.9, curve: Curves.elasticOut),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              shadowColor: Colors.white.withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? _buildLoadingDots()
                                : Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(0.7, 1.0),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}