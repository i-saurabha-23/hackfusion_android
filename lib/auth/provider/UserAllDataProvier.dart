import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  final RxString userEmail = ''.obs;
  final RxString userName = ''.obs;
  final RxString userGender = ''.obs;
  final RxString userAddress = ''.obs;
  final RxString userDepartment = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userRollNo = ''.obs;
  final RxString userSection = ''.obs;
  final RxString userUniversityRollNo = ''.obs;
  final RxString userYear = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserEmail();
  }

  // Load the email from SharedPreferences
  Future<void> loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    if (email != null && email.isNotEmpty) {
      userEmail.value = email;
      fetchStudentDetails(email); // Fetch student details after loading email
    }
  }

  // Set the email and store it in SharedPreferences
  Future<void> setUserEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    userEmail.value = email;
    fetchStudentDetails(email); // Fetch student details after setting email
  }

  // Logout and clear email from SharedPreferences
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    userEmail.value = '';
    clearUserDetails(); // Clear other user details
  }

  // Fetch student details from Firestore
  Future<void> fetchStudentDetails(String email) async {
    try {
      // Fetch student document from Firestore where email is the key
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('Students')
          .doc(email)
          .get();

      if (studentDoc.exists) {
        // Update the user details
        var data = studentDoc.data() as Map<String, dynamic>;

        userName.value = data['name'] ?? '';
        userGender.value = data['gender'] ?? '';
        userAddress.value = data['address'] ?? '';
        userDepartment.value = data['department'] ?? '';
        userPhone.value = data['phone'] ?? '';
        userRollNo.value = data['rollNo'] ?? '';
        userSection.value = data['section'] ?? '';
        userUniversityRollNo.value = data['universityRollNo'] ?? '';
        userYear.value = data['year'] ?? '';
      } else {
        // If document doesn't exist, clear the details
        clearUserDetails();
      }
    } catch (e) {
      print("Error fetching student details: $e");
      clearUserDetails(); // Clear details if there's an error
    }
  }

  // Clear all the user details if not found or on logout
  void clearUserDetails() {
    userName.value = '';
    userGender.value = '';
    userAddress.value = '';
    userDepartment.value = '';
    userPhone.value = '';
    userRollNo.value = '';
    userSection.value = '';
    userUniversityRollNo.value = '';
    userYear.value = '';
  }
}
