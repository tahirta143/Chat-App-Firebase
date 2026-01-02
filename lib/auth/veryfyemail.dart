// import 'package:chat_communication/screens/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../homepage.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    sendVerifyLink();
  }

  // Send verification email
  sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (!user.emailVerified) {
      try {
        setState(() => isSending = true);
        await user.sendEmailVerification();
        setState(() => isSending = false);

        Get.snackbar(
          'Link Sent',
          'A verification link has been sent to your email.',
          margin: const EdgeInsets.all(20),
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        setState(() => isSending = false);
        Get.snackbar(
          'Error',
          e.toString(),
          margin: const EdgeInsets.all(20),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  // Reload user and check verification
  reloadAndCheck() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();

    if (user.emailVerified) {
      Get.offAll(() => const Homepage());
    } else {
      Get.snackbar(
        'Not Verified',
        'Email is still not verified. Please check your inbox or spam folder.',
        margin: const EdgeInsets.all(20),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Skip verification and go to home (for testing / if email not received)
  skipVerification() {
    Get.offAll(() => const Homepage());
    Get.snackbar(
      'Skipped',
      'You have skipped email verification.',
      margin: const EdgeInsets.all(20),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Email Verification"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Check your email and click the link to verify your account. "
                    "If you don't see it, check your spam/junk folder.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isSending ? null : sendVerifyLink,
                icon: const Icon(Icons.send),
                label: const Text("Resend Verification Email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              FloatingActionButton(
                onPressed: reloadAndCheck,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.restart_alt),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: skipVerification,
                child: const Text(
                  "Skip Verification",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
