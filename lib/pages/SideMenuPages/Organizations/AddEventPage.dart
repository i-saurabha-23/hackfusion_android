import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEventPage extends StatefulWidget {
  final String organizationId;

  const AddEventPage({Key? key, required this.organizationId}) : super(key: key);

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTimeRange? _selectedDates;
  List<Map<String, dynamic>> _scheduleRows = [];
  List<Map<String, dynamic>> _budgetRows = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
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

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _animationController.dispose();

    // Dispose budget row controllers
    for (var row in _budgetRows) {
      (row['amountController'] as TextEditingController).dispose();
      (row['descriptionController'] as TextEditingController).dispose();
    }

    super.dispose();
  }

  // [All existing methods remain the same: _selectEventDates, _addScheduleRow, _addBudgetRow, _submitEvent]
  // Copy the existing implementations from the previous code

  @override
  Widget build(BuildContext context) {
    // Calculate the number of days in the selected date range
    final List<DateTime> days = _selectedDates == null
        ? []
        : List.generate(
      _selectedDates!.end.difference(_selectedDates!.start).inDays + 1,
          (index) => _selectedDates!.start.add(Duration(days: index)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Create New Event",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () => _selectEventDates(context),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Event Name Input
                  _buildAnimatedInputField(
                    controller: _eventNameController,
                    labelText: "Event Name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter event name";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Event Description Input
                  _buildAnimatedInputField(
                    controller: _eventDescriptionController,
                    labelText: "Event Description",
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter event description";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
                  _buildDateSelectionTile(),

                  const SizedBox(height: 16),

                  // Event Schedule Section
                  _buildEventScheduleSection(days),

                  // Budget Section
                  _buildBudgetSection(),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            validator: validator,
          ),
        );
      },
    );
  }

  Widget _buildDateSelectionTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        title: const Text(
          "Event Dates",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: _selectedDates == null
            ? const Text(
          "No dates selected",
          style: TextStyle(color: Colors.grey),
        )
            : Text(
          "${_selectedDates!.start.toLocal()} - ${_selectedDates!.end.toLocal()}",
          style: const TextStyle(color: Colors.black87),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.black),
          onPressed: () => _selectEventDates(context),
        ),
      ),
    );
  }

  Widget _buildEventScheduleSection(List<DateTime> days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Event Schedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        const Divider(color: Colors.black),

        if (days.isNotEmpty)
          for (var i = 0; i < days.length; i++)
            _buildDayScheduleSection(i, days[i]),
      ],
    );
  }

  Widget _buildDayScheduleSection(int index, DateTime day) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Day ${index + 1} (${day.toLocal()})",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Existing schedule rows implementation remains the same
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scheduleRows.where((row) => row['day'] == index + 1).length,
            itemBuilder: (context, rowIndex) {
              var row = _scheduleRows.where((row) => row['day'] == index + 1).toList()[rowIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          row['time'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Activity",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          row['activity'] = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () => _addScheduleRow(index + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Add Schedule Row",style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Event Budget",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        const Divider(color: Colors.black),

        // Budget rows remain the same as in the original implementation
        ..._budgetRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextFormField(
                      controller: row['amountController'],
                      decoration: InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          row['amount'] = value;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextFormField(
                      controller: row['descriptionController'],
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          row['description'] = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => _addBudgetRow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Add Budget Row",style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () => _submitEvent(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Create Event",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
      ),
    );
  }

  // Existing methods (_selectEventDates, _addScheduleRow, _addBudgetRow, _submitEvent)
  // should be copied from the original implementation
  Future<void> _selectEventDates(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDates,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDates) {
      setState(() {
        _selectedDates = picked;
      });
    }
  }

  void _addScheduleRow(int day) {
    setState(() {
      _scheduleRows.add({'day': day, 'time': '', 'activity': ''});
    });
  }

  void _addBudgetRow() {
    setState(() {
      _budgetRows.add({
        'amount': '',
        'description': '',
        'amountController': TextEditingController(),
        'descriptionController': TextEditingController(),
      });
    });
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        String currentOrganizationId = widget.organizationId;

        DocumentReference eventDocRef = FirebaseFirestore.instance
            .collection('Organization')
            .doc(currentOrganizationId)
            .collection('Events-Funds-Request')
            .doc(_eventNameController.text);

        // Prepare event data
        Map<String, dynamic> eventData = {
          'eventName': _eventNameController.text,
          'eventDescription': _eventDescriptionController.text,
          'status': 'Pending',
          'eventDates': {
            'start': _selectedDates?.start.toIso8601String(),
            'end': _selectedDates?.end.toIso8601String(),
          },
          'schedule': _scheduleRows,
          'budget': _budgetRows.map((row) {
            return {
              'amount': row['amount'],
              'description': row['description'],
            };
          }).toList(),
        };

        // Save event data to Firestore
        await eventDocRef.set(eventData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event successfully added!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back to previous screen
        Navigator.of(context).pop();
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}