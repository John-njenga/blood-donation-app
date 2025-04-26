import 'package:bloodconnect/firebase_notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RequestBloodScreen extends StatefulWidget {
  @override
  _RequestBloodScreenState createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _bloodType, _patientName, _location, _urgency;
  bool _isSending = false;

  final List<String> bloodTypes = [
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
  ];

  void _sendRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSending = true);

      try {
        // Save request to Firestore
        DocumentReference requestRef =
        await FirebaseFirestore.instance.collection('bloodRequests').add({
          'bloodType': _bloodType,
          'patientName': _patientName,
          'location': _location,
          'urgency': _urgency,
          'timestamp': Timestamp.now(),
          'isRead': false,
        });

        // Find matching donors
        QuerySnapshot donorSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('bloodType', isEqualTo: _bloodType)
            .get();

        // Send notifications to matching donors
        List<String> tokens = donorSnapshot.docs
            .map((doc) => doc['fcmToken'] as String)
            .where((token) => token.isNotEmpty)
            .toList();

        await _sendNotifications(tokens);

        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request Sent Successfully!")),
        );

        Navigator.pop(context); // Go back to HomeScreen
      } catch (e) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _sendNotifications(List<String> tokens) async {
    for (String token in tokens) {
      await FirebaseNotificationHelper.sendNotification(
          [token],
          "Urgent Blood Request!",
          "A $_bloodType blood request is needed for $_patientName at $_location. Please help if you can!"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Blood',
          style: TextStyle(color: Colors.white),  // Set the text color to white
        ),
        backgroundColor: Colors.red,
        elevation: 0,// Set the background color to red
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField("Patient Name", "Enter patient's name", (value) => _patientName = value),
                SizedBox(height: 16),
                _buildDropdownField("Required Blood Type", "Select blood type", bloodTypes, (value) => _bloodType = value),
                SizedBox(height: 16),
                _buildTextField("Location", "Enter location", (value) => _location = value),
                SizedBox(height: 16),
                _buildDropdownField("Urgency Level", "Select urgency level", ["Low", "Medium", "High"], (value) => _urgency = value),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSending
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Send Request", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String validationMessage, Function(String?) onSaved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: validationMessage,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onSaved: onSaved,
          validator: (value) => value!.isEmpty ? validationMessage : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String validationMessage, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          items: items
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? validationMessage : null,
        ),
      ],
    );
  }
}
