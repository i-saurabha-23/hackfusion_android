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
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget('Error loading events');
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyStateWidget(context);
          }

          var events = snapshot.data!.docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id
            };
          }).toList();

          return _buildEventsList(events);
        },
      ),
      floatingActionButton: _buildAddEventButton(context),
    );
  }

  Widget _buildEventsList(List<Map<String, dynamic>> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        var event = events[index];
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    DateTime startDate = DateTime.parse(event['eventDates']['start']);
    DateTime endDate = DateTime.parse(event['eventDates']['end']);

    String startFormatted = dateFormat.format(startDate);
    String endFormatted = dateFormat.format(endDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(
              organizationId: organizationId,
              eventId: event['id'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Event= "+event['eventName'] ?? 'Unnamed Event',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildEventDetailRow(
                icon: Icons.info_outline,
                text: 'Status: ${event['status'] ?? 'Pending'}',
              ),
              _buildEventDetailRow(
                icon: Icons.calendar_today,
                text: 'From: $startFormatted',
              ),
              _buildEventDetailRow(
                icon: Icons.calendar_today,
                text: 'To: $endFormatted',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEventButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEventPage(organizationId: organizationId),
          ),
        );
      },
      backgroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_events.png', // Add a suitable empty state image
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first event',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}