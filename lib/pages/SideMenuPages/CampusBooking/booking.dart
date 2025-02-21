import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '/auth/provider/UserAllDataProvier.dart';

class CampusBooking extends StatefulWidget {
  const CampusBooking({Key? key}) : super(key: key);

  @override
  State<CampusBooking> createState() => _CampusBookingState();
}

class _CampusBookingState extends State<CampusBooking> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  String? selectedVenue;
  String? selectedDepartment;
  String? selectedYear;
  String? selectedSection;
  DateTime? startDate;
  DateTime? endDate;

  final List<String> venues = ['Playground', 'Theater', 'Auditorium', 'Lab'];
  final List<String> departments = ['CSE', 'ECE', 'MECH', 'CIVIL'];
  final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> sections = ['A', 'B', 'C', 'D'];

  final UserController userController = Get.put(UserController());

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            startDate = DateTime(picked.year, picked.month, picked.day,
                pickedTime.hour, pickedTime.minute);
          } else {
            endDate = DateTime(picked.year, picked.month, picked.day,
                pickedTime.hour, pickedTime.minute);
          }
        });
      }
    }
  }

  // Function to format the document name
  Future<String> _generateDocumentName() async {
    String formattedStartDate =
        DateFormat("yyyy-MM-dd'T'HH:mm").format(startDate!);
    String formattedEndDate = DateFormat("yyyy-MM-dd'T'HH:mm").format(endDate!);

    return '${selectedVenue}_${formattedStartDate}_${formattedEndDate}';
  }

// Function to check if the booking already exists with overlap logic
  Future<bool> _checkIfBookingExists() async {
    try {
      // Query to check if there are any bookings for the same venue, department, year, and section
      // that overlap with the new booking's time range.
      QuerySnapshot querySnapshot = await _firestore
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKING')
          .collection('DATA')
          .where('venue', isEqualTo: selectedVenue)
          .where('department', isEqualTo: selectedDepartment)
          .where('year', isEqualTo: selectedYear)
          .where('section', isEqualTo: selectedSection)
          .get();

      // Check each booking's time range for overlap
      for (var doc in querySnapshot.docs) {
        DateTime existingStartDate = DateTime.parse(doc['startDate']);
        DateTime existingEndDate = DateTime.parse(doc['endDate']);

        // Check if the new booking's start and end date overlap with the existing ones
        if ((startDate!.isBefore(existingEndDate) &&
                endDate!.isAfter(existingStartDate)) ||
            (startDate!.isAtSameMomentAs(existingStartDate) ||
                endDate!.isAtSameMomentAs(existingEndDate))) {
          return true; // There is an overlap, so the booking cannot be made
        }
      }
      return false; // No overlap, booking can be made
    } catch (e) {
      print('Error checking booking existence: $e');
      return false;
    }
  }

  // Function to submit the booking with user info
  Future<void> _submitBooking() async {
    if (selectedVenue == null ||
        selectedDepartment == null ||
        selectedYear == null ||
        selectedSection == null ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    String userEmail = userController.userEmail.value;
    String userName = userController.userName.value;
    String userMobile = userController.userPhone.value;
    String userDept = userController.userDepartment.value;
    String userClass = userController.userYear.value;
    String userSection = userController.userSection.value;

    bool doesBookingExist = await _checkIfBookingExists();
    if (doesBookingExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Selected venue is already booked for the selected time. Please choose another time.')),
      );
      return;
    }

    Map<String, dynamic> bookingData = {
      'venue': selectedVenue,
      'department': selectedDepartment,
      'year': selectedYear,
      'section': selectedSection,
      'startDate': startDate!.toIso8601String(),
      'endDate': endDate!.toIso8601String(),
      'status': 'Pending',
      'userEmail': userEmail,
      'userName': userName,
      'userMobile': userMobile,
      'userDepartment': userDept,
      'userClass': userClass,
      'userSection': userSection,
    };

    try {
      CollectionReference showAllCollection = _firestore.collection('SHOW-ALL');
      String documentName = await _generateDocumentName();
      DocumentReference campusBookingDoc =
          showAllCollection.doc('CAMPUS-BOOKING');

      await campusBookingDoc.set({
        'initialized': true,
      }, SetOptions(merge: true));

      CollectionReference dataSubCollection =
          campusBookingDoc.collection('DATA');

      DocumentReference bookingDoc = dataSubCollection.doc(documentName);
      await bookingDoc.set(bookingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildFormField({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? dateTime,
    required bool isStart,
  }) {
    return InkWell(
      onTap: () => _selectDateTime(context, isStart),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.black),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dateTime == null
                        ? 'Select date and time'
                        : DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime),
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          dateTime == null ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final startDate = DateTime.parse(booking['startDate']);
    final endDate = DateTime.parse(booking['endDate']);
    final status = booking['status'] as String;

    Color statusColor = status.toLowerCase() == 'approved'
        ? Colors.green
        : status.toLowerCase() == 'pending'
            ? Colors.orange
            : Colors.red;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking['venue'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '${booking['department']}, ${booking['year']}, Section ${booking['section']}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd, hh:mm a').format(startDate)} - \n${DateFormat('MMM dd, hh:mm a').format(endDate)}',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildFormField(
                            label: 'Select Venue',
                            items: venues,
                            value: selectedVenue,
                            onChanged: (value) =>
                                setState(() => selectedVenue = value),
                          ),
                          _buildFormField(
                            label: 'Select Department',
                            items: departments,
                            value: selectedDepartment,
                            onChanged: (value) =>
                                setState(() => selectedDepartment = value),
                          ),
                          _buildFormField(
                            label: 'Select Year',
                            items: years,
                            value: selectedYear,
                            onChanged: (value) =>
                                setState(() => selectedYear = value),
                          ),
                          _buildFormField(
                            label: 'Select Section',
                            items: sections,
                            value: selectedSection,
                            onChanged: (value) =>
                                setState(() => selectedSection = value),
                          ),
                          SizedBox(height: 8),
                          _buildDateTimePicker(
                            label: 'Start Date & Time',
                            dateTime: startDate,
                            isStart: true,
                          ),
                          _buildDateTimePicker(
                            label: 'End Date & Time',
                            dateTime: endDate,
                            isStart: false,
                          ),
                          SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _submitBooking();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Submit Booking Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('SHOW-ALL')
                        .doc('CAMPUS-BOOKING')
                        .collection('DATA')
                        .where('userEmail',
                            isEqualTo: userController.userEmail.value)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading bookings',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No bookings found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final bookings = snapshot.data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();

                      return Column(
                        children: bookings
                            .map((booking) => _buildBookingCard(booking))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Keep the existing helper methods (_selectDateTime, _generateDocumentName, _checkIfBookingExists, _submitBooking)
}
