import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../auth/provider/UserAllDataProvier.dart';
import 'view_result_page.dart';
import 'voting_page.dart';

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

  Future<bool> _hasUserVoted(String electionId) async {
    try {
      final userVoteDoc = await _firestore
          .collection('SHOW-ALL')
          .doc('ELECTIONS')
          .collection('DATA')
          .doc(electionId)
          .collection('USERVOTES')
          .doc(userController.userEmail.value)
          .get();

      return userVoteDoc.exists && (userVoteDoc.data()?['voted'] ?? false);
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Simulate initial loading
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
    setState(() {
      // This will trigger a rebuild of the widget
    });
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
            height: 120,
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
            final creationDateString = election['creationDate'] as String;
            final creationDate = DateTime.parse(creationDateString);
            final formattedDate = DateFormat('dd-MM-yyyy').format(creationDate);

            return FutureBuilder<bool>(
              future: _hasUserVoted(election.id),
              builder: (context, voteSnapshot) {
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerCard();
                }

                bool hasVoted = voteSnapshot.data ?? false;

                if (hasVoted == voted) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: hasVoted ? Colors.black54 : Colors.black26,
                          width: 1,
                        ),
                      ),
                      color: Colors.white,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        childrenPadding: const EdgeInsets.only(
                            left: 20, right: 20, bottom: 20),
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 24,
                          child: Icon(
                            hasVoted ? Icons.how_to_vote : Icons.ballot,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          election['post'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: Colors.black45),
                                const SizedBox(width: 4),
                                Text(
                                  'Start Date: $formattedDate',
                                  style: const TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasVoted
                                      ? Icons.check_circle
                                      : Icons.pending_actions,
                                  size: 14,
                                  color:
                                      hasVoted ? Colors.black : Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasVoted
                                      ? 'You have voted'
                                      : 'Awaiting your vote',
                                  style: TextStyle(
                                    color: hasVoted
                                        ? Colors.black
                                        : Colors.black45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.expand_more, color: Colors.black),
                          ),
                        ),
                        children: [
                          const Divider(height: 24, color: Colors.black26),
                          const Text(
                            'Election Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This election was created on $formattedDate and is currently active. ' +
                                (hasVoted
                                    ? 'You have already cast your vote in this election.'
                                    : 'You can now cast your vote for your preferred candidate.'),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewResultPage(
                                          electionId: election.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.bar_chart),
                                label: const Text(
                                  'View Results',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (!hasVoted)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VotingPage(
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
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
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
}
