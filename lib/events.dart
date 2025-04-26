import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(BloodDriveAppScreen());
}

class BloodDriveAppScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital & Blood Drive Events',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: EventsPage(),
    );
  }
}

// Events Page
class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> futureEvents;

  @override
  void initState() {
    super.initState();
    futureEvents = fetchEvents();
  }

  Future<List<Event>> fetchEvents() async {
    const String apiKey = "NTI6OL2PAPHEVKWNIK2C"; // Replace with your actual API key
    const String url = "https://www.eventbriteapi.com/v3/events/search/"
        "?q=hospital+blood+donation"
        "&location.address=Kenya"
        "&categories=113"
        "&token=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List jsonResponse = data['events'];

      
      return Future.wait(jsonResponse.map((event) async {
        String location = await fetchVenue(event['venue_id'], apiKey);
        return Event.fromJson(event, location);
      }).toList());
    } else {
      throw Exception('Failed to load events: ${response.body}');
    }
  }

  Future<String> fetchVenue(String venueId, String apiKey) async {
    final Uri venueUrl = Uri.parse("https://www.eventbriteapi.com/v3/venues/$venueId/?token=$apiKey");

    final venueResponse = await http.get(venueUrl);
    if (venueResponse.statusCode == 200) {
      final venueData = json.decode(venueResponse.body);
      return venueData['address']['city'] ?? "Location Not Specified";
    } else {
      return "Location Not Specified";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital & Blood Drive Events'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<Event>>(
        future: futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No upcoming events found.'));
          }

          List<Event> events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              Event event = events[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.event, color: Colors.redAccent),
                  title: Text(
                    event.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${DateFormat.yMMMMd().format(event.date)}\n${event.location}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Event Model
class Event {
  final String title;
  final DateTime date;
  final String location;
  final String description;

  Event({
    required this.title,
    required this.date,
    required this.location,
    required this.description,
  });

  factory Event.fromJson(Map<String, dynamic> json, String location) {
    return Event(
      title: json['name']['text'] ?? 'No Title',
      date: DateTime.parse(json['start']['utc']),
      location: location,
      description: json['description']['text'] ?? 'No Description',
    );
  }
}
