import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  final List<Map<String, String>> onboardingData = [
    {
      "image": "images/logo.png",
      "title": "DogFecalScan",
      "subtitle":
          "An offline mobile application for canine fecal classification and dietary recommendations.",
      "button": "Get Started"
    },
    {
      "image": "images/camera.png",
      "title": "Capture Your Dog's Feces",
      "subtitle": "",
      "button": "Next"
    },
    {
      "image": "images/poo.png",
      "title": "Automatic Classification",
      "subtitle": "",
      "button": "Next"
    },
    {
      "image": "images/bowl.png",
      "title": "Dietary Recommendations",
      "subtitle": "",
      "button": "Finish"
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkDisclaimer();
  }

  Future<void> _checkDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('acceptedDisclaimer') ?? false;

    if (!accepted) {
      Future.delayed(Duration.zero, () => _showDisclaimerDialog());
    }
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Disclaimer"),
        content: const Text(
          "DogFecalScan is intended FOR DOGS ONLY.\n\n"
          "Results and dietary recommendations are for "
          "informational purposes and do not replace "
          "professional veterinary advice.\n\n"
          "Consult a licensed veterinarian for serious or "
          "persistent health concerns.",
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade400,
            ),
            child: const Text("Exit"),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8D6E63), 
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('acceptedDisclaimer', true);
              Navigator.pop(context);
            },
            child: const Text(
              "I Understand",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage(int index) async {
    if (index == onboardingData.length - 1) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("seenOnboarding", true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: onboardingData.length,
        itemBuilder: (context, index) => OnboardingPage(
          image: onboardingData[index]["image"]!,
          title: onboardingData[index]["title"]!,
          subtitle: onboardingData[index]["subtitle"]!,
          buttonText: onboardingData[index]["button"]!,
          onPressed: () => _nextPage(index),
        ),
      ),
    );
  }
}

/// ✅ ONBOARDING PAGE WIDGET (THIS FIXES YOUR ERROR)
class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(image, height: 150),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCBBD93),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6B588),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
