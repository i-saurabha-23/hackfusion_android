import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'OrganizationDetails.dart';

class OrganizationPage extends StatefulWidget {
  const OrganizationPage({Key? key}) : super(key: key);

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  String _loggedInEmail = '';

  @override
  void initState() {
    super.initState();
    _getLoggedInEmail();
  }

  // Retrieve logged-in email from local storage
  Future<void> _getLoggedInEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInEmail = prefs.getString('email') ?? ''; // Adjust the key based on your storage
    });
  }

  // This method will return the stream of organizations
  Stream<List<Map<String, String>>> _getOrganizationsStream() async* {
    var organizationSnapshot = await FirebaseFirestore.instance.collection('Organization').get();
    List<Map<String, String>> organizations = [];

    for (var organizationDoc in organizationSnapshot.docs) {
      // Check if the logged-in email exists in the 'Core-Committee' sub-collection
      var coreCommitteeSnapshot = await organizationDoc.reference.collection('Core-Committee').get();

      for (var memberDoc in coreCommitteeSnapshot.docs) {
        if (memberDoc.id == _loggedInEmail) {
          // Found the logged-in email in the core committee
          organizations.add({
            'organizationName': organizationDoc.id,
            'designation': memberDoc['designation'] ?? 'Unknown',
          });
        }
      }
    }

    yield organizations;  // Yielding the list of organizations
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loggedInEmail.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : StreamBuilder<List<Map<String, String>>>(
        stream: _getOrganizationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching organizations'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No organizations found',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            );
          } else {
            var organizations = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        organizations[index]['organizationName']!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Designation: ${organizations[index]['designation']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black,
                      ),
                      onTap: () {
                        // Pass the organizationId from the _organizations list
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrganizationDetails(
                              organizationId: organizations[index]['organizationName']!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
