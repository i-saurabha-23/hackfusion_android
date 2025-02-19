import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    const Page1(),
    const OrganizationPage(),
    const ComplaintPage(),
  ];
  final UserController userController = Get.put(UserController()); // Initialize userController

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Dashboard', style: TextStyle(color: Colors.red)),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Squid Game',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.red),
              title: const Text('Page 1', style: TextStyle(color: Colors.white)),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.red),
              title: const Text('Organization', style: TextStyle(color: Colors.white)),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.red),
              title: const Text('Complaint Page', style: TextStyle(color: Colors.white)),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Displays selected page
    );
  }

  void logout() {
    // Clear user data
    userController.logout();

    // Navigate back to login
    Get.offAll(() => LoginPage());
  }
}


class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch the userController instance using Get.find() method
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: Obx(() {
        // Check if the email is loaded and student details are available
        if (userController.userEmail.value.isEmpty) {
          return const Center(
            child: Text('No user details available.', style: TextStyle(fontSize: 20)),
          );
        }

        // Display the user details
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${userController.userName.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Gender: ${userController.userGender.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Address: ${userController.userAddress.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Department: ${userController.userDepartment.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Phone: ${userController.userPhone.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Roll No: ${userController.userRollNo.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Section: ${userController.userSection.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('University Roll No: ${userController.userUniversityRollNo.value}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Year: ${userController.userYear.value}', style: const TextStyle(fontSize: 18)),
            ],
          ),
        );
      }),
    );
  }
}
