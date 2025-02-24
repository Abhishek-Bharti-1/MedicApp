import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;
  bool _isProcessing = false;
  bool _hasScanned = false;

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (_hasScanned) return; // Ignore if already scanned

    final scannedValue = barcodes.barcodes.firstOrNull?.displayValue;
    if (scannedValue != null) {
      setState(() {
        _hasScanned = true;
        _isProcessing = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final User? user = FirebaseAuth.instance.currentUser;
      final uid = prefs.getString('uid') ?? user?.uid;

      if (uid == null) {
        setState(() {
          _isProcessing = false;
          _hasScanned = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      try {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.update({'Patient': scannedValue});

        DocumentReference patientRef =
            FirebaseFirestore.instance.collection('users').doc(scannedValue);
        await patientRef.update({'CareTaker': uid});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully linked to patient.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update data: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
        Navigator.of(context).pop(); // Close the scanner screen
      }
    }
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  // void _handleBarcode(BarcodeCapture barcodes) async {
  //   if (mounted) {
  //     setState(() {
  //       _barcode = barcodes.barcodes.firstOrNull;
  //     });
  //     final prefs = await SharedPreferences.getInstance();
  //     final User? user = FirebaseAuth.instance.currentUser;
  //     final uid = prefs.getString('uid') ?? user!.uid;

  //     DocumentReference userRef =
  //         FirebaseFirestore.instance.collection('users').doc(uid);
  //     try {
  //       await userRef
  //           .update({'Patient': _barcode?.displayValue.toString() ?? ''});
  //     } catch (e) {
  //       print('Error updating patient token: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update patient token.')),
  //       );
  //     }

  //     DocumentReference userRef2 =
  //         FirebaseFirestore.instance.collection('users').doc(_barcode?.displayValue.toString());
  //     try {
  //       await userRef2
  //           .update({'CareTaker': uid});
  //     } catch (e) {
  //       print('Error updating caretaker token: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update caretaker token.')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      backgroundColor: Colors.black,
      body: _isProcessing ?
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ) : Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _buildBarcode(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
