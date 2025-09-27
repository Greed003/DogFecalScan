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
                  "This Privacy Policy explains how we handle information, both online and offline, "
                  "and how we protect your privacy while you use the app."),

              sectionTitle("Consent"),
              sectionText(
                  "By using DogFecalScan, you hereby consent to this Privacy Policy and agree to its terms."),

              sectionTitle("Information We Collect"),
              sectionText(
                  "DogFecalScan does not require you to create an account or provide personal data. "
                  "The only data we process are the images you capture or upload for classification, "
                  "and these remain on your device."),
              bullet("Captured or uploaded stool images – processed locally on your device."),
              bullet("Timestamps – saved locally if you choose to view your history."),
              bullet("Contact info – only used if you tap 'Contact Vet' or 'Send Feedback'."),

              sectionTitle("How We Use Your Information"),
              bullet("Analyze dog stool images locally using AI to classify health conditions."),
              bullet("Save your scan history on your device (optional)."),
              bullet("Improve app functionality through feedback."),

              sectionTitle("Offline Use"),
              sectionText(
                  "DogFecalScan works completely offline. All image processing happens locally. "
                  "No data is sent to external servers, and we do not track or monitor user activity."),

              sectionTitle("Log Files & Analytics"),
              sectionText(
                  "Unlike websites, this app does not use cookies or online tracking. "
                  "We do not collect IP addresses, device identifiers, or analytics data."),

              sectionTitle("Third-Party Privacy"),
              sectionText(
                  "This app does not share your data with third-party advertisers or services. "
                  "Links to external resources (like a vet clinic's phone number or location) "
                  "will open outside the app and are subject to their own privacy policies."),

              sectionTitle("Your Rights"),
              bullet("Right to Access – You can view all your stored history from the History screen."),
              bullet("Right to Erasure – You can clear all stored data by using 'Clear History' in the app."),
              bullet("Right to Withdraw Consent – You can uninstall the app anytime."),

              sectionTitle("Children’s Privacy"),
              sectionText(
                  "DogFecalScan does not knowingly collect any personal information from children under 13. "
                  "Parents and guardians are encouraged to monitor their children's use of the app."),

              sectionTitle("Updates to This Policy"),
              sectionText(
                  "We may update this Privacy Policy from time to time. Any changes will be reflected here, "
                  "and the 'Last Updated' date will be adjusted accordingly."),

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
                "Last Updated: September 2025",
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