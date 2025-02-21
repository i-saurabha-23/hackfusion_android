import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Complaints extends StatefulWidget {
  const Complaints({Key? key}) : super(key: key);

  @override
  State<Complaints> createState() => _ComplaintsState();
}

class _ComplaintsState extends State<Complaints> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[200], // Light background for better readability
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Complaints').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blueAccent,
                size: 50,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No complaints found.', style: TextStyle(color: Colors.black)));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final data = complaint.data() as Map<String, dynamic>;

              // Convert Timestamp to readable format
              String formattedDate = data['timestamp'] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format((data['timestamp'] as Timestamp).toDate())
                  : 'Unknown date';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Anonymous Title & Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Anonymous',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Complaint Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: data['imageUrl'] ?? '',
                          placeholder: (context, url) => Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.blueAccent,
                              size: 50,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Complaint Description with Title
                      const Text(
                        'Description:',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? 'No description provided',
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
