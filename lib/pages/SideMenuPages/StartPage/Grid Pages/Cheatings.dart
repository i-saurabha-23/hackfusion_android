import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Cheatings extends StatefulWidget {
  const Cheatings({Key? key}) : super(key: key);

  @override
  State<Cheatings> createState() => _CheatingsState();
}

class _CheatingsState extends State<Cheatings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Cheating Records', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('cheating_records').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.black,
                size: 50,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No cheating records found.', style: TextStyle(color: Colors.black)));
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final data = record.data() as Map<String, dynamic>;

              // Convert Timestamp to readable format
              String formattedDate = data['timestamp'] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format((data['timestamp'] as Timestamp).toDate())
                  : 'Unknown date';

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Exam Details
                      Text(
                        data['name'] ?? 'Unknown Student',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📖 Exam: ${data['exam_name'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🕒 Time: $formattedDate',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⚠️ Reason: ${data['reason'] ?? 'No reason provided'}',
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),

                      const SizedBox(height: 10),

                      // Cheating Proof Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: data['proof'] ?? '',
                          placeholder: (context, url) => Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.black,
                              size: 50,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                          const Center(child: Icon(Icons.image_not_supported, size: 80)),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),
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
