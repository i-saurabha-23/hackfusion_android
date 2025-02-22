import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/provider/UserAllDataProvier.dart';

class SequentialMultiPostVotingPage extends StatefulWidget {
  final String electionId;
  final VoidCallback onVoteSubmitted;

  const SequentialMultiPostVotingPage({
    Key? key,
    required this.electionId,
    required this.onVoteSubmitted,
  }) : super(key: key);

  @override
  _SequentialMultiPostVotingPageState createState() => _SequentialMultiPostVotingPageState();
}

class _SequentialMultiPostVotingPageState extends State<SequentialMultiPostVotingPage> {
  List<Map<String, dynamic>> _posts = [];
  int _currentPostIndex = 0;
  int? _selectedCandidateIndex;
  bool _isVotingInProgress = false;
  bool _isLoading = true;

  final userController = Get.find<UserController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchElectionPosts();
  }

  Future<void> _fetchElectionPosts() async {
    try {
      final docRef = _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(widget.electionId);

      final electionDoc = await docRef.get();
      if (!electionDoc.exists) {
        throw Exception('Election not found');
      }

      // Get all posts
      List<dynamic> postsData = electionDoc.data()?['posts'] ?? [];

      setState(() {
        _posts = postsData.map((post) => post as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching election posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading election details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitVoteAndMoveNext() async {
    // Check if a candidate is selected
    if (_selectedCandidateIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a candidate.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVotingInProgress = true;
    });

    try {
      final docRef = _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(widget.electionId);

      // Get the current election document
      final electionDoc = await docRef.get();
      if (!electionDoc.exists) {
        throw Exception('Election not found');
      }

      // Get all posts
      List<dynamic> posts = electionDoc.data()?['posts'] ?? [];

      // Current post details
      final currentPost = _posts[_currentPostIndex];

      // Increment vote count for the selected candidate
      posts[_currentPostIndex]['candidates'][_selectedCandidateIndex!]['voteCount'] =
          (posts[_currentPostIndex]['candidates'][_selectedCandidateIndex!]['voteCount'] ?? 0) + 1;

      // Update the election document with new vote counts
      await docRef.update({'posts': posts});

      // Prepare user voting data
      Map<String, dynamic> userVotingData = {
        'gender': userController.userGender.value,
        'department': userController.userDepartment.value,
        'posts_voted': {
          currentPost['post']: true
        }
      };

      // Store user voting data
      await _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(widget.electionId)
          .collection('USERVOTES')
          .doc(userController.userEmail.value)
          .set(userVotingData, SetOptions(merge: true));

      // Move to next post or finish voting
      if (_currentPostIndex < _posts.length - 1) {
        setState(() {
          _currentPostIndex++;
          _selectedCandidateIndex = null;
          _isVotingInProgress = false;
        });
      } else {
        // All posts voted
        widget.onVoteSubmitted();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('All votes submitted successfully!'),
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
      }
    } catch (e) {
      print('Error submitting vote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting vote. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isVotingInProgress = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back if voting is in progress
        if (_isVotingInProgress) return false;
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Vote: Post ${_currentPostIndex + 1}/${_posts.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2.5,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT POST',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _posts[_currentPostIndex]['post'],
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_vote_outlined,
                                size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              'Select a candidate for ${_posts[_currentPostIndex]['post']}',
                              style: const TextStyle(
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _posts[_currentPostIndex]['candidates'].length,
                    itemBuilder: (context, candidateIndex) {
                      final candidate =
                      _posts[_currentPostIndex]['candidates'][candidateIndex];
                      final isSelected = _selectedCandidateIndex == candidateIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.grey.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: isSelected ? 1.5 : 0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCandidateIndex = candidateIndex;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
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
                                    placeholder: (context, url) => Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                    const Icon(Icons.person,
                                        size: 36, color: Colors.black38),
                                    fit: BoxFit.cover,
                                  )
                                      : const Icon(Icons.person,
                                      size: 36, color: Colors.black38),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        candidate['name'] ?? 'Name not available',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Colors.black,
                                          letterSpacing: isSelected ? -0.2 : 0,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
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
                        : _submitVoteAndMoveNext,
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
                      _currentPostIndex < _posts.length - 1
                          ? 'SUBMIT VOTE'
                          : 'SUBMIT VOTE',
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
      ),
    );
  }
}