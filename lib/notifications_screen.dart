import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? userBloodType;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserBloodType();
  }

  /// Fetch user's blood type from Firestore
  Future<void> _fetchUserBloodType() async {
    if (userId == null) return;

    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userBloodType = userDoc['bloodType']; // Ensure bloodType exists
      });
    }
  }

  /// Mark notification as read (disappears after tap)
  void _markAsRead(String docId) {
    FirebaseFirestore.instance
        .collection('bloodRequests')
        .doc(docId)
        .update({'isRead': true}).then((_) {
      setState(() {
        unreadCount--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userBloodType == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.white),  // Set the text color to white
          ),
          backgroundColor: Colors.red,  // Set the background color to red
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),  // Set the text color to white
        ),
        backgroundColor: Colors.red,  // Set the background color to red
        actions: [
          /// Badge Counter for Unread Notifications
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bloodRequests')
                .where('bloodType', isEqualTo: userBloodType)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: badges.Badge(
                  badgeContent: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  showBadge: unreadCount > 0,
                  child: const Icon(Icons.notifications, size: 26),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bloodRequests')
            .where('bloodType', isEqualTo: userBloodType)
            //.orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data!.docs;

          return notifications.isEmpty
              ? const Center(child: Text("No new notifications"))
              : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var data = notifications[index];
              bool isRead = data['isRead'] ?? false;

              return ListTile(
                title: Text(
                  "Blood request for ${data['patientName']} at ${data['location']} - Blood Type: ${data['bloodType']} - Urgency: ${data['urgency']}",
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Text("Requested on: ${data['timestamp'].toDate()}"),
                trailing: Icon(
                  isRead ? Icons.check_circle : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.red,
                ),
                onTap: () => _markAsRead(data.id),
              );
            },
          );
        },
      ),
    );
  }
}
