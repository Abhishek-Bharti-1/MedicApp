import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
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
import 'package:medicapp/screens/result/result_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_exercises_card.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? locationData;
  bool isLoading = true;
  String? _role;
  String? _uid;
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _itemsFuture = loadItemsFromAsset();
  }

  Future<void> _loadDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('userRole') ?? 'No role selected';
      final User? user = FirebaseAuth.instance.currentUser;
      _uid = prefs.getString('uid') ?? user!.uid;
    });
  }

  Future<void> _fetchLocationData() async {
    try {
      print("uid: $_uid");
      DocumentSnapshot<Map<String, dynamic>> patientUidSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc('oHqejth9h7OecIa7BIYrDaICwpH3')
              .get();

      if (patientUidSnapshot.exists) {
        Map<String, dynamic>? data = patientUidSnapshot.data();
        print(data.toString());
        if (data != null && data.containsKey('Patient')) {
          DocumentSnapshot<Map<String, dynamic>> lastLocationSnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['Patient'])
                  .collection('location')
                  .doc('last_location')
                  .get();

          if (lastLocationSnapshot.exists) {
            setState(() {
              locationData = lastLocationSnapshot.data();
              isLoading = false;
            });
            _launchGoogleMaps(locationData?['latitude'] ?? 31.326015,
                locationData?['longitude'] ?? 75.576180);
          } else {
            print("data does not exist");
            setState(() {
              isLoading = false;
            });
          }
        } else {
          print("data does not contain Patient field");
          setState(() {
            isLoading = false;
          }); // Log th
          return; // 'Patient' field not found or data is null.
        }
      } else {
        print("data snapshot does not exist");
        setState(() {
          isLoading = false;
        }); // Log th
        return; // Document does not exist.
      }
    } catch (e) {
      print('Error getting Patient token: $e');
      setState(() {
        isLoading = false;
      }); // Log the error
      return; // Return null on error.
    }
  }

  Future<void> _updateLocation() async {
    final firestore = FirebaseFirestore.instance;

    DocumentReference userRef = firestore.collection('users').doc(_uid);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
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

  Future<List<Map<String, dynamic>>> loadItemsFromAsset() async {
    // 1. Load the raw JSON string
    final jsonString = await rootBundle.loadString('assets/data/items.json');

    // 2. Decode into a List<dynamic>
    final List<dynamic> jsonList = jsonDecode(jsonString);

    // 3. Cast each entry into Map<String, dynamic>
    return jsonList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _createHomeBody(BuildContext context) {
    return ListView(
      // padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _createProfileData(context),
        const SizedBox(height: 35),
        const HomeStatistics(),
        const SizedBox(height: 30),
        if (_role == 'Patient')
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    final items = await _itemsFuture;
                    _showDropdownDialog(context, items);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const ResultPage()),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(MediaQuery.of(context).size.width * 0.6, 60),
                    backgroundColor: ColorConstants.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  child: const Text('Analyse Data', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              )),
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
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 20),
              WorkoutCard(
                color: ColorConstants.cardioColor,
                workout: _role == 'Patient'
                    ? DataConstants.homeWorkouts[0]
                    : DataConstants.homeWorkouts[3],
                image: "assets/icons/home/map.png",
                onTap: () async {
                  try {
                    _role == 'Patient'
                        ? await _updateLocation()
                        : await _fetchLocationData();
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
                  workout: _role == 'Patient'
                      ? DataConstants.homeWorkouts[2]
                      : DataConstants.homeWorkouts[4],
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
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              // width : MediaQuery.of(context).size.width * 0.7,
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
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.28,
            child: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (_, currState) => currState is ReloadImageState,
              builder: (context, state) {
                final photoUrl =
                    FirebaseAuth.instance.currentUser?.photoURL ?? null;
                return GestureDetector(
                  child: photoUrl == null
                      ? const CircleAvatar(
                          backgroundImage: AssetImage(PathConstants.profile),
                          radius: 55)
                      : CircleAvatar(
                          radius: 25,
                          child: ClipOval(
                              child: FadeInImage.assetNetwork(
                                  placeholder: PathConstants.profile,
                                  image: photoUrl,
                                  fit: BoxFit.cover,
                                  width: 170,
                                  height: 110))),
                  onTap: () async {
                    await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditAccountScreen()));
                    BlocProvider.of<HomeBloc>(context).add(ReloadImageEvent());
                  },
                );
              },
            ),
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

  Future<void> _showDropdownDialog(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) async {
    Map<String, dynamic>? selectedItem;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Sample'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<Map<String, dynamic>>(
                value: selectedItem,
                hint: const Text("Choose a sample"),
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: item,
                    child: Text(item['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedItem = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedItem != null) {
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // user can’t dismiss by tapping outside
                    builder: (_) => AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Analyzing, please wait...',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          // CircularProgressIndicator(),
                          Lottie.asset(
                            'assets/animations/loading.json', // put your Lottie file here
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  );

                  try {
                    // Grab the List<double> from the JSON
                    final List<dynamic> dataArray = selectedItem!['data'];
                    final response = await http.post(
                      Uri.parse(
                          'https://seizure-predictor-api.onrender.com/predict'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'data': dataArray,
                      }),
                    );

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultPage(
                            responseData: response.body,
                            image: selectedItem!['image'] as String,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // 3) On error, also pop the loading dialog (if still up)
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Request failed: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a sample')),
                  );
                }
              },
              child: const Text('Submit'),
            )
          ],
        );
      },
    );
  }
}
