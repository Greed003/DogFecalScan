import 'dart:ffi';
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
import 'dart:ui';

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

  // ✅ Match Python class_names order
  final List<String> _labels = ["Dry", "Loose", "Normal", "Soft"];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model/v2.tflite');
      print("✅ Model loaded successfully");

      // 🔍 Log input details
      var input = _interpreter!.getInputTensor(0);
      print("📏 Input tensor: shape=${input.shape}, type=${input.type}");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        setState(() {
          _image = imageFile;
        });

        await _runModel(imageFile);
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  Float32List _preprocessImage(File file, int inputSize) {
    final raw = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) throw Exception("Failed to decode image");

    img.Image resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    final Float32List floatList = Float32List(inputSize * inputSize * 3);
    int index = 0;

    final List<double> sample = [];

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);

        // ✅ No normalization, just raw values like Python
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        floatList[index++] = r;
        floatList[index++] = g;
        floatList[index++] = b;

        if (sample.length < 9) {
          sample.addAll([r, g, b]);
        }
      }
    }

    print("First pixel values (raw): $sample");

    return floatList;
  }

  Future<void> _runModel(File file) async {
    if (_interpreter == null) return;

    try {
      var inputShape = _interpreter!.getInputTensor(0).shape;
      int inputSize = inputShape[1];

      final Float32List inputBuffer = _preprocessImage(file, inputSize);

      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var outputBuffer = List.generate(1, (_) => List.filled(outputShape[1], 0.0));

      // ✅ Pass Float32List directly (no buffer.asFloat32List)
      _interpreter!.run(
        inputBuffer.reshape([1, inputSize, inputSize, 3]),
        outputBuffer,
      );

      List<double> probabilities = List<double>.from(outputBuffer[0]);
      print("📊 Raw output probabilities: $probabilities");

      int predictedIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      double maxValue = probabilities[predictedIndex];

      print("✅ Prediction: ${_labels[predictedIndex]} (${(maxValue * 100).toStringAsFixed(2)}%)");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: file,
            classification: _labels[predictedIndex],
            confidence: maxValue,
          ),
        ),
      );
    } catch (e, stack) {
      print("❌ Error running model: $e\n$stack");
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
            padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, top: 3, right: 16.0),
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
                const SizedBox(height: 8),
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
                _buildMenuItem(Icons.article, "Terms and Conditions", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TermsAndConditionsScreen()));
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
  final double confidence;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.classification,
    required this.confidence,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    saveResult();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.confidence).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList("history") ?? [];

    final result = {
      "date": DateTime.now().toString().split(" ")[0],
      "status": widget.classification,
      "confidence": double.parse((widget.confidence * 100).toStringAsFixed(2)),
      "imagePath": widget.imageFile.path,
    };

    history.add(jsonEncode(result));
    await prefs.setStringList("history", history);
  }

  String getRecommendation() {
    switch (widget.classification) {
      case "Dry":
        return "💧 Your dog may be dehydrated. Provide water and add fiber to meals.";
      case "Normal":
        return "✅ Healthy stool. Maintain current diet and exercise routine.";
      case "Soft":
        return "🥣 Soft stool could mean stress or mild upset. Offer bland food like chicken and rice.";
      case "Loose":
        return "⚠️ Possible diarrhea. Monitor hydration and visit a vet if it continues.";
      default:
        return "ℹ️ No specific recommendation available.";
    }
  }

  Color getClassificationColor() {
    switch (widget.classification) {
      case "Dry":
        return Colors.orange.shade700;
      case "Normal":
        return Colors.green.shade700;
      case "Soft":
        return Colors.amber.shade800;
      case "Loose":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (widget.confidence * 100).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B2A20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
        title: const Text(
          "Scan Result",
          style: TextStyle(color: Color(0xFFD7C49E), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// 🖼️ Image with Blur
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Image.file(
                      widget.imageFile,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.4),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.imageFile,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// 🏷 Classification Label
            Text(
              widget.classification,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: getClassificationColor(),
              ),
            ),
            const SizedBox(height: 8),

            /// 📊 Confidence Score + Progress Bar
            Column(
              children: [
                Text(
                  "Confidence: $confidencePercent%",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _animation.value,
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          getClassificationColor(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// 📝 Recommendation Card
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pets, color: Colors.brown, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getRecommendation(),
                        style: const TextStyle(fontSize: 16,color: Colors.brown, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// 🔁 Scan Again Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Scan Another",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              onPressed: () => Navigator.pop(context),
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
      historyData = history
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList(); // ✅ Newest-first ordering
    });
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("history");
    setState(() {
      historyData.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Dry":
        return Colors.orange.shade700;
      case "Normal":
        return Colors.green.shade700;
      case "Soft":
        return Colors.amber.shade800;
      case "Loose":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade400;
    }
  }

  void _showFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: Image.file(File(imagePath))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A20),
      appBar: AppBar(
        title: const Text("History", style: TextStyle(color: Color(0xFFD7C49E))),
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
                    content: const Text(
                      "Are you sure you want to clear all history?",
                      style: TextStyle(color: Colors.white70),
                    ),
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
                if (confirm == true) clearHistory();
              },
            ),
        ],
      ),
      body: historyData.isEmpty
          ? const Center(
              child: Text("No history yet", style: TextStyle(color: Colors.white)),
            )
          : ListView.separated(
              itemCount: historyData.length,
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = historyData[index];
                final String status = item["status"];
                final String? imagePath = item["imagePath"];
                final String confidence = item["confidence"] != null
                  ? "${(double.tryParse(item["confidence"].toString()) ?? 0 * 100).toStringAsFixed(2)}%"
                  : "N/A";

                return GestureDetector(
                  onTap: () {
                    if (imagePath != null && File(imagePath).existsSync()) {
                      _showFullImage(imagePath);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF4B3B2D),
                    ),
                    child: Row(
                      children: [
                        /// 🖼️ Thumbnail (blurred)
                        if (imagePath != null && File(imagePath).existsSync())
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Image.file(
                                File(imagePath),
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.image_not_supported, color: Colors.white54, size: 50),

                        const SizedBox(width: 14),

                        /// Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["date"], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "Confidence: $confidence",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    }
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📋 Phone number $phone copied"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];
          final cityVets = vets.where((v) => v["city"] == city).toList();

          return Card(
            color: Colors.brown[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ExpansionTile(
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              title: Text(
                city!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              children: cityVets.map((vet) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    onTap: () => _callVet(vet["phone"]!), // tap to call
                    onLongPress: () => _copyPhone(context, vet["phone"]!),
                    title: Text(
                      vet["clinic"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${vet["address"]}\n${vet["phone"]}",
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.call, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// Privacy Policy Screen
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

/// Terms and Conditions Screen
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
