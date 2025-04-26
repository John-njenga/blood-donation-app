import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donationdashboard.dart';

class DonateBloodFormScreen extends StatefulWidget {
  @override
  _DonateBloodFormScreenState createState() => _DonateBloodFormScreenState();
}

class _DonateBloodFormScreenState extends State<DonateBloodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _nextController = TextEditingController();
  final TextEditingController _nextphoneController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  bool _isSubmitting = false;
  String _verificationCode = "";

  @override
  void initState() {
    super.initState();
    _generateVerificationCode();
    _fetchUserBloodType();
  }

  void _generateVerificationCode() {
    setState(() {
      _verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    });
  }

  void _fetchUserBloodType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _bloodTypeController.text = userDoc['bloodType'] ?? "Not Available";
        });
      }
    }
  }

  void _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Donation"),
          content: Text("Are you sure you want to submit this donation?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User clicks 'No'
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User clicks 'Yes'
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isSubmitting = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('bloodDonations').add({
        'donorId': user.uid,
        'username': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'bloodType': _bloodTypeController.text,
        'NextKin': _nextController.text.trim(),
        'Nextphone': _nextphoneController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'date': Timestamp.now(),
        'pointsEarned': 10,
        'verificationCode': _verificationCode,
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
          {
            'pointsEarned': FieldValue.increment(10),
          });

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Donation recorded! Verification Code: $_verificationCode')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DonateDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Blood Donation Form"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_fullNameController, "Full Name", "Enter your full name", icon: Icons.person),
              SizedBox(height: 18),
              _buildTextField(_phoneController, "Phone Number", "Enter your phone number", keyboardType: TextInputType.phone, icon: Icons.phone),
              SizedBox(height: 18),
              _buildTextField(_locationController, "Location", "Enter your location", icon: Icons.location_on),
              SizedBox(height: 18),
              _buildTextField(_nextController, "Next of Kin Full Name", "Enter Next of Kin Full name", icon: Icons.person_add),
              SizedBox(height: 18),
              _buildTextField(_nextphoneController, "Next of Kin Phone Number", "Enter Next of Kin Phone number", keyboardType: TextInputType.phone, icon: Icons.phone_forwarded),
              SizedBox(height: 18),
              _buildTextField(_bloodTypeController, 'Blood Type', "Blood Type", readOnly: true, icon: Icons.bloodtype),
              SizedBox(height: 18),
              _buildTextField(_hospitalController, "Hospital Name", "Enter hospital name", icon: Icons.local_hospital),
              SizedBox(height: 20),
              Text("Verification Code: $_verificationCode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Submit Donation", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text, bool readOnly = false, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (value) => value!.isEmpty && !readOnly ? hint : null,
    );
  }
}
