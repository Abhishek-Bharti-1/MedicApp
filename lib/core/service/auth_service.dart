import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medicapp/core/extensions/exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static Future<User> signUp(String email, String password, String name) async {
    UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password.trim());
    final User user = result.user!;
    await user.updateDisplayName(name);
    await addUser(user, name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    return user;
  }

  static Future<void> addUser(User user, String name) async {
    // Initialize Firestore
    final firestore = FirebaseFirestore.instance;

    try {
      // Reference to the 'users' collection
      DocumentReference userRef = firestore.collection('users').doc(user.uid);

      // Add a new user document
      await userRef.set({
        'name': name, // Replace with actual data
        'email': user.email,
      });

       // Check location services and permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        // Handle accordingly, e.g., prompt the user to enable location services
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied.');
          // Handle accordingly, e.g., inform the user and skip location fetching
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permissions are permanently denied. We cannot request permissions.');
        // Handle accordingly, e.g., direct the user to app settings
        return;
      }

      try {
        // Attempt to get the current location
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));

        // Add 'last_location' document in 'location' subcollection
        await userRef.collection('location').doc('last_location').set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('User added with ID: ${userRef.id} and location saved.');
      } catch (locationError) {
        // Handle location retrieval errors
        print('Failed to get location: $locationError');
        // Optionally, delete the user document if location is essential
        await userRef.delete();
        print('User document deleted due to location error.');
      }
    } catch (firestoreError) {
      // Handle Firestore errors
      print('Failed to add user: $firestoreError');
    }
  }

  static Future resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      throw CustomFirebaseException(getExceptionMessage(e));
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final User? user = result.user;

      if (user == null) {
        throw Exception("User not found");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw CustomFirebaseException(getExceptionMessage(e));
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<void> signOut() async {
    await auth.signOut();
  }
}

String getExceptionMessage(FirebaseAuthException e) {
  print(e.code);
  switch (e.code) {
    case 'user-not-found':
      return 'User not found';
    case 'wrong-password':
      return 'Password is incorrect';
    case 'requires-recent-login':
      return 'Log in again before retrying this request';
    default:
      return e.message ?? 'Error';
  }
}
