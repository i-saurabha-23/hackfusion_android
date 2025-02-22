import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatefulWidget {
  final String organizationId;
  final String eventId;

  const EventDetailsPage({
    Key? key,
    required this.organizationId,
    required this.eventId
  }) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Organization')
          .doc(widget.organizationId)
          .collection('Events-Funds-Request')
          .doc(widget.eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        } else if (snapshot.hasError) {
          return _buildErrorScreen();
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildNoEventScreen();
        } else {
          var event = snapshot.data!.data() as Map<String, dynamic>;
          return _buildEventDetailsScreen(event);
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please try again later',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEventScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'Event Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The event you are looking for does not exist',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsScreen(Map<String, dynamic> event) {
    // Date formatting
    var dateFormat = DateFormat('MMM dd, yyyy');
    DateTime startDate = DateTime.parse(event['eventDates']['start']);
    DateTime endDate = DateTime.parse(event['eventDates']['end']);
    String startFormatted = dateFormat.format(startDate);
    String endFormatted = dateFormat.format(endDate);

    // Event data
    List eventSchedule = event['schedule'] ?? [];
    List eventBudget = event['budget'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          event['eventName'] ?? 'Event Details',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Details Section
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Event Details'),
                        const SizedBox(height: 10),
                        _buildDetailRow('Event Name', event['eventName'] ?? 'N/A'),
                        _buildDetailRow('Description', event['eventDescription'] ?? 'N/A'),
                        _buildDetailRow('Start Date', startFormatted),
                        _buildDetailRow('End Date', endFormatted),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Event Schedule Section
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Event Schedule'),
                        const SizedBox(height: 10),
                        if (eventSchedule.isNotEmpty)
                          _buildEventSchedule(eventSchedule)
                        else
                          const Text(
                            'No schedule available',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Event Budget Section
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Event Budget'),
                        const SizedBox(height: 10),
                        if (eventBudget.isNotEmpty)
                          _buildEventBudget(eventBudget)
                        else
                          const Text(
                            'No budget available',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
      scheduleWidgets.add(const SizedBox(height: 10));
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