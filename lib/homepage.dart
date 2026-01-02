import 'package:chat_communication/screens/chatscreen.dart';
import 'package:chat_communication/auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  // Logout method
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const Login());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text("No other users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>? ?? {};

              final phone = userData['phone'] ?? 'No phone';
              final name = userData['name'] ?? 'No Name';

              // Use StreamBuilder to listen for unread messages
              final chatId = getChatId(currentUserId, user.id);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .where('senderId', isEqualTo: user.id)
                    .where('status', isNotEqualTo: 'seen')
                    .snapshots(),
                builder: (context, msgSnapshot) {
                  bool hasUnread = false;

                  if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
                    hasUnread = true;
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 3,
                      child: ListTile(
                        leading: hasUnread
                            ? const Icon(Icons.circle, color: Colors.green, size: 12)
                            : null,
                        title: Text(name),
                        subtitle: Text(phone),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(peerUser: {
                                "uid": user.id,
                                "name": name,
                                "phone": phone,
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Generate a consistent chatId between two users
  String getChatId(String userId1, String userId2) {
    return (userId1.compareTo(userId2) > 0)
        ? '$userId2\_$userId1'
        : '$userId1\_$userId2';
  }
}
