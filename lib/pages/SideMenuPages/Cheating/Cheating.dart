import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CheatingRecords extends StatefulWidget {
  @override
  _CheatingRecordsState createState() => _CheatingRecordsState();
}

class _CheatingRecordsState extends State<CheatingRecords>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _examNameController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Dropdown data
  List<String> departments = [
    'Computer Science and Engineering',
    'Electronics and Telecommunication Engineering',
    'Mechanical Engineering',
    'Artificial Intelligence and Data Science',
    'Artificial Intelligence and Machine Learning',
    'Civil Engineering (CIVIL)',
    'Electrical Engineering (EE)',
  ];

  List<String> sections = ['A', 'B', 'C', 'D'];
  List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  // Dropdown selected values
  String? _selectedDepartment;
  String? _selectedSection;
  String? _selectedYear;

  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Method to upload the image to Firebase Storage
  Future<String> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child("cheating_proofs/$fileName");

      final uploadTask = storageRef.putFile(image);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw e;
    }
  }

  // Method to submit the data to Firestore
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _image != null &&
        _selectedDepartment != null &&
        _selectedSection != null &&
        _selectedYear != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        String imageUrl = await _uploadImage(_image!);

        await FirebaseFirestore.instance.collection('cheating_records').add({
          'name': _nameController.text,
          'reason': _reasonController.text,
          'exam_name': _examNameController.text,
          'department': _selectedDepartment,
          'section': _selectedSection,
          'year': _selectedYear,
          'proof': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _nameController.clear();
        _reasonController.clear();
        _examNameController.clear();
        setState(() {
          _image = null;
          _selectedDepartment = null;
          _selectedSection = null;
          _selectedYear = null;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data uploaded successfully')));
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
      }
    }
  }

  // Fetch the cheating records from Firestore
  Stream<QuerySnapshot> _fetchCheatingRecords() {
    return FirebaseFirestore.instance
        .collection('cheating_records')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Method to delete a record
  Future<void> _deleteRecord(String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('cheating_records')
          .doc(recordId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Record deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this); // Three tabs: Create, Manage, Show All
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Cheating Records'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Create'),
            Tab(text: 'Manage'),
            Tab(text: 'Show All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // "Create" Tab with the Form
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the student\'s name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for Cheating',
                      prefixIcon: Icon(Icons.report),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the reason';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _examNameController,
                    decoration: InputDecoration(
                      labelText: 'Exam Name',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the exam name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: screenWidth,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                      isExpanded: true,
                      items: departments
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: InputDecoration(
                      labelText: 'Section',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSection = newValue;
                      });
                    },
                    items:
                        sections.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a section';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    },
                    items: years.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a year';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _image == null
                      ? IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: _pickImage,
                          iconSize: 40,
                        )
                      : Image.file(
                          _image!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                  SizedBox(height: 16),
                  _isUploading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitForm,
                          child: Text('Submit'),
                        ),
                ],
              ),
            ),
          ),

          // "Manage" Tab to show records with Delete and View Details
          Padding(
            padding: EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchCheatingRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No records found'));
                }

                final records = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final recordId = record.id;
                    final name = record['name'];
                    final reason = record['reason'];
                    final examName = record['exam_name'];
                    final department = record['department'];
                    final section = record['section'];
                    final year = record['year'];
                    final imageUrl = record['proof'];

                    return GestureDetector(
                      onTap: () {
                        // Navigate to the detailed view screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordDetailPage(
                              recordId: recordId,
                              name: name,
                              reason: reason,
                              examName: examName,
                              department: department,
                              section: section,
                              year: year,
                              imageUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(name),
                          subtitle: Text('$examName - $reason'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Show confirmation dialog before deleting
                              _showDeleteConfirmationDialog(recordId);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // "Show All" Tab to show all records
          Padding(
            padding: EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchCheatingRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No records found'));
                }

                final records = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final recordId = record.id;
                    final name = record['name'];
                    final reason = record['reason'];
                    final examName = record['exam_name'];

                    return GestureDetector(
                      onTap: () {
                        // Navigate to the detailed view screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordDetailPage(
                              recordId: recordId,
                              name: name,
                              reason: reason,
                              examName: examName,
                              department: record['department'],
                              section: record['section'],
                              year: record['year'],
                              imageUrl: record['proof'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(name),
                          subtitle: Text('$examName - $reason'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for record deletion
  void _showDeleteConfirmationDialog(String recordId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this record?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteRecord(recordId);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class RecordDetailPage extends StatelessWidget {
  final String recordId;
  final String name;
  final String reason;
  final String examName;
  final String department;
  final String section;
  final String year;
  final String imageUrl;

  RecordDetailPage({
    required this.recordId,
    required this.name,
    required this.reason,
    required this.examName,
    required this.department,
    required this.section,
    required this.year,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Name: $name', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Reason: $reason', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Exam: $examName', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Department: $department', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Section: $section', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Year: $year', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),

            // Image with loading indicator that keeps spinning until fully loaded
            imageUrl.isEmpty
                ? Center(child: Text('No image available'))
                : Center(
              child: Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // Image has finished loading
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: null, // Keeps the spinner spinning until image is fully loaded
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

