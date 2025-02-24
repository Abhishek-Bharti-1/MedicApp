import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medicapp/core/const/color_constants.dart';
import 'package:medicapp/core/const/data_constants.dart';
import 'package:medicapp/core/const/path_constants.dart';
import 'package:medicapp/core/const/text_constants.dart';
import 'package:medicapp/screens/edit_account/edit_account_screen.dart';
import 'package:medicapp/screens/home/bloc/home_bloc.dart';
import 'package:medicapp/screens/home/widget/home_statistics.dart';
import 'package:medicapp/screens/news/news_page.dart';
import 'package:medicapp/screens/qr_code/qr_scanner_screen.dart';
import 'package:medicapp/screens/qr_code/qr_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_exercises_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _role;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('userRole') ?? 'No role selected';
      final User? user = FirebaseAuth.instance.currentUser;
      _uid = prefs.getString('uid') ?? user!.uid;
    });
  }

  Future<void> _updateLocation() async {
    // Initialize Firestore
    final firestore = FirebaseFirestore.instance;
    // Reference to the 'users' collection
    DocumentReference userRef = firestore.collection('users').doc(_uid);

    // Add a new user document
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

    // Attempt to get the current location
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Add 'last_location' document in 'location' subcollection
      await userRef.collection('location').doc('last_location').set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location updated successfully.')),
      );

      print('User added with ID: ${userRef.id} and location saved.');
    } catch (locationError) {
      // Handle location retrieval errors
      print('Failed to get location: $locationError');
      // Optionally, delete the user document if location is essential
      await userRef.delete();
      print('User document deleted due to location error.');
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    final Uri uri = Uri.parse(googleMapsUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)) {
      //   await launchUrl(uri);
      // } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: ColorConstants.homeBackgroundColor,
        height: double.infinity,
        width: double.infinity,
        child: _createHomeBody(context),
      ),
    );
  }

  Widget _createHomeBody(BuildContext context) {
    return ListView(
      // padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _createProfileData(context),
        const SizedBox(height: 35),
        const HomeStatistics(),
        const SizedBox(height: 30),
        _createExercisesList(context),
        const SizedBox(height: 25),
        _createProgress(),
      ],
    );
  }

  Widget _createExercisesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            TextConstants.discoverWorkouts,
            style: TextStyle(
              color: ColorConstants.textBlack,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 20),
              WorkoutCard(
                color: ColorConstants.cardioColor,
                workout: DataConstants.homeWorkouts[0],
                image: "assets/icons/home/map.png",
                onTap: () async {
                  try {
                    _role == 'Patient'
                        ? await _updateLocation()
                        : await _launchGoogleMaps(31.326015, 75.576180);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                },
                // onTap: () => Navigator.of(context).push(MaterialPageRoute(
                //     builder: (_) => WorkoutDetailsPage(
                //           workout: DataConstants.workouts[0],
                //         ))
              ),
              const SizedBox(width: 15),
              WorkoutCard(
                  color: ColorConstants.armsColor,
                  workout: DataConstants.homeWorkouts[1],
                  image: "assets/icons/home/newspaper.png",
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => NewsScreen()))),
              const SizedBox(width: 15),
              WorkoutCard(
                  color: ColorConstants.cardioColor2,
                  workout: DataConstants.homeWorkouts[2],
                  image: PathConstants.qr_code,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _role == 'Patient'
                        ? QRCodeGenerator(qrData: '${_uid}')
                        : BarcodeScannerSimple(),
                      ))),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createProfileData(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "No Username";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $displayName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _role == "Patient"
                    ? TextConstants.checkActivity1
                    : TextConstants.checkActivity2,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (_, currState) => currState is ReloadImageState,
            builder: (context, state) {
              final photoUrl =
                  FirebaseAuth.instance.currentUser?.photoURL ?? null;
              return GestureDetector(
                child: photoUrl == null
                    ? const CircleAvatar(
                        backgroundImage: AssetImage(PathConstants.profile),
                        radius: 60)
                    : CircleAvatar(
                        radius: 25,
                        child: ClipOval(
                            child: FadeInImage.assetNetwork(
                                placeholder: PathConstants.profile,
                                image: photoUrl,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 120))),
                onTap: () async {
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditAccountScreen()));
                  BlocProvider.of<HomeBloc>(context).add(ReloadImageEvent());
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _createProgress() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ColorConstants.white,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.textBlack.withOpacity(0.12),
            blurRadius: 5.0,
            spreadRadius: 1.1,
          ),
        ],
      ),
      child: const Row(
        children: [
          Image(
            image: AssetImage(
              PathConstants.progress,
            ),
          ),
          SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextConstants.keepProgress,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  TextConstants.profileSuccessful,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
