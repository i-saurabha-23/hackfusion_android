import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEventPage extends StatefulWidget {

  final String organizationId; // Required to get the organization details

  const AddEventPage({Key? key,

    required this.organizationId
  }) : super(key: key);

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
  TextEditingController();
  DateTimeRange? _selectedDates;
  List<Map<String, dynamic>> _scheduleRows = [
  ]; // Stores event schedule for all days
  List<Map<String, dynamic>> _budgetRows = [];

  // Method to show date picker and select event dates
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

  // Add row to Event Schedule table for a specific day
  void _addScheduleRow(int day) {
    setState(() {
      _scheduleRows.add({'day': day, 'time': '', 'activity': ''});
    });
  }

  // Method to add a budget row
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

  // Method to submit event details to Firestore
  Future<void> _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Assuming you have the current organization ID stored somewhere
        String currentOrganizationId = widget.organizationId;

        // Create event document with event name as the document ID
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
            const SnackBar(content: Text('Event successfully added!')));
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the number of days in the selected date range
    final days = _selectedDates == null
        ? []
        : List.generate(
      _selectedDates!
          .end
          .difference(_selectedDates!.start)
          .inDays + 1,
          (index) => _selectedDates!.start.add(Duration(days: index)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add Event",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.green),
            onPressed: () => _selectEventDates(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: "Event Name",
                  labelStyle: TextStyle(color: Colors.green),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green)),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter event name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventDescriptionController,
                decoration: const InputDecoration(
                  labelText: "Event Description",
                  labelStyle: TextStyle(color: Colors.green),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green)),
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter event description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Event Dates",
                    style: TextStyle(color: Colors.green)),
                subtitle: _selectedDates == null
                    ? const Text("No dates selected",
                    style: TextStyle(color: Colors.grey))
                    : Text(
                    "${_selectedDates!.start.toLocal()} - ${_selectedDates!.end
                        .toLocal()}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.green),
                  onPressed: () => _selectEventDates(context),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Event Schedule",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
              Divider(color: Colors.green),

              // Show each day in the event schedule
              if (days.isNotEmpty)
                for (var i = 0; i < days.length; i++)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Day ${i + 1} (${days[i].toLocal()})",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: _scheduleRows
                                  .where((row) => row['day'] == i + 1)
                                  .length,
                              itemBuilder: (context, index) {
                                var row = _scheduleRows
                                    .where((row) => row['day'] == i + 1)
                                    .toList()[index];
                                return Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: "Time",
                                            labelStyle: TextStyle(
                                              color: Colors.green,
                                              // Label color
                                              fontSize: 14, // Label font size
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.green,
                                                  width: 2),
                                              // Focused border color
                                              borderRadius: BorderRadius
                                                  .circular(
                                                  8), // Rounded corners
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 1),
                                              // Default border color
                                              borderRadius: BorderRadius
                                                  .circular(
                                                  8), // Rounded corners
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 1),
                                              // Error border color
                                              borderRadius: BorderRadius
                                                  .circular(
                                                  8),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red, width: 2),
                                              // Focused error border color
                                              borderRadius: BorderRadius
                                                  .circular(
                                                  8),
                                            ),
                                            contentPadding: EdgeInsets
                                                .symmetric(
                                                vertical: 12,
                                                horizontal: 16), // Padding inside the field
                                          ),
                                          onChanged: (value) {
                                            row['time'] = value;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: "Activity",
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            row['activity'] = value;
                                          },
                                        ),
                                      ),
                                    ]);
                              },
                            ),
                            ElevatedButton(
                              onPressed: () => _addScheduleRow(i + 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Button color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  // Rounded corners with 4px radius
                                  side: BorderSide(
                                      color: Colors.white,
                                      width:
                                      2), // Rectangle border with white color and 2px width
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16), // Adjust button padding
                              ),
                              child: const Text(
                                "Add Schedule Row",
                                style: TextStyle(
                                  fontSize: 16, // Adjust text size
                                  fontWeight: FontWeight.bold, // Bold text
                                  color: Colors.white, // Text color
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
              // Budget Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Loop through each budget row
                  ..._budgetRows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Amount Field
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextFormField(
                                controller: row['amountController'],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  labelText: "Amount",
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300, width: 1),
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
                          // Description Field
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextFormField(
                                controller: row['descriptionController'],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  labelText: "Description",
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300, width: 1),
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
                  // Add Budget Row Button
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _addBudgetRow(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        // Rounded corners with 4px radius
                        side: BorderSide(
                            color: Colors.white,
                            width:
                            2), // Rectangle border with white color and 2px width
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16), // Adjust button padding
                    ),
                    child: const Text(
                      "Add Budget Row",
                      style: TextStyle(
                        fontSize: 16, // Adjust text size
                        fontWeight: FontWeight.bold, // Bold text
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                  // Add Budget Row Button
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _submitEvent(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        // Rounded corners with 4px radius
                        side: BorderSide(
                            color: Colors.white,
                            width:
                            2), // Rectangle border with white color and 2px width
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16), // Adjust button padding
                    ),
                    child: const Text(
                      "Submit Event",
                      style: TextStyle(
                        fontSize: 16, // Adjust text size
                        fontWeight: FontWeight.bold, // Bold text
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
