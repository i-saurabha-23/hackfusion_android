import 'package:flutter/material.dart';
import 'package:hackfusion/student/organiztionFundsUpload.dart';

// A simple "home content" widget for the default view
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, John!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.school, color: Colors.blueAccent),
              title: const Text("Your Courses"),
              subtitle: const Text("Tap to view course details"),
              onTap: () {
                // TODO: Navigate to courses page
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.library_books, color: Colors.green),
              title: const Text("Assignments"),
              subtitle: const Text("View or submit assignments"),
              onTap: () {
                // TODO: Navigate to assignments page
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.chat, color: Colors.orange),
              title: const Text("Discussions"),
              subtitle: const Text("Join class discussions"),
              onTap: () {
                // TODO: Navigate to discussions page
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  /// The widget currently displayed in the body.
  /// We start with the HomeContent as default.
  Widget _selectedContent = const HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Implement profile navigation or menu here
            },
          ),
        ],
      ),

      // Sidebar (Drawer) on the left side
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // A nicer drawer header with user account info
            UserAccountsDrawerHeader(
              accountName: const Text("John Doe"),
              accountEmail: const Text("student@example.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: NetworkImage(
                  "https://via.placeholder.com/150/09f/fff.png",
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context); // Closes the drawer
                setState(() {
                  // Show the default "HomeContent"
                  _selectedContent = const HomeContent();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text("Event Funds Approval"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  // Replace the body with OrganizationFundsUpload
                  _selectedContent = const OrganizationFundsUpload();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement settings content or navigation
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                // TODO: Implement logout
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // Body that updates based on _selectedContent
      body: Container(
        // Optional gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfffbc2eb), Color(0xffa6c1ee)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // Use an AnimatedSwitcher for a simple fade transition
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedContent,
          ),
        ),
      ),
    );
  }
}
