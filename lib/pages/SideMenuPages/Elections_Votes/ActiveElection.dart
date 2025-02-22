import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Elections_Votes/voting_page.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../auth/provider/UserAllDataProvier.dart';
import 'view_result_page.dart';

class ActiveElection extends StatefulWidget {
  const ActiveElection({Key? key}) : super(key: key);

  @override
  State<ActiveElection> createState() => _ActiveElectionState();
}

class _ActiveElectionState extends State<ActiveElection>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userController = Get.find<UserController>();
  late TabController _tabController;
  bool _isLoading = true;

  Future<bool> _hasUserVotedForAllPosts(String electionId) async {
    try {
      // Fetch the user's voting document for this election
      final userVoteDoc = await _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(electionId)
          .collection('USERVOTES')
          .doc(userController.userEmail.value)
          .get();

      // If the document doesn't exist, return false
      if (!userVoteDoc.exists) {
        return false;
      }

      // Get the election document to check available posts
      final electionDoc = await _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(electionId)
          .get();

      // Get all posts from the election
      final List<dynamic> posts = electionDoc.data()?['posts'] ?? [];

      // Check if all posts have been voted
      final userVoteData = userVoteDoc.data()?['posts_voted'] ?? {};

      return posts.every((post) =>
      userVoteData[post['post']] == true
      );
    } catch (e) {
      print('Error checking user votes: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshElections() {
    setState(() {});
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 200,
                          height: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.white,
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElectionCard(
      DocumentSnapshot election, bool voted, int electionIndex) {
    final creationDateString = election['creationDate'] as String;
    final creationDate = DateTime.parse(creationDateString);
    final formattedDate = DateFormat('dd-MM-yyyy').format(creationDate);

    // Check if results are ready to be shown
    final bool showResults = election['showResult'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 24,
                  child: Text(
                    'E${electionIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Election ${electionIndex + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on: $formattedDate',
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: showResults
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewResultPage(
                          electionId: election.id,
                          postName: '', // Empty as we're viewing entire election
                        ),
                      ),
                    );
                  }
                      : null, // Disable button if showResults is false
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: Text(
                    'View Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: showResults
                          ? Colors.white
                          : Colors.black54,
                    ),
                  ),
                ),
                if (!voted)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Extract all candidates from all posts
                      final List<dynamic> postsData =
                      election['posts'] as List<dynamic>;
                      final List<dynamic> allCandidates =
                      postsData.expand((post) =>
                      post['candidates'] as List<dynamic>).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SequentialMultiPostVotingPage(
                            electionId: election.id,
                            onVoteSubmitted: _refreshElections,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text(
                      'Vote Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionsTab(bool voted) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            padding: const EdgeInsets.only(top: 16),
            itemBuilder: (context, index) => _buildShimmerCard(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.black, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  voted ? Icons.how_to_vote_outlined : Icons.ballot_outlined,
                  color: Colors.black38,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  voted
                      ? 'No voted elections yet'
                      : 'No active elections available',
                  style: const TextStyle(fontSize: 18, color: Colors.black38),
                ),
              ],
            ),
          );
        }

        final elections = snapshot.data!.docs
            .where((doc) => doc['isActive'] == true)
            .toList();

        if (elections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  voted ? Icons.how_to_vote_outlined : Icons.ballot_outlined,
                  color: Colors.black38,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  voted ? 'No voted elections' : 'No active elections',
                  style: const TextStyle(fontSize: 18, color: Colors.black38),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: elections.length,
          itemBuilder: (context, index) {
            final election = elections[index];

            return FutureBuilder<bool>(
              future: _hasUserVotedForAllPosts(election.id),
              builder: (context, voteSnapshot) {
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerCard();
                }

                final hasVotedAllPosts = voteSnapshot.data ?? false;

                if (voted == hasVotedAllPosts) {
                  return _buildElectionCard(election, hasVotedAllPosts, index);
                } else {
                  return const SizedBox.shrink();
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: Colors.black,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: TabBar(
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Available Elections'),
                  Tab(text: 'Voted Elections'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                padding: const EdgeInsets.only(top: 16),
                itemBuilder: (context, index) => _buildShimmerCard(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: TabBar(
              labelColor: Colors.white,
              indicatorColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              controller: _tabController,
              tabs: const [
                Tab(text: 'Available Elections'),
                Tab(text: 'Voted Elections'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildElectionsTab(false),
                _buildElectionsTab(true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}