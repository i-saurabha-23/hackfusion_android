import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Elections_Votes/view_result_page.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class Elections extends StatefulWidget {
  const Elections({Key? key}) : super(key: key);

  @override
  State<Elections> createState() => _ElectionsState();
}

class _ElectionsState extends State<Elections>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              mainAxisSize: MainAxisSize.min, // Add this
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // Wrap the first row in Expanded
                  child: Row(
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
                      Expanded(
                        // Add this to prevent text overflow
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Add this
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 20 to 16
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

  Widget _buildElectionsList() {
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
                  Icons.how_to_vote_outlined,
                  color: Colors.black38,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No elections available',
                  style: TextStyle(fontSize: 18, color: Colors.black38),
                ),
              ],
            ),
          );
        }
        final elections = snapshot.data!.docs;

        return ListView(
          children: elections.map((election) {
            final creationDateString = election['creationDate'] as String;
            final creationDate = DateTime.parse(creationDateString);
            final formattedDate = DateFormat('dd-MM-yyyy').format(creationDate);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 24,
                    child:
                        Icon(Icons.how_to_vote, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    election['post'] ?? 'Election',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text('Start Date: $formattedDate',
                      style: const TextStyle(color: Colors.black45)),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViewResultPage(electionId: election.id),
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Elections",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              padding: const EdgeInsets.only(top: 16),
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : _buildElectionsList(),
    );
  }
}
