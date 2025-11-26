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
              '"User", "You" and "Your" refers to you, the person using this app and compliant to these terms. '
              '"The Developer", "Ourselves", "We", "Our" and "Us", refers to the DogFecalScan developers. '
              '"Parties" refers to both the User and ourselves.',
            ),

            sectionTitle("App Usage"),
            bullet("DogFecalScan uses AI to analyze dog stool images and provide general dietary suggestions."),
            bullet("This app has been developed with veterinary consultation for educational purposes."),
            bullet("Dietary recommendations are based on general veterinary guidelines and stool analysis."),
            bullet("This tool is designed to assist pet owners but does not replace professional veterinary diagnosis."),
            bullet("For specific health concerns, persistent issues, or emergencies, consult your licensed veterinarian directly."),
            bullet("Always monitor your dog's response to dietary changes and seek professional advice if needed."),

            sectionTitle("Intellectual Property"),
            sectionText(
              "The DogFecalScan application and its contents are provided for personal, non-commercial use. "
              "You may not copy, modify, distribute, or use the app for any commercial purposes without explicit permission."
            ),

            sectionTitle("You Must Not:"),
            bullet("Republish, sell, rent, or sub-license any part of this app."),
            bullet("Reverse engineer, decompile, or attempt to extract the source code."),
            bullet("Use the app for any illegal, harmful, or commercial purposes."),
            bullet("Use the app in any way that could damage the app or impair anyone else's use of it."),

            sectionTitle("Data & Privacy"),
            bullet("DogFecalScan works fully offline."),
            bullet("No personal data, pet information, or images are collected, stored, or shared."),
            bullet("All image processing occurs locally on your device."),
            bullet("You retain full ownership and control of any images you process."),

            sectionTitle("Medical Disclaimer"),
            sectionText(
              "DogFecalScan is not a medical device and does not provide veterinary medical advice, diagnosis, or treatment. "
              "The information provided by this app is for educational and informational purposes only. "
              "Always seek the advice of a qualified veterinarian with any questions regarding your pet's health."
            ),

            sectionTitle("Limitation of Liability"),
            sectionText(
              "To the maximum extent permitted by applicable law, we exclude all representations, warranties, and conditions relating to the app "
              "and its use. In no event shall the developers be liable for any direct, indirect, special, incidental, or consequential damages "
              "arising out of the use or inability to use this app.",
            ),

            sectionTitle("Termination"),
            sectionText(
              "We may terminate or suspend your access to the app immediately, without prior notice or liability, for any reason whatsoever, "
              "including without limitation if you breach these Terms and Conditions."
            ),

            sectionTitle("Updates & Changes"),
            sectionText(
              "We reserve the right to amend these terms and conditions at any time. By continuing to use the app after changes are made, "
              "you accept the revised terms. It is your responsibility to review these terms periodically for updates.",
            ),

            sectionTitle("Governing Law"),
            sectionText(
              "These terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines, "
              "and you submit to the non-exclusive jurisdiction of the courts located there for the resolution of any disputes."
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