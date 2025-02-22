import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hackfusion_android/pages/SideMenuPages/StartPage/Grid%20Pages/Cheatings.dart';
import 'package:hackfusion_android/pages/SideMenuPages/StartPage/Grid%20Pages/Elections.dart';
import 'Grid Pages/CampusVenueBookings.dart';
import 'Grid Pages/Complaints.dart';

class StartHere extends StatefulWidget {
  const StartHere({Key? key}) : super(key: key);

  @override
  State<StartHere> createState() => _StartHereState();
}

class _StartHereState extends State<StartHere> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, dynamic>> categoryProperties = {
    'CAMPUS-BOOKING': {
      'icon': Icons.book_online,
      'color': Color(0xFF845EC2),
      'description': 'Book venues for your events',
      'route': '/campus-venue-bookings',
    },
    'ELECTIONS': {
      'icon': Icons.how_to_vote,
      'color': Color(0xFF00C2A8),
      'description': 'Campus election portal',
      'route': '/elections',
    },
    'Events': {
      'icon': Icons.event,
      'color': Color(0xFF2C73D2),
      'description': 'Upcoming campus events',
      'route': '/events',
    },
    'CHEATING-RECORD': {
      'icon': Icons.warning,
      'color': Color(0xFFFF6F91),
      'description': 'Report academic misconduct',
      'route': '/cheatings',
    },
    'COMPLAINTS': {
      'icon': Icons.report_problem,
      'color': Color(0xFFFF9671),
      'description': 'Submit your complaints',
      'route': '/complaints',
    },
    'Annual Budget': {
      'icon': Icons.assessment,
      'color': Color(0xFF4B4453),
      'description': 'View financial details',
      'route': '/budget',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("SHOW-ALL").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF845EC2)),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No items found",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  return AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final String docId = doc.id;
                        final properties = categoryProperties[docId] ?? {
                          'icon': Icons.widgets,
                          'color': Colors.blue,
                          'description': 'No description available',
                          'route': '/',
                        };

                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () {
                                  switch (docId) {
                                    case "CAMPUS-BOOKINGS":
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => const CampusVenueBookings(),
                                      ));
                                      break;
                                    case "CHEATING-RECORD":
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => CheatingRecords(),
                                      ));
                                      break;
                                    case "COMPLAINTS":
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => const Complaints(),
                                      ));
                                      break;
                                    case "ELECTIONS":
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => const Elections(),
                                      ));
                                      break;
                                    default:
                                      Navigator.pushNamed(context, properties['route']);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: properties['color'].withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: properties['color'].withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          properties['icon'],
                                          size: 32,
                                          color: properties['color'],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        docId,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          properties['description'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}