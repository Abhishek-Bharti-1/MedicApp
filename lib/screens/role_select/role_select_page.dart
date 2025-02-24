import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicapp/core/const/color_constants.dart';
import 'package:medicapp/screens/tab_bar/page/tab_bar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  Future<void> _storeRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final User? user = FirebaseAuth.instance.currentUser;
    await prefs.setString('userRole', role);
    final uid = prefs.getString('uid') ?? user!.uid;

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      // Update the 'role' field
      await userRef.update({'role': role});
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Role updated successfully.')),
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TabBarPage(role: role)),
      );
      // );
    } catch (e) {
      print('Error updating role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Select Role",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await _storeRole("Patient");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Role saved as Patient")),
              );
            },
            child: Container(
              width: 220,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor, // Background color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/home/patient.png",
                    width: 80, // Adjust size as needed
                    height: 80,
                  ), // Space between image and text
                  Text(
                    "Patient",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ElevatedButton(
          //   style: ButtonStyle(
          //       backgroundColor: WidgetStatePropertyAll(Colors.blueAccent)),
          //   onPressed: () async {
          //     await _storeRole("Patient");
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text("Role saved as Patient")),
          //     );
          //   },
          //   child: Text("Patient", style: TextStyle(
          //       fontWeight: FontWeight.w600, color: Colors.white)),
          // ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await _storeRole("Caretaker");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Role saved as Caretaker")),
              );
            },
            child: Container(
              width: 220,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor, // Background color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Caretaker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  Image.asset(
                    "assets/icons/home/caretaker.png",
                    width: 80, // Adjust size as needed
                    height: 80,
                  ), // Space between image and text
                ],
              ),
            ),
          ),
          // Spacing between buttons
          // ElevatedButton(
          //   style: ButtonStyle(
          //       backgroundColor: WidgetStatePropertyAll(Colors.blueAccent)),
          //   onPressed: () async {
          //     await _storeRole("Caretaker");
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text("Role saved as Caretaker")),
          //     );
          //   },
          //   child: Text("Caretaker", style: TextStyle(
          //       fontWeight: FontWeight.w600, color: Colors.white)),
          // ),
        ],
      ),
    ));
  }
}
