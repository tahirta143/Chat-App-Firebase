import 'package:chat_communication/homepage.dart';
import 'package:chat_communication/auth/login.dart';
// import 'package:chat_communication/auth/verify_email.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth/veryfyemail.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Reload user to get latest email verification status
          return FutureBuilder(
            future: user.reload(),
            builder: (context, reloadSnapshot) {
              if (reloadSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (user.emailVerified) {
                return const Homepage();
              } else {
                return const VerifyEmail();
              }
            },
          );
        } else {
          return const Login();
        }
      },
    );
  }
}
