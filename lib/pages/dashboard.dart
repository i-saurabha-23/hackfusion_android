import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/pages/SideMenuPages/CampusBooking/booking.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Elections_Votes/ActiveElection.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Profile/Page1.dart';
import 'package:hackfusion_android/pages/SideMenuPages/StartPage/StartHere.dart';

import '../auth/login.dart';
import '../auth/provider/UserAllDataProvier.dart';
import 'SideMenuPages/Complaint_Pages/complaint.dart';
import 'SideMenuPages/Organizations/organization.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    StartHere(),
    OrganizationPage(),
    ComplaintPage(),
    CampusBooking(),
    ActiveElection(),
    Page1(),
  ];
  final UserController userController = Get.put(UserController());

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.teal,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.sports_esports,
                          size: 40,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Squid Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
              _buildDrawerItem(Icons.groups_rounded, 'Organization', 1),
              _buildDrawerItem(Icons.report_problem_rounded, 'Complaints', 2),
              _buildDrawerItem(
                  Icons.warning_rounded, 'Campus Venue Booking', 3),
              _buildDrawerItem(Icons.how_to_vote_outlined, 'Elections', 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Other',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              _buildDrawerItem(Icons.person, 'Profile', 5),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.grey.shade700),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                onTap: () {
                  // Call your logout logic (if any) then navigate to the LoginScreen.
                  // For example, if you have a logout function:
                  logout();
                },
              ),

              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: _pages[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.teal : Colors.grey.shade700,
          size: 26,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.teal : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          _onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void logout() {
    userController.logout();
    Get.offAll(() => LoginPage());
  }
}

// Extension method to repeat strings
extension StringExtension on String {
  String repeat(int times) {
    String result = '';
    for (int i = 0; i < times; i++) {
      result += this;
    }
    return result;
  }
}
