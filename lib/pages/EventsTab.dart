import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion_android/pages/AddEventPage.dart';
import 'package:hackfusion_android/pages/EventDetailsPage.dart'; // Import your event details page
import 'package:intl/intl.dart'; // Importing the intl package for date formatting

class EventsTab extends StatelessWidget {
  final String organizationId; // Accept organizationId as parameter

  const EventsTab({super.key, required this.organizationId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Organization')
          .doc(organizationId)
          .collection('Events-Funds-Request') // Assuming Events is a sub-collection of Organization
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading events'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events available'));
        } else {
          var events = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();

          // DateFormat to format the dates
          var dateFormat = DateFormat('yyyy-MM-dd');

          return Scaffold(
            backgroundColor: Colors.white,
            body: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                var event = events[index];
                // Parse the start and end dates from the event data
                DateTime startDate = DateTime.parse(event['eventDates']['start']);
                DateTime endDate = DateTime.parse(event['eventDates']['end']);

                // Format the dates using DateFormat
                String startFormatted = dateFormat.format(startDate);
                String endFormatted = dateFormat.format(endDate);

                // Use doc.id to get the event's document ID
                var eventId = snapshot.data!.docs[index].id;

                return Card(
                  margin: const EdgeInsets.all(15.0),
                  elevation: 4,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to the Event Details Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsPage(
                            organizationId: organizationId,
                            eventId: eventId, // Pass the event id
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(event['eventName'] ?? 'Unnamed Event'),
                      subtitle: Text(
                        'Approval Status: ${event['status'] ?? 'No status available'}\n'
                            'Start Date: $startFormatted\n'
                            'End Date: $endFormatted',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Navigate to the Add Event Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEventPage(organizationId: organizationId),
                  ),
                );
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }
      },
    );
  }
}
