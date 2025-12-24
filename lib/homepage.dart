import 'package:chat_communication/widgets/listtiles.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  final List<Map<String, String>> users = const [
    {"name": "Ali", "uid": "1"},
    {"name": "Ahmed", "uid": "2"},
    {"name": "Sana", "uid": "3"},
    {"name": "Umer", "uid": "4"},
    {"name": "Umer", "uid": "5"},
    {"name": "Umer", "uid": "6"},
    {"name": "Umer", "uid": "7"},
  ];

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '$user1\_$user2'
        : '$user2\_$user1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text("Home"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Logout logic
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Settings') {
                  // Navigate to settings
                } else if (value == 'Help') {
                  // Navigate to help
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Settings',
                  child: Text('Settings'),
                ),
                const PopupMenuItem<String>(value: 'Help', child: Text('Help')),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: users.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final user = users[index];
            final name = user['name']!;
            final uid = user['uid']!;
            return UserTile(
              name: name,
              onTap: () {
                // Open ChatScreen
                final chatId = getChatId("currentUserId", uid);
                // Navigator.push(...);
              },
            );
          },
        ),
      ),
    );
  }
}
