import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewResultPage extends StatefulWidget {
  final String electionId;
  final String postName; // If empty, show full election results

  const ViewResultPage({
    Key? key,
    required this.electionId,
    this.postName = '', // Make postName optional with default empty string
  }) : super(key: key);

  @override
  _ViewResultPageState createState() => _ViewResultPageState();
}

class _ViewResultPageState extends State<ViewResultPage> {
  List<dynamic> _posts = [];
  int previousVoteCount = 0;

  Widget _buildCandidateResultCard(
      Map<String, dynamic> candidate,
      int candidateIndex,
      Map<String, dynamic> postData
      ) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                const Icon(Icons.person, color: Colors.white),
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.person, size: 40, color: Colors.white),
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
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: Colors.black,
                  );
                }

                if (!voteSnapshot.hasData) {
                  return const Text('No votes yet');
                }

                final updatedElectionData =
                voteSnapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> updatedPosts =
                    updatedElectionData['posts'] ?? [];

                final updatedPostData = widget.postName.isEmpty
                    ? postData
                    : updatedPosts.firstWhere(
                      (post) => post['post'] == widget.postName,
                  orElse: () => null,
                );

                if (updatedPostData == null) {
                  return const Text('Post not found');
                }

                final updatedCandidate =
                updatedPostData['candidates'][candidateIndex]
                as Map<String, dynamic>;
                final voteCount = updatedCandidate['voteCount'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedFlipCounter(
                      value: voteCount,
                      duration: const Duration(milliseconds: 500),
                      textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'Votes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            widget.postName.isEmpty
                ? 'Complete Election Results'
                : 'Results',
            style: const TextStyle(color: Colors.white)
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              child: CircularProgressIndicator(color: Colors.black),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Election not found'));
          }

          final electionData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> posts = electionData['posts'] ?? [];

          // If specific post is requested
          if (widget.postName.isNotEmpty) {
            final postData = posts.firstWhere(
                  (post) => post['post'] == widget.postName,
              orElse: () => null,
            );

            if (postData == null) {
              return Center(child: Text('Post "${widget.postName}" not found'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESULTS FOR',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.postName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: postData['candidates'].length,
                    itemBuilder: (context, index) {
                      return _buildCandidateResultCard(
                          postData['candidates'][index],
                          index,
                          postData
                      );
                    },
                  ),
                ),
              ],
            );
          }

          // If full election results are requested
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, postIndex) {
              final postData = posts[postIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      postData['post'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ...List.generate(
                    postData['candidates'].length,
                        (candidateIndex) => _buildCandidateResultCard(
                        postData['candidates'][candidateIndex],
                        candidateIndex,
                        postData
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
