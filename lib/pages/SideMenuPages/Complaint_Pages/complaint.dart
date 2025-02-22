import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion_android/All_Constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../auth/provider/UserAllDataProvier.dart';
import 'allcomplaint_pages.dart';
import 'package:http/http.dart' as http;

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({Key? key}) : super(key: key);

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isImageProcessing = false; // Add this variable to track image processing state
  bool _isSubmitting = false;
  File? _selectedImage;
  final List<String> _predefinedCategories = [
    'Technical Issue',
    'Billing Problem',
    'Service Quality',
    'Product Defect',
    'Other'
  ];

  final UserController _userController = Get.put(UserController());

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isImageProcessing = true; // Start image processing
      });

      // Print the API response for debugging
      print('Image selected: ${image.path}');

      // Check for adult or racy content
      final isAdultContent = await _checkAdultContent(File(image.path));

      if (isAdultContent) {
        setState(() {
          _selectedImage = null; // Remove the image if it contains adult content
          _isImageProcessing = false; // Stop image processing
        });

        _showAdultContentDialog(); // Show the popup for inappropriate content
      } else {
        setState(() {
          _isImageProcessing = false; // Stop image processing
        });
      }
    }
  }

  Future<bool> _checkAdultContent(File image) async {
    final base64Image = base64Encode(await image.readAsBytes());

    final url = GoogleVision_BaseUrl+GoogleAPiKey ;

    final requestBody = json.encode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {
              "type": "SAFE_SEARCH_DETECTION",
            },
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    // Print the API response to the console
    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final safeSearchAnnotation = responseBody['responses'][0]['safeSearchAnnotation'];

      // Check if the image contains adult or racy content
      if (safeSearchAnnotation['adult'] == 'VERY_LIKELY' || safeSearchAnnotation['racy'] == 'VERY_LIKELY') {
        return true; // Image contains adult or racy content
      }
    } else {
      print('Error with Vision API: ${response.statusCode}');
    }

    return false; // Image does not contain adult or racy content
  }

  void _showAdultContentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          title: const Text(
            'Inappropriate Content',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 18,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Your image is inappropriate. Please select another image.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _uploadImageToStorage(String complaintId) async {
    if (_selectedImage == null) return null;

    try {
      // Create a reference to the image location in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('complaint_images')
          .child('$complaintId.jpg');

      // Upload the file
      await storageRef.putFile(_selectedImage!);

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    // Validate inputs
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // Get the current user's email and student details from UserController
    String userEmail = _userController.userEmail.value;
    String userName = _userController.userName.value;
    String userNumber = _userController.userPhone.value;
    String userDepartment = _userController.userDepartment.value;
    String userYear = _userController.userYear.value;
    String userSection = _userController.userSection.value;
    String userRollNo = _userController.userRollNo.value;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the complaint count for the current user
      var complaintsSnapshot = await FirebaseFirestore.instance
          .collection('SHOW-ALL')
          .doc('COMPLAINTS')
          .collection('DATA')
          .where('userEmail', isEqualTo: userEmail)
          .get();

      int complaintCount = complaintsSnapshot.docs.length;

      // Generate a new complaint document ID using email + complaint count (e.g., email+C1)
      String complaintId = '$userEmail+C${complaintCount + 1}';

      // Create a new complaint document reference with the generated ID
      var complaintRef = FirebaseFirestore.instance
          .collection('SHOW-ALL')
          .doc('COMPLAINTS')
          .collection('DATA')
          .doc(complaintId);
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(complaintId);
      }

      // Adding complaint details to Firestore including the student's information
      await complaintRef.set({
        'Email': userEmail,
        'Name': userName,
        'RollNo': userRollNo,
        'Number': userNumber,
        'Department': userDepartment,
        'Year': userYear,
        'Section': userSection,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'complaintId': complaintId,
        'imageUrl': imageUrl,
        'status': 'Pending', // Initial status
      });

      // Set isInitialized true after creating the complaint document
      await FirebaseFirestore.instance
          .collection('SHOW-ALL')
          .doc('COMPLAINTS')
          .set({'isInitialized': true}, SetOptions(merge: true));

      // Reset form after submission
      _descriptionController.clear();
      _categoryController.clear();
      setState(() {
        _selectedImage = null;
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint submitted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.black,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Submit New', icon: Icon(Icons.add_circle_outline)),
                  Tab(text: 'My Complaints', icon: Icon(Icons.list_alt)),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSubmitComplaintForm(),
                  _buildComplaintsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitComplaintForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit a New Complaint',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Category as TextField instead of Dropdown
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              onChanged: (value) {
                _categoryController.text = value;
              },
            ),

            const SizedBox(height: 16),

            // Description TextField
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Complaint Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Please provide details about your complaint...',
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 20),

            // Image Upload Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attach Evidence (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedImage != null) ...[
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: _isImageProcessing
                                ? null // Don't show the image while processing
                                : DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: _isImageProcessing
                              ? const Center(
                            child: CircularProgressIndicator(), // Show loading animation
                          )
                              : null,
                        ),
                        if (!_isImageProcessing) // Show cancel button only after processing
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library, color: Colors.black,),
                        label: const Text('Select Image', style: TextStyle(color: Colors.black),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Complaint',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Complaints')
          .snapshots(), // Fetch all complaints from the collection
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No complaints submitted yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filter documents based on the user's email in the document ID (email+C1, email+C2, etc.)
        final complaints = snapshot.data!.docs.where((doc) {
          final docId = doc.id;
          return docId.startsWith(_userController.userEmail.value + '+');  // Filter by email+C1, email+C2...
        }).toList();

        // Sort complaints by timestamp
        complaints.sort((a, b) {
          final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
          final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
          return timestampB.compareTo(timestampA);  // Sort descending (most recent first)
        });

        // Debugging: Print complaints count
        print('Total complaints fetched: ${complaints.length}');

        return ListView.builder(
          itemCount: complaints.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final complaint = complaints[index].data() as Map<String, dynamic>;
            final timestamp = complaint['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy - h:mm a').format(timestamp.toDate())
                : 'Date pending';

            final statusColor = _getStatusColor(complaint['status'] ?? 'Pending');

            return Card(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo[100],
                  child: Icon(
                    _getCategoryIcon(complaint['category'] ?? ''),
                    color: Colors.indigo,
                  ),
                ),
                title: Text(
                  complaint['category'] ?? 'Unknown Category',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      complaint['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint['status'] ?? 'Pending',
                    style: TextStyle(color: statusColor),
                  ),
                ),
                onTap: () {
                  _navigateToComplaintDetails(complaint);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToComplaintDetails(Map<String, dynamic> complaint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintDetailsPage(complaint: complaint),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Technical Issue':
        return Icons.computer_outlined;
      case 'Billing Problem':
        return Icons.receipt_outlined;
      case 'Service Quality':
        return Icons.thumb_down_outlined;
      case 'Product Defect':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
