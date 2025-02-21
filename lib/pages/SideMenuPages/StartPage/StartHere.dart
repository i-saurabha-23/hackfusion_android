import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Grid Pages/CampusVenueBookings.dart'; // Import the CampusVenueBookings screen

class StartHere extends StatefulWidget {
  const StartHere({Key? key}) : super(key: key);

  @override
  State<StartHere> createState() => _StartHereState();
}

class _StartHereState extends State<StartHere> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mapping each document id to its corresponding icon, color, and route.
  final Map<String, Map<String, dynamic>> categoryProperties = {
    'CAMPUS-BOOKING': {
      'icon': Icons.book_online,
      'color': Colors.purple,
      // The route is not used here since we'll push CampusVenueBookings directly.
      'route': '/campus-venue-bookings',
    },
    'Election Results': {
      'icon': Icons.how_to_vote,
      'color': Colors.green,
      'route': '/elections',
    },
    'Events': {
      'icon': Icons.event,
      'color': Colors.blue,
      'route': '/events',
    },
    'CHEATING-RECORD': {
      'icon': Icons.warning,
      'color': Colors.orange,
      'route': '/cheatings',
    },
    'Complaints': {
      'icon': Icons.report_problem,
      'color': Colors.red,
      'route': '/complaints',
    },
    'Annual Budget': {
      'icon': Icons.assessment,
      'color': Colors.teal,
      'route': '/budget',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection("SHOW-ALL").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No items found."));
            }
            final docs = snapshot.data!.docs;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                // Use the document's ID as the title.
                final String docId = doc.id;
                // Lookup the properties for this document; if not found, apply defaults.
                final properties = categoryProperties[docId] ??
                    {
                      'icon': Icons.widgets,
                      'color': Colors.blue,
                      'route': '/',
                    };
                final icon = properties['icon'] as IconData;
                final color = properties['color'] as Color;
                final route = properties['route'] as String;

                return InkWell(
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  onTap: () {
                    if (docId == "CAMPUS-BOOKING") {
                      // For CAMPUS-BOOKING, push CampusVenueBookings screen directly.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CampusVenueBookings(),
                        ),
                      );
                    } else {
                      // Otherwise, use the named route.
                      Navigator.pushNamed(context, route);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 40, color: Colors.white),
                          const SizedBox(height: 12),
                          Text(
                            docId,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
