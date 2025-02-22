import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'AddEventPage.dart';
import 'EventDetailsPage.dart';

class EventsTab extends StatelessWidget {
  final String organizationId;

  const EventsTab({Key? key, required this.organizationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Organization')
            .doc(organizationId)
            .collection('Events-Funds-Request')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildMessage('Error loading events');
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildMessage('No events available');
          }

          var events = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();

          var dateFormat = DateFormat('yyyy-MM-dd');

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              DateTime startDate = DateTime.parse(event['eventDates']['start']);
              DateTime endDate = DateTime.parse(event['eventDates']['end']);

              String startFormatted = dateFormat.format(startDate);
              String endFormatted = dateFormat.format(endDate);

              var eventId = snapshot.data!.docs[index].id;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(15.0),
                elevation: 4,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsPage(
                          organizationId: organizationId,
                          eventId: eventId,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddEventPage(organizationId: organizationId),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 20, color: Colors.black54),
      ),
    );
  }
}
