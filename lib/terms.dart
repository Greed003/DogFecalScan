import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // brown background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Terms and Conditions",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Welcome to DogFecalScan!"),
            sectionText(
              "These terms and conditions outline the rules and regulations for the use of the DogFecalScan mobile application. "
              "By accessing or using this app, we assume you accept these terms and conditions. Do not continue to use DogFecalScan "
              "if you do not agree to all of the terms stated on this page.",
            ),

            sectionTitle("Definitions"),
            sectionText(
              '"Client", "You" and "Your" refers to you, the person using this app and compliant to these terms. '
              '"The Company", "Ourselves", "We", "Our" and "Us", refers to the DogFecalScan developers. '
              '"Party", "Parties", or "Us", refers to both the Client and ourselves.',
            ),

            sectionTitle("App Usage"),
            bullet("DogFecalScan uses AI to classify dog stool images for educational purposes."),
            bullet("The app does not provide veterinary medical advice or a professional diagnosis."),
            bullet("You should consult a licensed veterinarian for any health concerns."),

            sectionTitle("License"),
            sectionText(
              "Unless otherwise stated, DogFecalScan and/or its licensors own the intellectual property rights "
              "for all material in the app. You may access and use the app for your own personal purposes, "
              "subject to the restrictions set in these terms and conditions.",
            ),

            sectionTitle("You Must Not:"),
            bullet("Republish, sell, rent, or sub-license any part of this app."),
            bullet("Reproduce, duplicate or copy material from this app."),
            bullet("Use the app for any illegal, harmful, or commercial purposes."),

            sectionTitle("Data & Privacy"),
            bullet("DogFecalScan works fully offline."),
            bullet("No personal or pet data is collected or shared."),
            bullet("Any images remain on your device unless you share them manually."),

            sectionTitle("Limitation of Liability"),
            sectionText(
              "To the maximum extent permitted by applicable law, we exclude all warranties and conditions relating to the app "
              "and its use. We shall not be held responsible for any decisions or outcomes resulting from the use of this app.",
            ),

            sectionTitle("Updates & Changes"),
            sectionText(
              "We reserve the right to amend these terms and conditions at any time. Continued use of the app means that you "
              "accept any changes made to these terms.",
            ),

          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}