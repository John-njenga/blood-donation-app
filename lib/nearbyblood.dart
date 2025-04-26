import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyBloodScreen extends StatefulWidget {
  @override
  _NearbyBloodScreenState createState() => _NearbyBloodScreenState();
}

class _NearbyBloodScreenState extends State<NearbyBloodScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Map<String, dynamic>> _bloodBanks = [];
  final String _apiKey = "AIzaSyB517D8KUVznowtGHJam3EFRJgAPTseySw";

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in to access this feature.")),
      );
      Navigator.pop(context);
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _showLocationAlert();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return _showLocationAlert();
    }
    if (permission == LocationPermission.deniedForever) return _showLocationAlert();

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = position);
    _fetchBloodBanks();
  }

  void _showLocationAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Required"),
        content: Text("Please enable location services to find blood banks."),
        actions: [
          TextButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchBloodBanks() async {
    if (_currentPosition == null) return;

    final String url =
        "https://maps.googleapis.com/maps/api/place/textsearch/json"
        "?query=blood+bank+near+me"
        "&location=${_currentPosition!.latitude},${_currentPosition!.longitude}"
        "&radius=5000"
        "keyword= Blood + hospital"
        "&key=$_apiKey";

    try {
      print("Fetching data from: $url");  // Debug URL
      final response = await http.get(Uri.parse(url));

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] == null || (data['results'] as List).isEmpty) {
          print("No results found.");
          setState(() => _bloodBanks = []);
          return;
        }

        List<Map<String, dynamic>> bloodBanks = (data['results'] as List).map((place) {
          return {
            "name": place['name'],
            "address": place['vicinity'] ?? "Address not available",
            "lat": place['geometry']['location']['lat'],
            "lng": place['geometry']['location']['lng'],
          };
        }).toList();

        setState(() => _bloodBanks = bloodBanks);
        print("Blood Banks Found: $_bloodBanks");
      } else {
        print("Failed to fetch blood banks.");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to fetch blood banks."))
        );
      }
    } catch (e) {
      print("Error fetching data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data. Check your connection."))
      );
    }
  }


  void _openMap(double lat, double lng) async {
    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blood Banks"), backgroundColor: Colors.redAccent),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [

          Expanded(
            flex: 1,
            child: _bloodBanks.isEmpty
                ? Center(child: Text("No blood banks found."))
                : ListView.builder(
              itemCount: _bloodBanks.length,
              itemBuilder: (context, index) {
                final place = _bloodBanks[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.local_hospital, color: Colors.redAccent),
                    title: Text(place['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(place['address']),
                    trailing: IconButton(
                      icon: Icon(Icons.directions, color: Colors.blue),
                      onPressed: () => _openMap(place['lat'], place['lng']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
