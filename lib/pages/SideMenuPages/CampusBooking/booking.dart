import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampusFacilityBooking extends StatefulWidget {
  const CampusFacilityBooking({Key? key}) : super(key: key);

  @override
  _CampusFacilityBookingState createState() => _CampusFacilityBookingState();
}

class _CampusFacilityBookingState extends State<CampusFacilityBooking> {
  // Comprehensive facility details
  final List<Map<String, dynamic>> facilities = [
    {
      'name': 'Football Ground',
      'category': 'Sports',
      'timeSlots': [
        '06:00-08:00', '08:00-10:00', '10:00-12:00',
        '14:00-16:00', '16:00-18:00', '18:00-20:00'
      ],
      'description': 'Professional football ground with natural grass'
    },
    {
      'name': 'Gym',
      'category': 'Fitness',
      'timeSlots': [
        '06:00-07:30', '07:30-09:00', '09:00-10:30',
        '16:00-17:30', '17:30-19:00', '19:00-20:30'
      ],
      'description': 'Fully equipped modern gymnasium'
    },
    {
      'name': 'Basketball Court',
      'category': 'Sports',
      'timeSlots': [
        '06:00-08:00', '08:00-10:00', '10:00-12:00',
        '16:00-18:00', '18:00-20:00', '20:00-22:00'
      ],
      'description': 'Indoor basketball court with professional markings'
    },
    {
      'name': 'Swimming Pool',
      'category': 'Sports',
      'timeSlots': [
        '06:00-07:30', '07:30-09:00', '09:00-10:30',
        '16:00-17:30', '17:30-19:00', '19:00-20:30'
      ],
      'description': 'Olympic-sized swimming pool with professional lanes'
    },
    {
      'name': 'Conference Hall',
      'category': 'Meeting',
      'timeSlots': [
        '08:00-10:00', '10:00-12:00', '13:00-15:00',
        '15:00-17:00', '17:00-19:00'
      ],
      'description': 'Modern conference hall with advanced facilities'
    }
  ];

  // Form Controllers
  final GlobalKey<FormState> _bookingFormKey = GlobalKey<FormState>();

  // Booking Variables
  String? selectedCategory;
  String? selectedFacility;
  String? selectedTimeSlot;
  DateTime? selectedDate;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Generate next 7 days
    nextSevenDays = List.generate(7, (index) {
      return DateTime.now().add(Duration(days: index));
    });
  }

  List<DateTime> nextSevenDays = [];

// Comprehensive Booking Submission
  Future<void> _submitBooking() async {
    // Validate form
    if (!_bookingFormKey.currentState!.validate()) {
      return;
    }

    // Check all required fields
    if (selectedCategory == null ||
        selectedFacility == null ||
        selectedTimeSlot == null ||
        selectedDate == null) {
      _showErrorDialog('Please fill all booking details');
      return;
    }

    // Get user email from UserController
    final UserController userController = Get.find();
    final String userEmail = userController.userEmail.value;

    if (userEmail.isEmpty) {
      _showErrorDialog('Please log in to make a booking');
      return;
    }

    // Check booking availability with comprehensive conflict checking
    bool isAvailable = await _checkBookingAvailability();
    if (!isAvailable) {
      _showErrorDialog('This slot is already booked. Please choose another time.');
      return;
    }

    // Prepare booking data
    Map<String, dynamic> bookingData = {
      'userEmail': userEmail,
      'category': selectedCategory,
      'facility': selectedFacility,
      'timeSlot': selectedTimeSlot,
      'date': selectedDate!.toIso8601String(),
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
      'bookingId': _generateUniqueBookingId(),
    };

    try {
      // Save booking to Firestore with comprehensive conflict prevention
      await _firestore
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKINGS')
          .collection('DATA')
          .doc(_generateUniqueBookingId())
          .set(bookingData);

      // Set isInitialized true after creating the complaint document
      await FirebaseFirestore.instance
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKINGS')
          .set({'isInitialized': true}, SetOptions(merge: true));

      // Reset form and show success
      _resetBookingForm();
      _showSuccessDialog('Booking submitted successfully!');
    } catch (e) {
      _showErrorDialog('Booking failed: ${e.toString()}');
    }
  }

  // Generate a truly unique booking ID
  String _generateUniqueBookingId() {
    return '${selectedFacility}_${DateFormat('yyyyMMdd').format(selectedDate!)}_${selectedTimeSlot?.replaceAll(':', '')}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Advanced Availability Checking
  Future<bool> _checkBookingAvailability() async {
    try {
      // Complex query to check for any conflicting bookings
      QuerySnapshot existingBookings = await _firestore
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKINGS')
          .collection('DATA')
          .where('facility', isEqualTo: selectedFacility)
          .where('date', isEqualTo: selectedDate!.toIso8601String())
          .where('timeSlot', isEqualTo: selectedTimeSlot)
          .where('status', whereNotIn: ['Cancelled', 'Rejected'])
          .get();

      return existingBookings.docs.isEmpty;
    } catch (e) {
      print('Availability check error: $e');
      return false;
    }
  }

  // Reset booking form
  void _resetBookingForm() {
    setState(() {
      selectedCategory = null;
      selectedFacility = null;
      selectedTimeSlot = null;
      selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Form(
              key: _bookingFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Modern Typography
                  Text(
                    'Book Campus Facilities',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Select your preferred facility and time slot',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Category Dropdown with Enhanced Design
                  _buildDropdownWithDecoration(
                    hint: 'Select Facility Category',
                    value: selectedCategory,
                    items: facilities
                        .map((f) => f['category'] as String)
                        .toSet()
                        .map((category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        selectedFacility = null;
                        selectedTimeSlot = null;
                        selectedDate = null;
                      });
                    },
                    icon: Icons.category_outlined,
                  ),

                  SizedBox(height: 20),

                  // Facility Dropdown (Filtered by Category)
                  if (selectedCategory != null)
                    _buildDropdownWithDecoration(
                      hint: 'Select Specific Facility',
                      value: selectedFacility,
                      items: facilities
                          .where((f) => f['category'] == selectedCategory)
                          .map((f) => DropdownMenuItem<String>(
                                value: f['name'] as String,
                                child: Text(f['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFacility = value;
                          selectedTimeSlot = null;
                          selectedDate = null;
                        });
                      },
                      icon: Icons.sports_outlined,
                    ),

                  SizedBox(height: 20),

                  // Improved Date Selection
                  if (selectedFacility != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: nextSevenDays.length,
                            itemBuilder: (context, index) {
                              DateTime date = nextSevenDays[index];
                              bool isSelected = selectedDate?.day == date.day;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDate = date;
                                    selectedTimeSlot = null;
                                  });
                                },
                                child: Container(
                                  width: 110,
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE').format(date),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        DateFormat('dd').format(date),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 20),

                  // Time Slots with Improved Design
                  if (selectedDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Time Slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: facilities
                              .firstWhere((f) => f['name'] == selectedFacility)[
                                  'timeSlots']
                              .map<Widget>((slot) {
                            bool isSelected = selectedTimeSlot == slot;
                            return ChoiceChip(
                              label: Text(
                                slot,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.black,
                              backgroundColor: Colors.grey[200],
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedTimeSlot = selected ? slot : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  SizedBox(height: 20),

                  // Book Now Button with Modern Design
                  if (selectedCategory != null &&
                      selectedFacility != null &&
                      selectedDate != null &&
                      selectedTimeSlot != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _submitBooking,
                        child: Text(
                          'Book Facility',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
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

  // Helper method for dropdown with icon and styling
  Widget _buildDropdownWithDecoration({
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
      validator: (value) => value == null ? 'Please select an option' : null,
      items: items,
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.black),
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.black87, fontSize: 16),
    );
  }

  // Input Decoration Helper
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  // Error Dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Success Dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Successful'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
