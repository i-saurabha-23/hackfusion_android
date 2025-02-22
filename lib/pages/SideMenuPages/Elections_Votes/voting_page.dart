import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/provider/UserAllDataProvier.dart';

class VotingPage extends StatefulWidget {
  final String electionId;
  final VoidCallback onVoteSubmitted;

  const VotingPage(
      {Key? key, required this.electionId, required this.onVoteSubmitted})
      : super(key: key);

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  int? _selectedCandidateIndex;
  List<Map<String, dynamic>> candidates = [];
  bool _isVotingInProgress = false;
  bool _isLoading = true;
  String post = 'Post not available';

  final userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _fetchElectionData();
  }

  Future<void> _fetchElectionData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('SHOW-ALL')
        .doc('ELECTIONS')
        .collection('DATA')
        .doc(widget.electionId)
        .get();
    if (snapshot.exists) {
      final electionData = snapshot.data() as Map<String, dynamic>;
      setState(() {
        candidates =
            List<Map<String, dynamic>>.from(electionData['candidates'] ?? []);
        post = electionData['post'] ?? 'Post not available';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Cast Your Vote',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                )),
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with election details
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey.shade100,
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ELECTION FOR',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.how_to_vote_outlined,
                                    size: 16, color: Colors.black54),
                                SizedBox(width: 8),
                                Text(
                                  'Select one candidate from the list below',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            'CANDIDATES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Divider(color: Colors.black26, thickness: 1),
                          ),
                        ],
                      ),
                    ),

                    // Candidates list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final candidate = candidates[index];
                          final isSelected = _selectedCandidateIndex == index;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.grey.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isSelected ? 0.08 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: isSelected ? 1.5 : 0,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCandidateIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Candidate Image
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: candidate['imagePath'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: candidate['imagePath'],
                                              placeholder: (context, url) =>
                                                  Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url,
                                                      error) =>
                                                  const Icon(Icons.person,
                                                      size: 36,
                                                      color: Colors.black38),
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(Icons.person,
                                              size: 36, color: Colors.black38),
                                    ),
                                    const SizedBox(width: 16),

                                    // Candidate Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate['name'] ??
                                                'Name not available',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Colors.black,
                                              letterSpacing:
                                                  isSelected ? -0.2 : 0,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${candidate['year'] ?? 'Year not available'} | ${candidate['section'] ?? 'Section not available'}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Selection indicator
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom voting button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedCandidateIndex == null ||
                                _isVotingInProgress
                            ? null
                            : () async {
                                setState(() {
                                  _isVotingInProgress = true;
                                });

                                final candidateIndex = _selectedCandidateIndex!;
                                final candidate = candidates[candidateIndex];

                                // Update vote count in Firestore
                                candidates[candidateIndex]['voteCount'] =
                                    (candidate['voteCount'] ?? 0) + 1;
                                await FirebaseFirestore.instance
                                    .collection('SHOW-ALL')
                                    .doc('ELECTIONS')
                                    .collection('DATA')
                                    .doc(widget.electionId)
                                    .update({'candidates': candidates});

                                // Mark user as voted in USERVOTES subcollection
                                await FirebaseFirestore.instance
                                    .collection('SHOW-ALL')
                                    .doc('ELECTIONS')
                                    .collection('DATA')
                                    .doc(widget.electionId)
                                    .collection('USERVOTES')
                                    .doc(userController.userEmail.value)
                                    .set({'voted': true});

                                setState(() {
                                  _isVotingInProgress = false;
                                });

                                // Call the callback function to refresh the previous screen
                                widget.onVoteSubmitted();

                                // Redirect and show confirmation
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Vote submitted successfully!'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    margin: const EdgeInsets.all(8),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'SUBMIT YOUR VOTE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: _selectedCandidateIndex == null ||
                                    _isVotingInProgress
                                ? Colors.grey.shade600
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        // Loading Overlay
        if (_isVotingInProgress)
          Container(
            color: Colors.black.withOpacity(0.7),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
