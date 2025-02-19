import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackfusion_android/pages/EventsTab.dart'; // Assuming EventsTab is defined

class OrganizationDetails extends StatefulWidget {
  final String organizationId; // Required to get the organization details

  const OrganizationDetails({
    Key? key,
    required this.organizationId, // Accept organizationId to fetch data
  }) : super(key: key);

  @override
  State<OrganizationDetails> createState() => _OrganizationDetailsState();
}

class _OrganizationDetailsState extends State<OrganizationDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Organization')
              .doc(widget.organizationId) // Stream organization document by organizationId
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            } else if (snapshot.hasError) {
              return const Text('Error loading organization');
            } else if (snapshot.hasData && snapshot.data!.exists) {
              var organizationData = snapshot.data!.data() as Map<String, dynamic>;
              return Text(
                widget.organizationId,
                style: TextStyle(color: Colors.white),
              );
            } else {
              return const Text('Organization not found');
            }
          },
        ),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Events'),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.red,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Organization')
            .doc(widget.organizationId) // Stream organization details by organizationId
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading organization details'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Organization not found'));
          } else {
            var organizationDetails = snapshot.data!.data() as Map<String, dynamic>;

            return TabBarView(
              controller: _tabController,
              children: [
                // Organization Details Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization: ${widget.organizationId}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Description: ${organizationDetails['description'] ?? 'No description available.'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // Core Committee Table
                      const Text(
                        'Core Committee:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildCoreCommitteeTable(),
                    ],
                  ),
                ),
                // Events Tab
                EventsTab(organizationId: widget.organizationId), // Pass organizationId to EventsTab
              ],
            );
          }
        },
      ),
    );
  }

  // Helper function to build the core committee section using Table
  Widget _buildCoreCommitteeTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Organization')
          .doc(widget.organizationId)
          .collection('Core-Committee') // Fetch the core committee members
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading core committee'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No core committee members available');
        } else {
          var coreCommittee = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          return Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2), // Name column width
              1: FlexColumnWidth(2), // Designation column width
              2: FlexColumnWidth(3), // Email column width
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade100),
                children: const [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Designation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              // Loop through each core committee member
              ...coreCommittee.map((member) {
                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(member['name'] ?? 'N/A'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(member['designation'] ?? 'N/A'),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(member['email'] ?? 'N/A'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }
}
