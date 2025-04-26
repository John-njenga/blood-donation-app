import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'donatebloodformscreen.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Donate Blood", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get user's blood type
          String bloodType = userSnapshot.data!['bloodType'] ?? 'Unknown';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bloodRequests')
                .where('bloodType', isEqualTo: bloodType)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No blood donation requests at the moment."),
                );
              }

              var requests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  var request = requests[index];
                  String requesterName = request['patientName'] ?? 'Unknown';
                  String hospital = request['location'] ?? 'Unknown Hospital';
                  String bloodType = request['bloodType'] ?? 'Unknown';
                  String urgency = request['urgency'] ?? 'Unknown';
                  String requestId = request.id; // Document ID

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    child: ListTile(
                      title: Text("Patient: $requesterName", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(" Hospital: $hospital\n Blood Type: $bloodType\n Urgency:$urgency"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DonateBloodFormScreen()),
                          );

                          // This should be inside onPressed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("You accepted to donate blood!")),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text("Accept", style: TextStyle(color: Colors.white)),
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
}
