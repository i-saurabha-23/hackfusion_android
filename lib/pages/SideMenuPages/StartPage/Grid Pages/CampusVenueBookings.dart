import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CampusVenueBookings extends StatefulWidget {
  const CampusVenueBookings({Key? key}) : super(key: key);

  @override
  State<CampusVenueBookings> createState() => _CampusVenueBookingsState();
}

class _CampusVenueBookingsState extends State<CampusVenueBookings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to build a row for a detail.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date strings.
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Show details in a dialog.
  void _showBookingDetails(Map<String, dynamic> data) {
    String formattedStartDate = _formatDate(data['startDate'] ?? '');
    String formattedEndDate = _formatDate(data['endDate'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['venue'] ?? 'Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Department", data['department'] ?? ''),
                _buildInfoRow("Year", data['year'] ?? ''),
                _buildInfoRow("Section", data['section'] ?? ''),
                _buildInfoRow("Start Date", formattedStartDate),
                _buildInfoRow("End Date", formattedEndDate),
                _buildInfoRow("Status", data['status'] ?? ''),
                const Divider(),
                const Text(
                  "User Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow("Name", data['userName'] ?? ''),
                _buildInfoRow("Email", data['userEmail'] ?? ''),
                _buildInfoRow("Mobile", data['userMobile'] ?? ''),
                _buildInfoRow("User Dept", data['userDepartment'] ?? ''),
                _buildInfoRow("User Class", data['userClass'] ?? ''),
                _buildInfoRow("User Section", data['userSection'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Campus Venue Bookings",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 2,
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("SHOW-ALL")
            .doc("CAMPUS-BOOKING")
            .collection("DATA")
            .where("status", isEqualTo: "Approved")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No approved bookings found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              String formattedStartDate = _formatDate(data['startDate'] ?? '');
              String formattedEndDate = _formatDate(data['endDate'] ?? '');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    _showBookingDetails(data);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with venue name
                        Text(
                          data['venue'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Divider(height: 24),
                        // A few key details
                        _buildInfoRow("Department", data['department'] ?? ''),
                        _buildInfoRow("Year", data['year'] ?? ''),
                        _buildInfoRow("Section", data['section'] ?? ''),
                        _buildInfoRow("Start Date", formattedStartDate),
                        _buildInfoRow("End Date", formattedEndDate),
                        _buildInfoRow("Status", data['status'] ?? ''),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
