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

  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Format date method
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Show booking details method
  void _showBookingDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Booking Header
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.black, size: 30),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['facility'] ?? 'Booking Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Booking Information
                  _buildDetailRow('Category', data['category'] ?? 'N/A'),
                  _buildDetailRow('Facility', data['facility'] ?? 'N/A'),
                  _buildDetailRow('Time Slot', data['timeSlot'] ?? 'N/A'),
                  _buildDetailRow('Booking Date', _formatDate(data['date'] ?? '')),
                  _buildDetailRow('Status', data['status'] ?? 'N/A'),

                  // User Information
                  SizedBox(height: 20),
                  Text(
                    'User Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Divider(),
                  _buildDetailRow('Name', data['userName'] ?? 'N/A'),
                  _buildDetailRow('Email', data['userEmail'] ?? 'N/A'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.black,
            title: Text(
              'Facility Bookings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('SHOW-ALL')
              .doc('CAMPUS-BOOKINGS')
              .collection('DATA')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 100, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No Bookings Found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Filter bookings
            var filteredDocs = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;

              bool searchMatch = _searchQuery.isEmpty ||
                  (data['facility']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                  (data['userName']?.toString().toLowerCase().contains(_searchQuery) ?? false) ||
                  (data['userEmail']?.toString().toLowerCase().contains(_searchQuery) ?? false);

              return searchMatch;
            }).toList();

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                var data = filteredDocs[index].data() as Map<String, dynamic>;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    title: Text(
                      data['facility'] ?? 'Unknown Facility',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Unknown User',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text("Booked Slot  "+
                          data['timeSlot'] ?? '',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          _formatDate(data['date'] ?? ''),
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        data['status'] ?? 'N/A',
                        style: TextStyle(
                          color: _getStatusColor(data['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => _showBookingDetails(data),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Status color method
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}