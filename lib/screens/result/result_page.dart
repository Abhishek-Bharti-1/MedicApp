import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

class ResultPage extends StatefulWidget {
  final String responseData;
  final String image;

  const ResultPage({super.key,
   required this.responseData, required this.image,
   });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _flashTimer;
  Timer? _stopTimer;
  bool _torchOn = false;
  bool _isRunning = false;
  late Map<String, dynamic> _resultJson;
  bool _isJsonValid = true;

  @override
  void initState() {
    super.initState();
     _parseResponse();
  }

   void _parseResponse() {
    try {
      _resultJson = jsonDecode(widget.responseData) as Map<String, dynamic>;
    } catch (e) {
      // If the response isn’t valid JSON, mark as invalid
      _isJsonValid = false;
      _resultJson = {};
    }

    if(_isJsonValid){
      if(_resultJson['seizure'] == true) {
        _startAlarm();
        FirebaseAuth auth = FirebaseAuth.instance;
        String? patientId = auth.currentUser?.uid;

        try{
            sendAlert(patientId!);
        }catch (e) {
          print('Error sending alert: $e');
        }

        setState(() => _isRunning = true);
      } else {
        _stopAlarm();
      }
    }
  }

  void sendAlert(String patientId) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('sendAlertToCaretaker');
    try {
      final result = await callable.call({'topic': patientId});
      print('Alert sent: ${result.data}');
    } catch (e) {
      print('Failed to send alert: $e');
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _stopAlarm();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _flashTimer?.cancel();
    _stopTimer?.cancel();
  }

  Future<void> _startAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/alert.mp3'));

    _flashTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) async {
        try {
          if (_torchOn) {
            await TorchLight.disableTorch();
          } else {
            await TorchLight.enableTorch();
          }
          _torchOn = !_torchOn;
        } catch (_) {}
      },
    );

    _stopTimer = Timer(
      const Duration(minutes: 2),
      () {
        _stopAlarm();
        if (mounted) setState(() => _isRunning = false);
      },
    );
  }

  Future<void> _stopAlarm() async {
    _cancelTimers();
    await _audioPlayer.stop();
    if (_torchOn) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
      _torchOn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopAlarm();
            Navigator.pop(context);
          },
        ),
      ),
      body: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Text(
            _resultJson['seizure'] ? 'Seizure Detected' : 'Seizure Not Detected',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
      
          Image.asset(widget.image, width: screenWidth, height: 100),
          const SizedBox(height: 20),
          const Text(
            'Confidence',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            "${(_resultJson['confidence'] * 100.0).toStringAsFixed(2)} %" ,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          
          
          ElevatedButton.icon(
            icon: Icon(_isRunning ? Icons.stop : Icons.flash_on),
            label: Text(_isRunning ? 'Stop Alert' : 'Alert Stopped'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: _isRunning
                ? () {
                    _stopAlarm();
                    setState(() => _isRunning = false);
                  }
                : null,
          ),
        ]),
      ),
    );
  }
}
