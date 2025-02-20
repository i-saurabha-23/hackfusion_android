import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../auth/provider/UserAllDataProvier.dart';

class VotingPage extends StatefulWidget {
  final String electionId;

  const VotingPage({Key? key, required this.electionId}) : super(key: key);

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  int? _selectedCandidateIndex;
  List<Map<String, dynamic>> candidates = [];
  bool _isVotingInProgress = false;

  final userController = Get.find<UserController>(); // Get the user controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Elections').doc(widget.electionId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Election not found'));
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
                Text('Election Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Post: ${electionData['post']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Department: ${electionData['department']}'),
                SizedBox(height: 8),
                Text('Section: ${electionData['section']}'),
                SizedBox(height: 8),
                Text('Year: ${electionData['year']}'),
                SizedBox(height: 16),
                Text('Candidates:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Radio<int>(
                            value: index,
                            groupValue: _selectedCandidateIndex,
                            onChanged: (value) {
                              setState(() {
                                _selectedCandidateIndex = value;
                              });
                            },
                          ),
                          title: Text(candidate['name'] ?? 'Name not available'),
                          subtitle: Text('Votes: ${candidate['voteCount'] ?? 0}'),
                          trailing: candidate['imagePath'] != null
                              ? CachedNetworkImage(
                            imageUrl: candidate['imagePath'],
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.person, size: 50),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedCandidateIndex == null || _isVotingInProgress
                      ? null
                      : () async {
                    setState(() {
                      _isVotingInProgress = true; // Show loading indicator
                    });

                    // Get the selected candidate index
                    final candidateIndex = _selectedCandidateIndex!;

                    // Get the current candidate and vote count
                    final candidate = candidates[candidateIndex];
                    final currentVoteCount = candidate['voteCount'] ?? 0;

                    // Find the candidate by name
                    final candidateName = candidate['name'];

                    // Update the vote count using Firestore update
                    await FirebaseFirestore.instance
                        .collection('Elections')
                        .doc(widget.electionId)
                        .update({
                      'candidates': FieldValue.arrayRemove([candidate]), // Remove the current candidate
                    });

                    // Update the vote count for the candidate
                    candidate['voteCount'] = currentVoteCount + 1;

                    // Re-add the updated candidate to the candidates array
                    await FirebaseFirestore.instance
                        .collection('Elections')
                        .doc(widget.electionId)
                        .update({
                      'candidates': FieldValue.arrayUnion([candidate]), // Re-add updated candidate
                    });

                    // Store the vote in the "USERVOTES" subcollection inside the election document
                    await FirebaseFirestore.instance
                        .collection('Elections')
                        .doc(widget.electionId)
                        .collection('USERVOTES')
                        .doc(userController.userEmail.value)
                        .set({
                      'voted': true,
                    });

                    // Update the local state to reflect the vote count increment
                    setState(() {
                      candidates[candidateIndex]['voteCount'] = currentVoteCount + 1;
                      _isVotingInProgress = false; // Hide loading indicator
                    });

                    // Redirect to the previous screen
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vote submitted successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVotingInProgress
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Vote Now', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
