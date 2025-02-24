import 'package:flutter/material.dart';
import 'package:qr_bar_code/qr/src/qr_code.dart';

class QRCodeGenerator extends StatelessWidget {
  final String qrData;

  QRCodeGenerator({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Caretaker"),
      ),
      body: Center(
        child: Container(
          width: 350,
          height: 360,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.5), // Shadow color with opacity
                offset: Offset(4, 4), // Horizontal and vertical offset
                blurRadius: 6, // Softening the shadow
                spreadRadius: 1, // Extending the shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Ask your caretaker to scan this \n code to help you...",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                  height: 200,
                  width: 200,
                  child: QRCode(backgroundColor: Colors.white, data: qrData)),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
