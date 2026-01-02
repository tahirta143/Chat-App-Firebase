import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final Map peerUser;

  ChatScreen({required this.peerUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final picker = ImagePicker();

  String chatId = "";
  String statusText = "";
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.peerUser['uid'] != null) {
      currentUserId = user.uid;
      chatId = _getChatId(currentUserId, widget.peerUser['uid']);
      _setOnline();
      _listenUserStatus();
      _markDelivered();
      _markSeen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else {
      _setOffline();
    }
  }

  // Generate a stable chatId for two users
  String _getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1\_$uid2' : '$uid2\_$uid1';
  }

  // 🔵 Online
  void _setOnline() async {
    if (currentUserId.isEmpty) return;
    await _firestore.collection("users").doc(currentUserId).update({
      "online": true,
      "lastSeen": FieldValue.serverTimestamp()
    });
  }

  // ⚪ Offline
  void _setOffline() async {
    if (currentUserId.isEmpty) return;
    await _firestore.collection("users").doc(currentUserId).update({
      "online": false,
      "lastSeen": FieldValue.serverTimestamp()
    });
  }

  // 👁 Peer online/last seen
  void _listenUserStatus() {
    if (widget.peerUser['uid'] == null) return;
    _firestore
        .collection("users")
        .doc(widget.peerUser['uid'])
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data["online"] == true) {
        setState(() => statusText = "Online");
      } else {
        Timestamp? ts = data["lastSeen"];
        if (ts != null) {
          final date = ts.toDate();
          setState(() {
            statusText =
            "last seen ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
          });
        } else {
          setState(() => statusText = "Offline");
        }
      }
    });
  }

  // 📩 Mark messages delivered
  void _markDelivered() async {
    if (chatId.isEmpty) return;
    final query = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'status': 'delivered'});
    }
  }

  // 👀 Mark messages seen
  void _markSeen() {
    if (chatId.isEmpty) return;
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'seen'});
      }
    });
  }

  // ✉️ Send text
  void sendMessage() async {
    if (_controller.text.trim().isEmpty || chatId.isEmpty) return;

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'type': 'text',
      'content': _controller.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent'
    });

    _controller.clear();
  }

  // 🖼 Send image
  void pickAndSendImage() async {
    if (chatId.isEmpty) return;

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'type': 'image',
      'content': url,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent'
    });
  }

  // 📄 Send document
  void pickAndSendDocument() async {
    if (chatId.isEmpty) return;

    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_documents')
        .child('${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'type': 'document',
      'content': url,
      'fileName': result.files.single.name,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent'
    });
  }

  @override
  Widget build(BuildContext context) {
    if (chatId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: Text(widget.peerUser['name'] ?? "Chat",style: TextStyle(color: Colors.white),)),
        body: Center(child: Text("Invalid chat. Try again.")),
      );
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.deepPurple,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon:Icon(Icons.arrow_back_ios,color: Colors.white,)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerUser['name'] ?? "Chat",style: TextStyle(color: Colors.white)),
            Text(statusText, style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final msgData = msg.data() as Map<String, dynamic>? ?? {};
                    final isMe = msgData['senderId'] == currentUserId;

                    Widget messageWidget;
                    if (msgData['type'] == 'text') {
                      messageWidget = Text(msgData['content'] ?? '');
                    } else if (msgData['type'] == 'image') {
                      messageWidget = Image.network(msgData['content'] ?? '', width: 200);
                    } else if (msgData['type'] == 'document') {
                      messageWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_drive_file),
                          SizedBox(width: 5),
                          Flexible(child: Text(msgData['fileName'] ?? 'Document')),
                        ],
                      );
                    } else {
                      messageWidget = Text('Unsupported message');
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            messageWidget,
                            SizedBox(height: 4),
                            if (isMe)
                              Icon(
                                msgData['status'] == 'sent'
                                    ? Icons.check
                                    : msgData['status'] == 'delivered'
                                    ? Icons.done_all
                                    : Icons.done_all,
                                size: 16,
                                color: msgData['status'] == 'seen' ? Colors.blue : Colors.grey,
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.image), onPressed: pickAndSendImage),
                IconButton(icon: Icon(Icons.attach_file), onPressed: pickAndSendDocument),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
