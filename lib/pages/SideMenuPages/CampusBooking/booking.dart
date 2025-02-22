import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/auth/provider/UserAllDataProvier.dart';
import 'package:intl/intl.dart';

class CampusFacilityBooking extends StatefulWidget {
  const CampusFacilityBooking({Key? key}) : super(key: key);

  @override
  _CampusFacilityBookingState createState() => _CampusFacilityBookingState();
}

class _CampusFacilityBookingState extends State<CampusFacilityBooking> {
  final List<Map<String, dynamic>> facilities = [
    {
      'name': 'Football Ground',
      'category': 'Sports',
      'timeSlots': [
        '06:00-08:00',
        '08:00-10:00',
        '10:00-12:00',
        '14:00-16:00',
        '16:00-18:00',
        '18:00-20:00'
      ],
      'description': 'Professional football ground with natural grass',
      'maxCapacity': 1,
      'allowMultiple': false,
      'defaultMaxCap': 1
    },
    {
      'name': 'Gym',
      'category': 'Fitness',
      'timeSlots': [
        '06:00-07:30',
        '07:30-09:00',
        '09:00-10:30',
        '16:00-17:30',
        '17:30-19:00',
        '19:00-20:30'
      ],
      'description': 'Fully equipped modern gymnasium',
      'maxCapacity': 20,
      'allowMultiple': true,
      'defaultMaxCap': 20
    },
    {
      'name': 'Hospital',
      'category': 'Medical',
      'timeSlots': [
        '08:00-09:00',
        '09:00-10:00',
        '10:00-11:00',
        '11:00-12:00',
        '14:00-15:00',
        '15:00-16:00',
        '16:00-17:00'
      ],
      'description': 'Campus medical facility',
      'maxCapacity': 6,
      'allowMultiple': true,
      'defaultMaxCap': 6
    },
    {
      'name': 'Basketball Court',
      'category': 'Sports',
      'timeSlots': [
        '06:00-08:00',
        '08:00-10:00',
        '10:00-12:00',
        '16:00-18:00',
        '18:00-20:00',
        '20:00-22:00'
      ],
      'description': 'Indoor basketball court with professional markings',
      'maxCapacity': 1,
      'allowMultiple': false,
      'defaultMaxCap': 1
    },
    {
      'name': 'Swimming Pool',
      'category': 'Sports',
      'timeSlots': [
        '06:00-07:30',
        '07:30-09:00',
        '09:00-10:30',
        '16:00-17:30',
        '17:30-19:00',
        '19:00-20:30'
      ],
      'description': 'Olympic-sized swimming pool with professional lanes',
      'maxCapacity': 1,
      'allowMultiple': false,
      'defaultMaxCap': 1
    },
    {
      'name': 'Conference Hall',
      'category': 'Meeting',
      'timeSlots': [
        '08:00-10:00',
        '10:00-12:00',
        '13:00-15:00',
        '15:00-17:00',
        '17:00-19:00'
      ],
      'description': 'Modern conference hall with advanced facilities',
      'maxCapacity': 1,
      'allowMultiple': false,
      'defaultMaxCap': 1
    }
  ];

  final GlobalKey<FormState> _bookingFormKey = GlobalKey<FormState>();
  String? selectedCategory;
  String? selectedFacility;
  String? selectedTimeSlot;
  DateTime? selectedDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late List<DateTime> nextSevenDays;

  @override
  void initState() {
    super.initState();
    nextSevenDays = List.generate(7, (index) {
      return DateTime.now().add(Duration(days: index));
    });
  }

  Stream<Map<String, dynamic>> _getBookingsStream() {
    return _firestore
        .collection('SHOW-ALL')
        .doc('CAMPUS-BOOKINGS')
        .collection('DATA')
        .where('status', whereNotIn: ['Cancelled', 'Rejected'])
        .snapshots()
        .map((snapshot) {
          Map<DateTime, Map<String, Map<String, dynamic>>> availabilityMap = {};

          for (var doc in snapshot.docs) {
            DateTime bookingDate = DateTime.parse(doc['date']);
            String facility = doc['facility'];
            String timeSlot = doc['timeSlot'];

            if (nextSevenDays.any((day) =>
                day.year == bookingDate.year &&
                day.month == bookingDate.month &&
                day.day == bookingDate.day)) {
              if (!availabilityMap.containsKey(bookingDate)) {
                availabilityMap[bookingDate] = {};
              }
              if (!availabilityMap[bookingDate]!.containsKey(facility)) {
                availabilityMap[bookingDate]![facility] = {};
              }
              if (!availabilityMap[bookingDate]![facility]!
                  .containsKey(timeSlot)) {
                var facilityData =
                    facilities.firstWhere((f) => f['name'] == facility);
                availabilityMap[bookingDate]![facility]![timeSlot] = {
                  'count': 0,
                  'maxCap': facilityData['defaultMaxCap']
                };
              }

              availabilityMap[bookingDate]![facility]![timeSlot]['count'] =
                  (availabilityMap[bookingDate]![facility]![timeSlot]
                              ['count'] ??
                          0) +
                      1;
            }
          }

          return {
            'bookings': availabilityMap,
          };
        });
  }

  bool _isSlotAvailable(
    Map<DateTime, Map<String, Map<String, dynamic>>> bookingsMap,
    DateTime date,
    String facility,
    String timeSlot,
  ) {
    var facilityData = facilities.firstWhere((f) => f['name'] == facility);
    int defaultMaxCap = facilityData['defaultMaxCap'] as int;
    int currentBookings =
        bookingsMap[date]?[facility]?[timeSlot]?['count'] ?? 0;
    return currentBookings < defaultMaxCap;
  }

  Future<void> _submitBooking() async {
    if (!_bookingFormKey.currentState!.validate()) {
      return;
    }

    if (selectedCategory == null ||
        selectedFacility == null ||
        selectedTimeSlot == null ||
        selectedDate == null) {
      _showErrorDialog('Please fill all booking details');
      return;
    }

    var facilityData =
        facilities.firstWhere((f) => f['name'] == selectedFacility);
    int defaultMaxCap = facilityData['defaultMaxCap'] as int;

    var bookingsSnapshot = await _firestore
        .collection('SHOW-ALL')
        .doc('CAMPUS-BOOKINGS')
        .collection('DATA')
        .where('date', isEqualTo: selectedDate!.toIso8601String())
        .where('facility', isEqualTo: selectedFacility)
        .where('timeSlot', isEqualTo: selectedTimeSlot)
        .where('status', whereNotIn: ['Cancelled', 'Rejected']).get();

    if (bookingsSnapshot.docs.length >= defaultMaxCap) {
      _showErrorDialog('This slot has reached maximum capacity');
      return;
    }

    final UserController userController = Get.find();
    final String userEmail = userController.userEmail.value;
    final String userName = userController.userName.value;

    if (userEmail.isEmpty) {
      _showErrorDialog('Please log in to make a booking');
      return;
    }

    String bookingId = _generateUniqueBookingId();
    Map<String, dynamic> bookingData = {
      'userEmail': userEmail,
      'userName': userName,
      'category': selectedCategory,
      'facility': selectedFacility,
      'timeSlot': selectedTimeSlot,
      'date': selectedDate!.toIso8601String(),
      'status': 'Approved',
      'timestamp': FieldValue.serverTimestamp(),
      'bookingId': bookingId,
      'maxCap': defaultMaxCap,
      'currentCount': bookingsSnapshot.docs.length + 1
    };

    try {
      await _firestore
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKINGS')
          .collection('DATA')
          .doc(bookingId)
          .set(bookingData);

      await _firestore
          .collection('SHOW-ALL')
          .doc('CAMPUS-BOOKINGS')
          .set({'isInitialized': true}, SetOptions(merge: true));

      _resetBookingForm();
      _showSuccessDialog('Booking submitted successfully!');
    } catch (e) {
      _showErrorDialog('Booking failed: ${e.toString()}');
    }
  }

  String _generateUniqueBookingId() {
    return '${selectedFacility}_${DateFormat('yyyyMMdd').format(selectedDate!)}_${selectedTimeSlot?.replaceAll(':', '')}_${DateTime.now().millisecondsSinceEpoch}';
  }

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
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _getBookingsStream(),
          builder: (context, availabilitySnapshot) {
            if (!availabilitySnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            Map<DateTime, Map<String, Map<String, dynamic>>> bookingsMap =
                availabilitySnapshot.data!['bookings']
                    as Map<DateTime, Map<String, Map<String, dynamic>>>;

            return SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Form(
                  key: _bookingFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      if (selectedCategory != null)
                        _buildDropdownWithDecoration(
                          hint: 'Select Specific Facility',
                          value: selectedFacility,
                          items: facilities
                              .where((f) => f['category'] == selectedCategory)
                              .map((f) => DropdownMenuItem<String>(
                                    value: f['name'] as String,
                                    child: Row(
                                      children: [
                                        Text(f['name'] as String),
                                        Text(
                                          ' (Max: ${f['defaultMaxCap']})',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                  var facilityData = facilities.firstWhere(
                                      (f) => f['name'] == selectedFacility);

                                  bool isFullyBooked =
                                      facilityData['timeSlots'].every((slot) {
                                    int currentBookings = bookingsMap[date]
                                                ?[selectedFacility]?[slot]
                                            ?['count'] ??
                                        0;
                                    return currentBookings >=
                                        facilityData['defaultMaxCap'];
                                  });

                                  bool isSelected =
                                      selectedDate?.day == date.day;

                                  return GestureDetector(
                                    onTap: isFullyBooked
                                        ? null
                                        : () {
                                            setState(() {
                                              selectedDate = date;
                                              selectedTimeSlot = null;
                                            });
                                          },
                                    child: Container(
                                      width: 110,
                                      margin: EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: isFullyBooked
                                            ? Colors.red.withOpacity(0.2)
                                            : (isSelected
                                                ? Colors.black
                                                : Colors.grey[200]),
                                        borderRadius: BorderRadius.circular(15),
                                        border: isFullyBooked
                                            ? Border.all(
                                                color: Colors.red, width: 2)
                                            : null,
                                        boxShadow: isSelected && !isFullyBooked
                                            ? [
                                                BoxShadow(
                                                  color: Colors.blue
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('EEE').format(date),
                                            style: TextStyle(
                                              color: isFullyBooked
                                                  ? Colors.red
                                                  : (isSelected
                                                      ? Colors.white
                                                      : Colors.black87),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            DateFormat('dd').format(date),
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isFullyBooked
                                                  ? Colors.red
                                                  : (isSelected
                                                      ? Colors.white
                                                      : Colors.black87),
                                            ),
                                          ),
                                          if (isFullyBooked)
                                            Text(
                                              'Fully Booked',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
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
                      if (selectedDate != null && selectedFacility != null)
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
                                  .firstWhere((f) =>
                                      f['name'] ==
                                      selectedFacility)['timeSlots']
                                  .map<Widget>((slot) {
                                var facilityData = facilities.firstWhere(
                                    (f) => f['name'] == selectedFacility);
                                int defaultMaxCap =
                                    facilityData['defaultMaxCap'] as int;
                                var slotData = bookingsMap[selectedDate]
                                    ?[selectedFacility]?[slot];
                                int currentCount = slotData?['count'] ?? 0;
                                bool isAvailable = currentCount < defaultMaxCap;
                                bool isSelected = selectedTimeSlot == slot;

                                return Tooltip(
                                  message: isAvailable
                                      ? 'Available: ${currentCount}/${defaultMaxCap} spots'
                                      : 'Fully Booked',
                                  child: ChoiceChip(
                                    label: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          slot,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '$currentCount/$defaultMaxCap',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    selectedColor: Colors.black,
                                    backgroundColor: isAvailable
                                        ? Colors.grey[200]
                                        : Colors.red[100],
                                    onSelected: isAvailable
                                        ? (bool selected) {
                                            setState(() {
                                              selectedTimeSlot =
                                                  selected ? slot : null;
                                            });
                                          }
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      SizedBox(height: 30),
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
            );
          },
        ),
      ),
    );
  }

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

  @override
  void dispose() {
    super.dispose();
  }
}
