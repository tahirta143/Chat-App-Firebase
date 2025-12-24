import 'package:chat_communication/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Veryfyemail extends StatefulWidget {
  const Veryfyemail({super.key});

  @override
  State<Veryfyemail> createState() => _VeryfyemailState();
}

class _VeryfyemailState extends State<Veryfyemail> {
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then(
      (value) => {
        Get.snackbar(
          'Link sent',
          'A link has been send to your email',
          margin: EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM,
        ),
      },
    );
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!.reload().then(
      (value) => {Get.offAll(Wrapper())},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verification"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            "Check your email and click on the link provided to verify email and reload this page ",
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: (()=> reload()),
      child: Icon(Icons.restart_alt),
      ),
    );
  }
}
