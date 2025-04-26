import 'package:bloodconnect/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'request_blood_screen.dart';
import 'donationdashboard.dart';
import 'nearbyblood.dart';
import 'events.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context, true);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          'BloodConnect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          // Notification Icon with Badge
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const CircularProgressIndicator();
              }

              // Get the blood type of the user
              String bloodType = userSnapshot.data!['bloodType'] ?? 'Unknown';

              // Fetch unread notifications for the user's blood type
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bloodRequests')
                    .where('bloodType', isEqualTo: bloodType) // Match the blood type of the user
                    .where('isRead', isEqualTo: false) // Only unread notifications
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  print("Unread Count: $unreadCount"); // Debugging print

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0) // Show badge only if there are unread notifications
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),

          // Profile Icon
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Icon(Icons.account_circle, color: Colors.white, size: 28);
              }

              var userData = snapshot.data!;
              String name = userData['name'] ?? 'No Name';
              String phone = userData['phone'] ?? 'No Phone';

              return PopupMenuButton<int>(
                icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                onSelected: (value) {
                  if (value == 1) {
                    _logout(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<int>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.black87,)),
                        const Divider(),
                        Text("Name: $name", style: const TextStyle(fontSize: 14, color: Colors.black87,)),
                        Text("Phone: $phone", style: const TextStyle(fontSize: 14,color: Colors.black87,)),
                        Text("Email: ${user?.email ?? "No Email"}", style: const TextStyle(fontSize: 14,color: Colors.black87,)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<int>(
                    value: 1,
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Logout"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!;
          String bloodType = userData['bloodType'] ?? 'Unknown';
          String userName = userData['name'] ?? 'User'; // Fetch the user's name

          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' Hello, $userName!\n        Welcome to BloodConnect!',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Connecting donors & recipients. Every drop counts!',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 16,
                    children: [
                      _buildHomeCard(
                        icon: Icons.bloodtype_rounded,
                        title: 'Donate Blood\n$bloodType',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DonateDashboardScreen()),
                          );
                        },
                      ),
                      _buildHomeCard(
                        icon: Icons.local_hospital_rounded,
                        title: 'Request Blood',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RequestBloodScreen()),
                        ),
                      ),
                      _buildHomeCard(icon: Icons.event, title: 'Blood Drives', onTap: ()=> Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BloodDriveAppScreen()),
                      ),
                      ),
                      _buildHomeCard(icon: Icons.location_on_rounded, title: 'Nearby Blood Banks', onTap: ()=> Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NearbyBloodScreen()),
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => RequestBloodScreen()));
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Request Blood", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHomeCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        shadowColor: Colors.black54,
        color: Colors.white.withOpacity(0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
