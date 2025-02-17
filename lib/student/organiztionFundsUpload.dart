import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion/admin/models/organization_data.dart';

class OrganizationFundsUpload extends StatefulWidget {
  const OrganizationFundsUpload({Key? key}) : super(key: key);

  @override
  State<OrganizationFundsUpload> createState() =>
      _OrganizationFundsUploadState();
}

class _OrganizationFundsUploadState extends State<OrganizationFundsUpload> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final _orgNameController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();

  // Lists for faculty, committee, schedule, and expenses
  final List<String> _facultyCoordinators = [];
  final List<String> _coreCommittee = [];
  final List<ScheduleItem> _eventSchedule = [];
  final List<ExpenseItem> _expenses = [];

  // Helper controllers for adding new items
  final _facultyController = TextEditingController();
  final _committeeController = TextEditingController();
  final _scheduleTimeController = TextEditingController();
  final _scheduleActivityController = TextEditingController();
  final _expenseNameController = TextEditingController();
  final _expenseCostController = TextEditingController();

  // Loading indicator for when we upload to Firestore
  bool _isUploading = false;

  @override
  void dispose() {
    // Dispose controllers when the page is removed
    _orgNameController.dispose();
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _facultyController.dispose();
    _committeeController.dispose();
    _scheduleTimeController.dispose();
    _scheduleActivityController.dispose();
    _expenseNameController.dispose();
    _expenseCostController.dispose();
    super.dispose();
  }

  // Helper: build the final OrganizationData object from the form inputs
  OrganizationData _buildOrganizationData() {
    return OrganizationData(
      organizationName: _orgNameController.text.trim(),
      facultyCoordinators: _facultyCoordinators,
      coreCommittee: _coreCommittee,
      eventName: _eventNameController.text.trim(),
      eventDescription: _eventDescriptionController.text.trim(),
      eventSchedule: _eventSchedule,
      expenses: _expenses,
      isApproved: false, // Or handle approval logic as needed
    );
  }

  // Convert OrganizationData to a Firestore-friendly Map
  Map<String, dynamic> _toFirestoreMap(OrganizationData data) {
    return {
      "organizationName": data.organizationName,
      "facultyCoordinators": data.facultyCoordinators,
      "coreCommittee": data.coreCommittee,
      "eventName": data.eventName,
      "eventDescription": data.eventDescription,
      "eventSchedule": data.eventSchedule
          .map((s) => {
                "time": s.time,
                "activity": s.activity,
              })
          .toList(),
      "expenses": data.expenses
          .map((e) => {
                "name": e.name,
                "expectedCost": e.expectedCost,
              })
          .toList(),
      "isApproved": data.isApproved,
    };
  }

  // Submit / Upload logic to Firestore (store in subcollection)
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      final data = _buildOrganizationData();

      // 1. Reference the Organization doc by organizationName
      final orgDocRef = FirebaseFirestore.instance
          .collection("Organization")
          .doc(data.organizationName);

      // 2. The event details will go into a subcollection named "Events-Funds-Request"
      //    We'll name the document after the eventName for easy identification.
      final eventDocRef =
          orgDocRef.collection("Events-Funds-Request").doc(data.eventName);

      try {
        await eventDocRef.set(_toFirestoreMap(data));
        // Successfully uploaded
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Organization event data uploaded successfully!")),
        );
        // Optionally clear form or navigate away
        _clearForm();
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading: $e")),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Clear all fields after successful upload
  void _clearForm() {
    _orgNameController.clear();
    _eventNameController.clear();
    _eventDescriptionController.clear();
    _facultyCoordinators.clear();
    _coreCommittee.clear();
    _eventSchedule.clear();
    _expenses.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff6DD5FA), Color(0xff2980B9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Organization Name
                          TextFormField(
                            controller: _orgNameController,
                            decoration: const InputDecoration(
                              labelText: "Organization Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter organization name";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Faculty Coordinators
                          _buildSectionTitle("Faculty Coordinators"),
                          Wrap(
                            children: _facultyCoordinators
                                .map(
                                  (name) => Chip(
                                    label: Text(name),
                                    onDeleted: () {
                                      setState(() {
                                        _facultyCoordinators.remove(name);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _facultyController,
                                  decoration: const InputDecoration(
                                    labelText: "Add Coordinator",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final name = _facultyController.text.trim();
                                  if (name.isNotEmpty) {
                                    setState(() {
                                      _facultyCoordinators.add(name);
                                      _facultyController.clear();
                                    });
                                  }
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Core Committee
                          _buildSectionTitle("Core Committee"),
                          Wrap(
                            children: _coreCommittee
                                .map(
                                  (member) => Chip(
                                    label: Text(member),
                                    onDeleted: () {
                                      setState(() {
                                        _coreCommittee.remove(member);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _committeeController,
                                  decoration: const InputDecoration(
                                    labelText: "Add Committee Member",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final member =
                                      _committeeController.text.trim();
                                  if (member.isNotEmpty) {
                                    setState(() {
                                      _coreCommittee.add(member);
                                      _committeeController.clear();
                                    });
                                  }
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Event Name
                          TextFormField(
                            controller: _eventNameController,
                            decoration: const InputDecoration(
                              labelText: "Event Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter event name";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Event Description
                          TextFormField(
                            controller: _eventDescriptionController,
                            decoration: const InputDecoration(
                              labelText: "Event Description",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter event description";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Event Schedule
                          _buildSectionTitle("Event Schedule"),
                          ..._eventSchedule.map(
                            (item) => ListTile(
                              title: Text("${item.time} - ${item.activity}"),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _eventSchedule.remove(item);
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _scheduleTimeController,
                                  decoration: const InputDecoration(
                                    labelText: "Time",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _scheduleActivityController,
                                  decoration: const InputDecoration(
                                    labelText: "Activity",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final time =
                                      _scheduleTimeController.text.trim();
                                  final activity =
                                      _scheduleActivityController.text.trim();
                                  if (time.isNotEmpty && activity.isNotEmpty) {
                                    setState(() {
                                      _eventSchedule.add(
                                        ScheduleItem(
                                          time: time,
                                          activity: activity,
                                        ),
                                      );
                                      _scheduleTimeController.clear();
                                      _scheduleActivityController.clear();
                                    });
                                  }
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Expenses
                          _buildSectionTitle("Expected Expenses"),
                          ..._expenses.map(
                            (item) => ListTile(
                              title:
                                  Text("${item.name} (\$${item.expectedCost})"),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _expenses.remove(item);
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _expenseNameController,
                                  decoration: const InputDecoration(
                                    labelText: "Expense Name",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _expenseCostController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: "Expected Cost",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final name =
                                      _expenseNameController.text.trim();
                                  final costString =
                                      _expenseCostController.text.trim();
                                  if (name.isNotEmpty &&
                                      costString.isNotEmpty) {
                                    final cost = double.tryParse(costString);
                                    if (cost != null) {
                                      setState(() {
                                        _expenses.add(
                                          ExpenseItem(
                                              name: name, expectedCost: cost),
                                        );
                                        _expenseNameController.clear();
                                        _expenseCostController.clear();
                                      });
                                    }
                                  }
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: _isUploading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Upload to Firebase",
                                      style: TextStyle(
                                        fontSize: 18,
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
                ),
              ),
              // Optional loading overlay
              if (_isUploading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to style section titles
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }
}
