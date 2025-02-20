import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'voting_page.dart';
import 'view_result_page.dart';
import 'package:get/get.dart';
import '../../../auth/provider/UserAllDataProvier.dart';

class ActiveElection extends StatefulWidget {
  const ActiveElection({Key? key}) : super(key: key);

  @override
  State<ActiveElection> createState() => _ActiveElectionState();
}

class _ActiveElectionState extends State<ActiveElection> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userController = Get.find<UserController>(); // Get the user controller
  late TabController _tabController;

  Future<bool> _hasUserVoted(String electionId) async {
    try {
      // Fetch the user-specific vote document from USERCOLLECTION for the current election
      final userVoteDoc = await _firestore
          .collection('Elections')
          .doc(electionId)
          .collection('USERVOTES')
          .doc(userController.userEmail.value) // Current user's email as doc ID
          .get();

      if (!userVoteDoc.exists) {
        print('User vote document not found for user: ${userController.userEmail.value}');
        return false; // If the document doesn't exist, user hasn't voted
      }

      // If document exists, check if the 'voted' field is true
      bool voted = userVoteDoc.data()?['voted'] ?? false;
      print('User voted status: $voted'); // Debugging log
      return voted;
    } catch (e) {
      print("Error checking vote status: $e");
      return false; // In case of error, assume user has not voted
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elections'),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Available Elections'),
            Tab(text: 'Voted Elections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildElectionsTab(false), // Available Elections
          _buildElectionsTab(true),  // Voted Elections
        ],
      ),
    );
  }

  Widget _buildElectionsTab(bool voted) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Elections').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No active elections'));
        }

        final elections = snapshot.data!.docs
            .where((doc) => doc['isActive'] == true)
            .toList();

        return ListView.builder(
          itemCount: elections.length,
          itemBuilder: (context, index) {
            final election = elections[index];
            final creationDateString = election['creationDate'] as String;
            final creationDate = DateTime.parse(creationDateString);
            final formattedDate = DateFormat('dd-MM-yyyy').format(creationDate);

            return FutureBuilder<bool>(
              future: _hasUserVoted(election.id), // Check if the user has voted
              builder: (context, voteSnapshot) {
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (voteSnapshot.hasError) {
                  return Center(child: Text('Error: ${voteSnapshot.error}'));
                }

                bool hasVoted = voteSnapshot.data ?? false;

                if (hasVoted == voted) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        election['post'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Start Date: $formattedDate'),
                      trailing: Icon(Icons.arrow_drop_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewResultPage(electionId: election.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('View Result', style: TextStyle(fontSize: 16)),
                              ),
                              if (!hasVoted) // Only show Vote Now if user has not voted
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VotingPage(electionId: election.id),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Vote Now', style: TextStyle(fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return SizedBox.shrink(); // Return an empty widget if the election doesn't match the tab criteria
                }
              },
            );
          },
        );
      },
    );
  }
}
