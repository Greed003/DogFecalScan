import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const DogFecalScanApp());
}

class DogFecalScanApp extends StatelessWidget {
  const DogFecalScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Fecal Scan',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
      ),
      home: const EntryPoint(),
    );
  }
}

/// ENTRY POINT: Decides whether to show onboarding or home
class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  bool _isLoading = true;
  bool _seenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool("seenOnboarding") ?? false;
    setState(() {
      _seenOnboarding = seen;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _seenOnboarding ? const HomeScreen() : const OnboardingScreen();
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
      "subtitle":
          "A mobile app that helps check your dog's digestive health through stool analysis.",
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

  void _nextPage(int index) async {
    if (index == onboardingData.length - 1) {
      // Save onboarding as seen
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
  Interpreter? _interpreter;
  String _result = "No result";

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model/model.tflite');
      print("✅ Model loaded successfully");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85, // reduce size if needed
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        setState(() {
          _image = imageFile;
        });

        // Directly run model using the File object
        _runModel(imageFile);
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  Uint8List _preprocessImage(File file, int inputSize) {
    final raw = file.readAsBytesSync();
    img.Image? image = img.decodeImage(raw);

    if (image == null) {
      throw Exception("Failed to decode image");
    }

    // Resize to input size
    img.Image resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Convert to Float32 for TensorFlow Lite
    var floatList = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y); // <-- Pixel object

        floatList[index++] = pixel.r / 255.0; // red
        floatList[index++] = pixel.g / 255.0; // green
        floatList[index++] = pixel.b / 255.0; // blue
      }
    }

    return floatList.buffer.asUint8List();
  }


  Future<void> _runModel(File file) async {
    if (_interpreter == null) {
      print("Interpreter is null!");
      return;
    }

    try {
      // Get input tensor shape
      var inputShape = _interpreter!.getInputTensor(0).shape;
      print("Input shape: $inputShape");

      int inputSize = inputShape[1];

      // Preprocess the image
      var input = _preprocessImage(file, inputSize);
      print("Input preprocessed: ${input.length}");

      // Get output tensor shape
      var outputShape = _interpreter!.getOutputTensor(0).shape.cast<int>();
      print("Output shape: $outputShape");

      // Create output buffer with correct type
      int outputSize = outputShape.reduce((a, b) => a * b);
      var output = List.generate(outputSize, (_) => 0.0).reshape([1, outputShape[1]]);

      // Run inference
      _interpreter!.run(
        input.buffer.asFloat32List().reshape([1, inputSize, inputSize, 3]),
        output,
      );

      // Safely convert to List<double>
      List<double> probabilities = List<double>.from(output[0]);

      // Find predicted index
      double maxValue = probabilities.reduce((a, b) => a > b ? a : b);
      int predictedIndex = probabilities.indexOf(maxValue);

      // Labels
      List<String> labels = ["Dry", "Watery", "Normal", "Soft"];
      String classification = labels[predictedIndex];
      print("Predicted: $classification");

      // Navigate to result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: file,
            classification: classification,
          ),
        ),
      );
    } catch (e, stack) {
      print("Error running model: $e\n$stack");
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
                      icon: const Icon(Icons.camera_alt, color: Colors.black),
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

/// RESULT SCREEN
class ResultScreen extends StatefulWidget {
  final File imageFile;
  final String classification;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.classification,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    saveResult();
  }

  Future<void> saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList("history") ?? [];

    final result = {
      "date": DateTime.now().toString().split(" ")[0], // YYYY-MM-DD
      "status": widget.classification,
      "imagePath": widget.imageFile.path,
    };

    history.add(jsonEncode(result));
    await prefs.setStringList("history", history);
  }

  // ✅ Recommendations
  String getRecommendation() {
    switch (widget.classification) {
      case "Dry":
        return "💧 Add moisture & fiber.\n- Pumpkin, broth, wet food\n🐶 Tip: Ensure constant water access.";
      case "Normal":
        return "✅ Balanced stool.\n- Keep current diet of quality kibble, meat, veggies\n🐶 Tip: Avoid sudden food changes.";
      case "Soft":
        return "🍚 Gentle diet:\n- Rice, chicken, pumpkin\n🐶 Tip: Limit fatty treats.";
      case "Watery":
        return "⚠️ Vet visit if >24hrs.\n- Feed chicken & rice\n🐶 Tip: Monitor hydration closely.";
      default:
        return "❓ No recommendation available.";
    }
  }

  // 🎨 Colors
  Color getClassificationColor() {
    switch (widget.classification) {
      case "Dry":
        return Colors.brown;
      case "Normal":
        return Colors.green;
      case "Soft":
        return Colors.orange;
      case "Watery":
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Result",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // 🟢 Classification
            RichText(
              text: TextSpan(
                text: "Classification: ",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: widget.classification,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getClassificationColor(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 📝 Recommendation
            Text(
              getRecommendation(),
              style: const TextStyle(
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
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> historyData = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList("history") ?? [];

    setState(() {
      historyData = history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("history"); // Clear from storage
    setState(() {
      historyData.clear(); // Clear UI list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(color: Color(0xFFD7C49E)),
        ),
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        actions: [
          if (historyData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFD7C49E)),
              tooltip: "Clear History",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF3B2A20),
                    title: const Text("Clear History", style: TextStyle(color: Colors.white)),
                    content: const Text("Are you sure you want to clear all history?",
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  clearHistory();
                }
              },
            ),
        ],
      ),
      body: historyData.isEmpty
          ? const Center(
              child: Text(
                "No history yet",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: historyData.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = historyData[index];

                Color statusColor;
                switch (item["status"]) {
                  case "Normal":
                    statusColor = Colors.green;
                    break;
                  case "Dry":
                    statusColor = Colors.brown;
                    break;
                  case "Soft":
                    statusColor = Colors.orange;
                    break;
                  case "Watery":
                    statusColor = Colors.blue;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF3B2A20),
                  ),
                  child: Row(
                    children: [
                      /// Image thumbnail
                      if (item["imagePath"] != null && File(item["imagePath"]).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(item["imagePath"]),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.image_not_supported, color: Colors.white54),

                      const SizedBox(width: 12),

                      /// Details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["date"],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            item["status"],
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
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

  void _callVet(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint("Could not launch $phone");
    }
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Phone number $phone copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = vets.map((v) => v["city"]).toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
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
                    onTap: () => _callVet(vet["phone"]!), // tap to call
                    onLongPress: () =>
                        _copyPhone(context, vet["phone"]!), // long press to copy
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
                    trailing: const Icon(Icons.phone, color: Colors.white),
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