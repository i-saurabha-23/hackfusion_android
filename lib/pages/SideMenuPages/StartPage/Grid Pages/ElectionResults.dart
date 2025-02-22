import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewResultPage extends StatefulWidget {
  final String electionId;

  const ViewResultPage({Key? key, required this.electionId}) : super(key: key);

  @override
  _ViewResultPageState createState() => _ViewResultPageState();
}

class _ViewResultPageState extends State<ViewResultPage> {
  List<Map<String, dynamic>> candidates = [];
  int previousVoteCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Election Results',
            style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('SHOW-ALL')
            .doc('ELECTIONS')
            .collection('DATA')
            .doc(widget.electionId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.black,
            ));
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
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: candidate['imagePath'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: candidate['imagePath'],
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.person,
                                                color: Colors.white),
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.person,
                                        size: 40, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      candidate['name'] ?? 'Name not available',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${candidate['year'] ?? 'Year not available'} | ${candidate['section'] ?? 'Section not available'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('SHOW-ALL')
                                    .doc('ELECTIONS')
                                    .collection('DATA')
                                    .doc(widget.electionId)
                                    .snapshots(),
                                builder: (context, voteSnapshot) {
                                  if (voteSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(
                                      color: Colors.black,
                                    );
                                  }

                                  if (!voteSnapshot.hasData) {
                                    return const Text('No votes yet');
                                  }

                                  final updatedElectionData = voteSnapshot.data!
                                      .data() as Map<String, dynamic>;
                                  final updatedCandidate =
                                      updatedElectionData['candidates'][index]
                                          as Map<String, dynamic>;
                                  final voteCount =
                                      updatedCandidate['voteCount'] ?? 0;

                                  final voteDifference =
                                      (voteCount - previousVoteCount).abs();
                                  previousVoteCount = voteCount;
                                  int durationMilliseconds =
                                      (500 + (voteDifference * 50)).toInt();

                                  return AnimatedFlipCounter(
                                    value: voteCount,
                                    duration: Duration(
                                        milliseconds: durationMilliseconds),
                                    textStyle: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ],
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
