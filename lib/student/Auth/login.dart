import 'package:flutter/material.dart';

import '../../Components/animated_card.dart';
import '../../Components/custom_button.dart';
import '../../Components/reusable_text_field.dart';


class StudentLoginPage extends StatelessWidget {
  const StudentLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff6DD5FA), Color(0xff2980B9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedCard(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Student Login",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const ReusableTextField(
                          label: 'Email',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        const ReusableTextField(
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: "Login",
                          onPressed: () {
                            // TODO: Implement login logic.
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to forgot password page.
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                          ),
                          child: const Text("Forgot Password?"),
                        ),
                      ],
                    ),
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
