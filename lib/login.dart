import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isLoading = false;
  bool _isSignUp = false;
  String _selectedBloodType = 'A+'; // Default blood type selection

  // Function to save user data in Firestore
  Future<void> saveUserData(User user, String bloodType) async {
    String? token = await _firebaseMessaging.getToken();
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': user.email,
      'bloodType': bloodType,
      'fcmToken': token,
      'pointsEarned': 0,
      'createdAt': Timestamp.now(),
    });
  }

  // Authentication logic
  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // Sign up user
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          await saveUserData(user, _selectedBloodType);
        }
      } else {
        // Sign in user
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Update FCM token for existing user
        User? user = userCredential.user;
        if (user != null) {
          String? token = await _firebaseMessaging.getToken();
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_isSignUp ? 'Signup' : 'Login'} Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50, // Light red background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 80),
              const SizedBox(height: 10),
              Text(
                _isSignUp ? 'Create an Account' : 'Blood Donation App',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 30),

              // Show name, phone, and blood type selection only for sign-up
              if (_isSignUp) ...[
                _buildTextField(nameController, 'Full Name', Icons.person, false),
                const SizedBox(height: 15),
                _buildTextField(phoneController, 'Phone Number', Icons.phone, false),
                const SizedBox(height: 15),

                // Blood type selection
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                      .map((bloodType) => DropdownMenuItem(
                    value: bloodType,
                    child: Text(bloodType),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodType = value!;
                    });
                  },
                ),
                const SizedBox(height: 15),
              ],

              _buildTextField(emailController, 'Email', Icons.email, false),
              const SizedBox(height: 15),
              _buildTextField(passwordController, 'Password', Icons.lock, true),
              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.red)
                  : ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _isSignUp ? 'Sign Up' : 'Login',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),

              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Already have an account? Login' : 'Don’t have an account? Sign up',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: hint == 'Phone Number' ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.red),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
