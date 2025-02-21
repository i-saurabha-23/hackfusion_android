import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hackfusion_android/pages/SideMenuPages/CampusBooking/booking.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Cheating/Cheating.dart';
import 'package:hackfusion_android/pages/SideMenuPages/Elections_Votes/ActiveElection.dart';
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
    Page1(),
    OrganizationPage(),
    ComplaintPage(),
    CampusBooking(),
    ActiveElection(),
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
              _buildDrawerItem(Icons.warning_rounded, 'Campus Venue Booking', 3),
              _buildDrawerItem(Icons.how_to_vote_outlined, 'Elections', 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(color: Colors.grey.shade300, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.grey.shade700),
                title: Text(
                  'Profile',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: Colors.grey.shade700),
                title: Text(
                  'Settings',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.grey.shade700),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                onTap: logout,
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


class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF6C63FF),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Edit profile action
            },
          ),
        ],
      ),
      body: Obx(() {
        if (userController.userEmail.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 70, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No user details available.',
                  style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to login page
                  },
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C63FF).withOpacity(0.9), Colors.white],
              stops: [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          userController.userName.value.isNotEmpty
                              ? userController.userName.value[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        userController.userName.value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        userController.userEmail.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${userController.userDepartment.value} - ${userController.userYear.value}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Personal Information Card
                _buildInfoCard(
                  "Personal Information",
                  Icons.person,
                  [
                    {"label": "Name", "value": userController.userName.value},
                    {"label": "Gender", "value": userController.userGender.value},
                    {"label": "Address", "value": userController.userAddress.value},
                    {"label": "Phone", "value": userController.userPhone.value},
                  ],
                ),

                // Academic Information Card
                _buildInfoCard(
                  "Academic Information",
                  Icons.school,
                  [
                    {"label": "Department", "value": userController.userDepartment.value},
                    {"label": "Year", "value": userController.userYear.value},
                    {"label": "Section", "value": userController.userSection.value},
                    {"label": "Roll No", "value": userController.userRollNo.value},
                    {"label": "University Roll No", "value": userController.userUniversityRollNo.value},
                  ],
                ),

                // Parent Information Card
                _buildInfoCard(
                  "Parents Information",
                  Icons.family_restroom,
                  [
                    {"label": "Name", "value": userController.userParentsName.value},
                    {"label": "Email", "value": userController.userParentsEmail.value},
                    {"label": "Mobile", "value": userController.userParentsMob.value},
                  ],
                ),

                // Account Information Card
                _buildInfoCard(
                  "Account Information",
                  Icons.lock,
                  [
                    {"label": "Email", "value": userController.userEmail.value},
                    {"label": "Password", "value":userController.userPassword.value},
                  ],
                ),

                SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Map<String, String>> items) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF6C63FF)),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                items.length,
                    (index) => Padding(
                  padding: EdgeInsets.only(bottom: index < items.length - 1 ? 16 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(0xFF6C63FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index]["label"]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            items[index]["value"]!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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