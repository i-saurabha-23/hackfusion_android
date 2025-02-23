import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../auth/provider/UserAllDataProvier.dart';

class LeaveApplicationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  tabs: [
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Apply Leave'),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('My Applications'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              Expanded(
                child: TabBarView(
                  children: [
                    ApplyLeaveTab()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.2, end: 0),
                    ViewApplicationsTab()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ApplyLeaveTab extends StatefulWidget {
  @override
  _ApplyLeaveTabState createState() => _ApplyLeaveTabState();
}

class _ApplyLeaveTabState extends State<ApplyLeaveTab> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserController userController = Get.find<UserController>();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHosteler = false;
  File? _proofFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isHosteler = false;
      _proofFile = null;
      _reasonController.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _proofFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadProof() async {
    if (_proofFile == null) return null;

    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_proofFile!.path.split('/').last}';
      Reference ref = _storage.ref().child('leave_proofs/$fileName');

      SettableMetadata metadata = SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {'picked-file-path': _proofFile!.path},
      );

      await ref.putFile(_proofFile!, metadata);
      String downloadUrl = await ref.getDownloadURL();
      print('Proof uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading proof: $e');
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String baseUrl = Platform.isAndroid
          ? 'https://symphony-force-wanting-camcorders.trycloudflare.com'
          : Platform.isIOS
              ? 'http://localhost:5000'
              : 'http://YOUR_MACHINE_IP:5000';

      // Test server connection
      try {
        final healthCheck = await http
            .get(Uri.parse(baseUrl))
            .timeout(const Duration(seconds: 5));
        if (healthCheck.statusCode != 200) {
          throw Exception('Server is not responding properly');
        }
      } catch (e) {
        print("Server connection failed: $e");
        throw Exception(
            'Cannot connect to server. Please check if the server is running.');
      }

      // Get faculty email from Firestore
      QuerySnapshot facultySnapshot = await _firestore
          .collection('Faculties')
          .where('department', isEqualTo: userController.userDepartment.value)
          .where('year', isEqualTo: userController.userYear.value)
          .where('section', isEqualTo: userController.userSection.value)
          .where('isCoordinator', isEqualTo: true)
          .get();

      if (facultySnapshot.docs.isEmpty) {
        throw Exception('No faculty coordinator found.');
      }

      String facultyEmail = facultySnapshot.docs.first['email'] as String;
      print("Faculty Email: $facultyEmail");

      int duration = _endDate!.difference(_startDate!).inDays + 1;

      // Upload proof file to Firebase Storage
      String? proofUrl = await _uploadProof();

      // Prepare leave application data
      Map<String, dynamic> leaveData = {
        'name': userController.userName.value ?? '',
        'email': userController.userEmail.value ?? '',
        'facultyEmail': facultyEmail,
        'parentEmail': userController.userParentsEmail.value ?? '',
        'reason': _reasonController.text,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'duration': duration,
        'status': 'Pending', // Default status
        'timestamp': FieldValue.serverTimestamp(),
        'proofUrl': proofUrl ?? '', // Store URL in Firestore
      };

      // Store application in Firestore
      DocumentReference leaveRef =
          await _firestore.collection('leave_applications').add(leaveData);

      print("Leave Application Stored: ${leaveRef.id}");

      // Prepare multipart request for email
      var uri = Uri.parse('$baseUrl/send-email');
      var request = http.MultipartRequest('POST', uri);
      request.fields.addAll(
          leaveData.map((key, value) => MapEntry(key, value.toString())));

      // Attach the actual file to the email request
      if (_proofFile != null) {
        try {
          var fileStream = http.ByteStream(_proofFile!.openRead());
          var length = await _proofFile!.length();

          var multipartFile = http.MultipartFile(
              'proofFile', fileStream, length,
              filename: _proofFile!.path.split('/').last);

          request.files.add(multipartFile);
          print("File attached successfully");
        } catch (e) {
          print("Error attaching file: $e");
          throw Exception('Failed to attach supporting document');
        }
      }

      // Send the request
      try {
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out. Please try again.');
          },
        );

        // Get the response
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          Get.snackbar(
            'Success',
            'Leave application submitted successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          // Update Firestore status to "Submitted"
          await leaveRef.update({'status': 'In Review'});
        } else {
          print("Server response: ${response.body}");
          throw Exception(
              'Failed to submit application: ${response.statusCode}');
        }
      } catch (e) {
        print("Error sending request: $e");
        if (e is TimeoutException) {
          throw Exception(
              'Request timed out. Please check your internet connection and try again.');
        }
        throw Exception('Failed to send application: ${e.toString()}');
      }
    } catch (e) {
      print("Error: $e");
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDurationCard(),
              SizedBox(height: 16),
              _buildReasonCard(),
              SizedBox(height: 16),
              _buildDocumentCard(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ]
                .animate(interval: 100.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your reason for leave',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter reason for leave';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('I am a hosteler'),
              value: _isHosteler,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (value) {
                setState(() {
                  _isHosteler = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supporting Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: Icon(Icons.attach_file),
              label:
                  Text(_proofFile != null ? 'Change File' : 'Upload Document'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            if (_proofFile != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${_proofFile!.path.split('/').last}',
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitApplication,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Submit Application',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              date != null
                  ? DateFormat('MMM dd, yyyy').format(date)
                  : 'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                color: date != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewApplicationsTab extends StatelessWidget {
  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_applications')
          .where('email', isEqualTo: userController.userEmail.value)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No applications found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your leave applications will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ApplicationCard(data: data)
                .animate()
                .fadeIn(delay: (50 * index).ms, duration: 400.ms)
                .slideX(begin: 0.2, end: 0);
          },
        );
      },
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  ApplicationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Ensure timestamp conversion
    final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    final DateTime createdAt =
        createdAtTimestamp?.toDate() ?? DateTime.now(); // Fallback value

    // Convert start and end dates safely
    final DateTime startDate = (data['startDate'] is Timestamp)
        ? (data['startDate'] as Timestamp).toDate()
        : DateTime.parse(data['startDate']);
    final DateTime endDate = (data['endDate'] is Timestamp)
        ? (data['endDate'] as Timestamp).toDate()
        : DateTime.parse(data['endDate']);

    // Calculate duration
    final int duration =
        data['duration'] ?? (endDate.difference(startDate).inDays + 1);

    // Status and Color Mapping
    final String status = data['status'] ?? 'Pending';
    final Color statusColor = status == 'Approved'
        ? Colors.green
        : status == 'Rejected'
            ? Colors.red
            : Colors.orange;

    // Check for proof attachment
    final String? proofUrl = data['proofUrl'];

    // Hosteler status (optional field)
    final bool isHosteler = data['isHosteler'] ?? false;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.bottomSheet(
            ApplicationDetailsSheet(data: data),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$duration ${duration == 1 ? 'day' : 'days'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                data['reason'] ?? 'No reason provided',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (isHosteler)
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Hosteler',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (proofUrl != null && proofUrl.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attachment,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Attachment',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Applied: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showFullScreenLeaveDetails(
    BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // Allows full-screen height
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9, // 90% of screen height
      child: ApplicationDetailsSheet(data: data),
    ),
  );
}

class ApplicationDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  ApplicationDetailsSheet({required this.data});

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    // Fallback to current date if parsing fails
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Safely parse dates
    final startDate = _parseDateTime(data['startDate']);
    final endDate = _parseDateTime(data['endDate']);
    final status = data['status'] as String? ?? 'Pending';
    final isHosteler = data['isHosteler'] as bool? ?? false;
    final proofUrl = data['proofUrl'] as String?;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Start Date',
                      DateFormat('MMM dd, yyyy').format(startDate)),
                  _buildDetailRow(
                      'End Date', DateFormat('MMM dd, yyyy').format(endDate)),
                  _buildDetailRow('Duration',
                      '${endDate.difference(startDate).inDays + 1} days'),
                  _buildDetailRow('Reason', data['reason'] ?? 'No reason provided'),
                  if (isHosteler) _buildDetailRow('Accommodation', 'Hosteler'),
                  if (proofUrl != null && proofUrl.isNotEmpty)
                    _buildDetailRow('Document', 'Attached', isLink: true,
                        onTap: () {
                          // Handle document viewing
                        }),
                  _buildDetailRow(
                    'Applied On',
                    DateFormat('MMM dd, yyyy').format(
                      _parseDateTime(data['createdAt'] ?? DateTime.now()),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500
            ),
          ),
          SizedBox(height: 4),
          if (isLink)
            GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline
                ),
              ),
            )
          else
            Text(
                value,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black
                )
            ),
        ],
      ),
    );
  }
}
