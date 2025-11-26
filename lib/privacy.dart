import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'robertleo.ballasiw@lorma.edu',
      query: 'subject=Privacy Policy Inquiry',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle("Privacy Policy for DogFecalScan"),
              sectionText(
                "At DogFecalScan, one of our main priorities is the privacy of our users. "
                "This Privacy Policy explains how we handle information and how we protect your privacy while you use the app."
              ),

              sectionTitle("Consent"),
              sectionText(
                "By using DogFecalScan, you hereby consent to this Privacy Policy and agree to its terms."
              ),

              sectionTitle("Information We Process"),
              sectionText(
                "DogFecalScan does not require you to create an account or provide personal data. "
                "The app processes images locally on your device for analysis purposes only."
              ),
              bullet("Stool images – processed locally on your device and not stored by the app"),
              bullet("Timestamps – saved locally only if you choose to use the history feature"),
              bullet("Contact info – only used if you choose to contact a vet or send feedback"),

              sectionTitle("How We Use Your Information"),
              bullet("Analyze dog stool images locally using AI to provide dietary suggestions"),
              bullet("Save your scan history locally on your device (optional feature)"),
              bullet("Improve app functionality through user feedback (if provided)"),

              sectionTitle("Offline Operation"),
              sectionText(
                "DogFecalScan works completely offline. All image processing happens locally on your device. "
                "No data is sent to external servers, and we do not track, monitor, or collect user activity."
              ),

              sectionTitle("Data Storage & Security"),
              sectionText(
                "All data remains on your device. We do not use cookies, online tracking, or collect any analytics data. "
                "Your privacy is protected by the app's offline design."
              ),

              sectionTitle("Third-Party Services"),
              sectionText(
                "This app does not share your data with third-party advertisers or services. "
                "External features like contacting a vet will open outside the app and are subject to their own privacy policies."
              ),

              sectionTitle("Your Rights"),
              bullet("Right to Access – You can view all stored data from the History screen"),
              bullet("Right to Delete – You can clear all stored data using 'Clear History' in the app"),
              bullet("Right to Withdraw – You can uninstall the app at any time to remove all local data"),

              sectionTitle("Children's Privacy"),
              sectionText(
                "DogFecalScan does not knowingly collect any personal information from children under 13. "
                "The app is designed for pet owners and guardians."
              ),

              sectionTitle("Policy Updates"),
              sectionText(
                "We may update this Privacy Policy from time to time. Any changes will be reflected here, "
                "and we encourage you to review this policy periodically."
              ),

              sectionTitle("Contact Us"),
              sectionText("If you have any questions about this Privacy Policy, you can contact us at:"),
              GestureDetector(
                onTap: _launchEmail,
                child: Text(
                  "robertleo.ballasiw@lorma.edu",
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Last Updated: November 2025", // Changed to current year
                style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 6.0),
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
        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.white, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}