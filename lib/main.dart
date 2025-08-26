import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(DogFecalScanApp());
}

class DogFecalScanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Fecal Scan',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
      ),
      home: SplashScreen(),
    );
  }
}

/// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage("images/logo.png"),
          height: 150,
        ),
      ),
    );
  }
}

/// ONBOARDING SCREEN
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
      "title": "Dog Fecal Scan",
      "subtitle": "A mobile app that helps check your dog's digestive health through stool analysis.",
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
      "title": "Classify Feces Automatically",
      "subtitle": "",
      "button": "Next"
    },
    {
      "image": "images/bowl.png",
      "title": "Receive Dietary Recommendations",
      "subtitle": "",
      "button": "Finish"
    },
  ];

  void _nextPage(int index) {
    if (index == onboardingData.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
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

/// ONBOARDING PAGE WIDGET
class OnboardingPage extends StatelessWidget {
  final String image, title, subtitle, buttonText;
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
            if (title.isNotEmpty)
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
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

/// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageFile: _image!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipOval(
                child: Image.asset(
                  'images/logo.png', // your logo
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Text(
              'Dog Fecal Scan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFCBBD93),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFCBBD93)),
              iconSize: 28,
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF4B2E1E),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Menu",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCBBD93),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFCBBD93)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.history, "History", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => HistoryScreen()));
                }),
                _buildMenuItem(Icons.medical_services, "Contact Vet", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ContactVetScreen()));
                }),
                _buildMenuItem(Icons.privacy_tip, "Privacy Policy", () {
                   Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()));
                }),
                _buildMenuItem(Icons.article, "Service Agreement", () {
                   Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ServiceAgreementScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              'images/face.png',
              height: 180,
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Upload or capture your dog feces to provide you a dietary recommendations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6B588),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.upload, color: Colors.black),
                      label: const Text(
                        'Upload',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6B588),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon:
                          const Icon(Icons.camera_alt, color: Colors.black),
                      label: const Text(
                        'Take a Photo',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFCBBD93)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFCBBD93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result Screen
class ResultScreen extends StatelessWidget {
  final File imageFile;
  const ResultScreen({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // brown background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Result",
          style: TextStyle(color: Color(0xFFD7C49E), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uploaded Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Classification
            RichText(
              text: const TextSpan(
                text: "Classification: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: "Normal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recommendation
            const Text(
              "✅ Balanced stool.\n"
              "- Keep current diet of quality kibble, meat, veggies\n"
              "🐶 Tip: Avoid sudden food changes",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// History Screen
class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> historyData = [
    {
      "date": "01/05/2025",
      "status": "Normal",
      "color": Colors.green,
      "icon": Icons.check_circle,
    },
    {
      "date": "28/04/2025",
      "status": "Dry",
      "color": Colors.orange,
      "icon": Icons.wb_sunny,
    },
    {
      "date": "20/04/2025",
      "status": "Soft",
      "color": Colors.yellow,
      "icon": Icons.water_drop,
    },
    {
      "date": "15/04/2025",
      "status": "Watery",
      "color": Colors.red,
      "icon": Icons.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // Dark brown background
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
      ),
      body: ListView.builder(
        itemCount: historyData.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = historyData[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(30),
              color: const Color(0xFF3B2A20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Date
                Text(
                  item["date"],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),

                /// Status
                Text(
                  item["status"],
                  style: TextStyle(
                    color: item["color"],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                /// Icon instead of image
                Icon(
                  item["icon"],
                  color: item["color"],
                  size: 28,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Contact Vet Screen
class ContactVetScreen extends StatelessWidget {
  final List<Map<String, String>> vets = [
    {
      "city": "San Juan",
      "clinic": "Skyu Veterinary Clinic",
      "address": "Aragorn Bldg., Brgy Ilocanos Sur, San Juan, La Union",
      "phone": "09123454567"
    },
    {
      "city": "Bauang",
      "clinic": "Bauang Veterinary Care Clinic",
      "address": "Bauang, 2501 La Union",
      "phone": "09357898802"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Group vets by city
    final cities = vets.map((v) => v["city"]).toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // brown background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Contact Vet",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
      ),
      body: ListView(
        children: cities.map((city) {
          // Get vets for this city
          final cityVets = vets.where((v) => v["city"] == city).toList();

          return Card(
            color: Colors.brown[800],
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ExpansionTile(
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              title: Text(
                city!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: cityVets.map((vet) {
                return Card(
                  color: Colors.brown[700],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    title: Text(
                      vet["clinic"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${vet["address"]}\n${vet["phone"]}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // brown background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0.0, bottom: 16.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            sectionTitle("📌 DogFecalScan cares about your privacy."),
            sectionText("This policy explains, in simple terms, how the app works and what it uses."),

            sectionTitle("🔹 1. What We Use"),
            bullet("Camera & Gallery → Only for taking or uploading dog stool images."),
            bullet("Storage → To save or access images on your phone."),
            bullet("Phone & Maps → Only if you tap Contact Vet (opens dialer or Google Maps)."),
            sectionText("👉 We never collect or store your personal data."),

            sectionTitle("🔹 2. Offline Use"),
            bullet("The app works completely offline."),
            bullet("All analysis happens on your device only."),
            bullet("Nothing is sent to servers."),

            sectionTitle("🔹 3. Data Sharing"),
            bullet("We do not sell or share your data."),
            bullet("Everything stays on your phone unless you decide to share it."),

            sectionTitle("🔹 4. Permissions"),
            bullet("📷 Camera → Take photos"),
            bullet("🖼 Storage → Choose from gallery"),
            bullet("📞 Phone → Call a vet (optional)"),

            sectionTitle("🔹 5. Your Control"),
            bullet("You can remove permissions anytime in your phone settings."),
            bullet("You can uninstall the app whenever you like."),

            sectionTitle("🔹 6. Contact Us"),
            sectionText("Questions? Email us at: robertleo.ballasiw@lorma.edu"),
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

///Service Agreement Screen
class ServiceAgreementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20), // brown background
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Service Agreement",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0.0, bottom: 16.0, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            sectionTitle("📌 Agreement Overview"),
            sectionText("By using DogFecalScan, you agree to these terms. This app is designed only as a pet health aid, not as a substitute for a veterinarian."),

            sectionTitle("🔹 1. App Usage"),
            bullet("The app analyzes dog stool images using AI for educational purposes."),
            bullet("It does not provide official medical or veterinary diagnosis."),
            bullet("Always consult a licensed veterinarian for serious concerns."),

            sectionTitle("🔹 2. User Responsibilities"),
            bullet("Use the app responsibly and only for personal/non-commercial purposes."),
            bullet("You are responsible for how you use and interpret the results."),
            bullet("The app should not replace professional veterinary advice."),

            sectionTitle("🔹 3. Limitations"),
            bullet("Results may not always be 100% accurate."),
            bullet("The developers are not liable for decisions made based on the app."),
            bullet("The app requires device permissions (camera, storage, phone) to function properly."),

            sectionTitle("🔹 4. Data & Privacy"),
            bullet("The app works fully offline."),
            bullet("No personal or pet data is collected or shared."),
            bullet("Any images remain on your device unless you share them."),

            sectionTitle("🔹 5. Updates & Changes"),
            bullet("We may update this agreement in future app versions."),
            bullet("Continued use means you accept the latest terms."),

            sectionTitle("🔹 6. Contact Us"),
            sectionText("For questions, contact us at: alexander.celestino@lorma.edu"),
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