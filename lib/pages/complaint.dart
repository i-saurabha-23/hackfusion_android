import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComplaint() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Generate a new complaint ID and create a new document in Firestore
      var complaintRef =
          FirebaseFirestore.instance.collection('Complaints').doc();

      // Adding complaint details to Firestore
      await complaintRef.set({
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'complaintId': complaintRef.id, // Auto-generate complaint ID
      });

      // Reset form after submission
      _descriptionController.clear();
      _categoryController.clear();

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Complaint submitted with ID: ${complaintRef.id}')),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting complaint')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Complaint Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitComplaint,
                    child: const Text('Submit Complaint'),
                  ),
            const SizedBox(height: 20),
            // StreamBuilder to listen to the latest complaint submissions
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Complaints')
                  .orderBy('timestamp', descending: true)
                  .limit(1) // Only listen to the latest complaint
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading complaints'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No complaints submitted yet.'));
                }

                var latestComplaint = snapshot.data!.docs.first;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Latest Complaint ID: ${latestComplaint['complaintId']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
