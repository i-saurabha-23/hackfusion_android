import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatelessWidget {
  final String organizationId;
  final String eventId;

  const EventDetailsPage(
      {Key? key,  required this.organizationId, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Organization')
          .doc(organizationId)
          .collection('Events-Funds-Request')
          .doc(eventId) // Fetch the specific event by eventId
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading event details'));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Event not found'));
        } else {
          var event = snapshot.data!.data() as Map<String, dynamic>;

          // DateFormat to format the dates
          var dateFormat = DateFormat('yyyy-MM-dd');
          DateTime startDate = DateTime.parse(event['eventDates']['start']);
          DateTime endDate = DateTime.parse(event['eventDates']['end']);
          String startFormatted = dateFormat.format(startDate);
          String endFormatted = dateFormat.format(endDate);

          // Fetching the event schedule and event budget
          List eventSchedule = event['schedule'] ?? [];
          List eventBudget = event['budget'] ?? [];

          return Scaffold(
            appBar: AppBar(
              title: Text(event['eventName'] ?? 'Event Details'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name and Description
                    Text('Event Name: ${event['eventName'] ?? 'N/A'}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        'Event Description: ${event['eventDescription'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Start Date: $startFormatted',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('End Date: $endFormatted',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),

                    // Event Schedule Section (Using Table)
                    Text('Event Schedule:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (eventSchedule.isNotEmpty)
                      _buildEventSchedule(eventSchedule),
                    if (eventSchedule.isEmpty)
                      const Text('No schedule available',
                          style: TextStyle(fontSize: 16)),

                    const SizedBox(height: 20),

                    // Event Budget Section (Using Table)
                    Text('Event Budget:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (eventBudget.isNotEmpty) _buildEventBudget(eventBudget),
                    if (eventBudget.isEmpty)
                      const Text('No budget available',
                          style: TextStyle(fontSize: 16)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // Helper function to build the event schedule section using Table
  Widget _buildEventSchedule(List schedule) {
    // Group schedule by day
    Map<int, List<Map<String, dynamic>>> groupedByDay = {};

    for (var item in schedule) {
      int day = item['day'];
      if (!groupedByDay.containsKey(day)) {
        groupedByDay[day] = [];
      }
      groupedByDay[day]?.add(item);
    }

    // Create schedule table for each day
    List<Widget> scheduleWidgets = [];
    groupedByDay.forEach((day, events) {
      scheduleWidgets.add(
        Text('Day $day',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
      scheduleWidgets.add(const SizedBox(height: 10));

      scheduleWidgets.add(
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FlexColumnWidth(2), // Time column width
            1: FlexColumnWidth(3), // Activity column width
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.green.shade100),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Activity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Loop through each schedule entry for the day
            ...events.map((item) {
              return TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item['time'] ?? 'N/A'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item['activity'] ?? 'N/A'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      );
    });

    return Column(children: scheduleWidgets);
  }

  // Helper function to build the event budget section using Table
  Widget _buildEventBudget(List budget) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2), // Amount column width
        1: FlexColumnWidth(3), // Description column width
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.green.shade100),
          children: const [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        // Loop through each budget entry
        ...budget.map((item) {
          return TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item['amount'] ?? 'N/A'),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item['description'] ?? 'N/A'),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
