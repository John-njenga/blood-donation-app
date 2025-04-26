import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donate.dart';

class DonateDashboardScreen extends StatefulWidget {
  @override
  _DonateDashboardScreenState createState() => _DonateDashboardScreenState();
}

class _DonateDashboardScreenState extends State<DonateDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isDonateButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkDonationEligibility();
  }

  Future<void> _checkDonationEligibility() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot donationHistory = await FirebaseFirestore.instance
        .collection('bloodDonations')
        .where('donorId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (donationHistory.docs.isNotEmpty) {
      DateTime lastDonationDate =
      (donationHistory.docs.first['date'] as Timestamp).toDate();
      DateTime currentDate = DateTime.now();

      // Check if 30 days have passed
      if (currentDate.difference(lastDonationDate).inDays < 30) {
        setState(() {
          isDonateButtonEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background for contrast
      appBar: AppBar(
        title: Text('Donation Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.redAccent, // Thematic red for blood donation
        elevation: 0,
      ),
      body: user == null
          ? Center(
        child: Text(
          'Please log in to view your dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bloodDonations')
            .where('donorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoHistoryUI(context);
          }

// Calculate total points across all donations
          int totalPoints = snapshot.data!.docs.fold(0, (sum, doc) {
            num points = doc['pointsEarned'] ?? 0;
            return sum + points.toInt();
          });



          return Column(
            children: [
              _buildPointsCard(totalPoints),
              _buildDonationHistoryTitle(),
              _buildDonationHistoryList(snapshot),
              _buildDonateButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoHistoryUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No donation history available.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isDonateButtonEnabled
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DonateScreen()),
              );
            }
                : null,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int totalPoints) {
    return Card(
      margin: EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.redAccent, size: 40),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Points Earned',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '$totalPoints',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationHistoryTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Donation History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDonationHistoryList(AsyncSnapshot<QuerySnapshot> snapshot) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var doc = snapshot.data!.docs[index];
          DateTime date = (doc['date'] as Timestamp).toDate();

          return Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.bloodtype, color: Colors.white),
              ),
              title: Text(
                'Date: ${date.toLocal()}'.split('.')[0],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Username: ${doc['username']}',
                      style: TextStyle(color: Colors.black87)),
                  Text('Blood Type: ${doc['bloodType']}',
                      style: TextStyle(color: Colors.black87)),
                  Text('Location: ${doc['location']}',
                      style: TextStyle(color: Colors.black87)),
                  Text('Hospital: ${doc['hospital']}',
                      style: TextStyle(color: Colors.black87)),
                  Text('Verification Code: ${doc['verificationCode']}',
                      style: TextStyle(color: Colors.black87)),
                  Text('Phone: ${doc['phone']}',
                      style: TextStyle(color: Colors.black87)),
                  SizedBox(height: 6),
                  Text(
                    'Points Earned: ${doc['pointsEarned']}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonateButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: isDonateButtonEnabled
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DonateScreen()),
          );
        }
            : null, // Disable button if donation is not eligible
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Donate Blood',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDonateButtonEnabled
              ? Colors.redAccent
              : Colors.grey, // Grey out button if disabled
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: TextStyle(fontSize: 16,color:Colors.white),
        ),
      ),
    );
  }
}
