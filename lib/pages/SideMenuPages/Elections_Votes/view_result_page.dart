import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewResultPage extends StatefulWidget {
  final String electionId;

  const ViewResultPage({Key? key, required this.electionId}) : super(key: key);

  @override
  _ViewResultPageState createState() => _ViewResultPageState();
}

class _ViewResultPageState extends State<ViewResultPage> {
  List<Map<String, dynamic>> candidates = [];
  int previousVoteCount = 0;  // Store the previous vote count

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Results'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Elections').doc(widget.electionId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Election not found'));
          }

          final electionData = snapshot.data!.data() as Map<String, dynamic>;
          candidates = (electionData['candidates'] as List)
              .map((candidate) => candidate as Map<String, dynamic>)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Candidates & Vote Counts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: candidate['imagePath'] != null
                              ? CachedNetworkImage(
                            imageUrl: candidate['imagePath'],
                            placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.person, size: 50),
                          title: Text(
                            candidate['name'] ?? 'Name not available',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Elections')
                                .doc(widget.electionId)
                                .snapshots(),
                            builder: (context, voteSnapshot) {
                              if (voteSnapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              if (!voteSnapshot.hasData) {
                                return const Text('No votes yet');
                              }

                              final updatedElectionData = voteSnapshot.data!.data() as Map<String, dynamic>;
                              final updatedCandidate =
                              updatedElectionData['candidates'][index] as Map<String, dynamic>;
                              final voteCount = updatedCandidate['voteCount'] ?? 0;

                              // Calculate the difference in vote count
                              final voteDifference = (voteCount - previousVoteCount).abs();

                              // Update the previousVoteCount
                              previousVoteCount = voteCount;

                              // Slow down the animation based on the difference
                              int durationMilliseconds = (500 + (voteDifference * 50)).toInt();  // Explicitly convert to int

                              // Use AnimatedFlipCounter with dynamic duration
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Regular vote label
                                  const Text(
                                    'Votes: ',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  // Animated vote counter (on the right side and bigger)
                                  AnimatedFlipCounter(
                                    value: voteCount,
                                    duration: Duration(milliseconds: durationMilliseconds),
                                    textStyle: const TextStyle(
                                      fontSize: 30,  // Larger font size
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
