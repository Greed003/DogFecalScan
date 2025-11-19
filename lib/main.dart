import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/privacy.dart';
import 'package:flutter_application_1/terms.dart';
import 'package:flutter_application_1/contact.dart';
import 'package:flutter_application_1/history.dart';
import 'package:flutter_application_1/onboarding.dart';

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
  bool _isLoading = false;
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

        await _runModel(imageFile, source: source);
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

  Future<void> _runModel(File file, {required ImageSource source}) async {
    if (_interpreter == null) return;

    setState(() {
      _isLoading = true; 
    });
    await Future.delayed(const Duration(seconds: 3));

    try {
      var inputShape = _interpreter!.getInputTensor(0).shape;
      int inputSize = inputShape[1];

      final Float32List inputBuffer = _preprocessImage(file, inputSize);

      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var outputBuffer = List.generate(1, (_) => List.filled(outputShape[1], 0.0));

      _interpreter!.run(
        inputBuffer.reshape([1, inputSize, inputSize, 3]),
        outputBuffer,
      );

      List<double> probabilities = List<double>.from(outputBuffer[0]);
      int predictedIndex = probabilities.indexOf(
        probabilities.reduce((a, b) => a > b ? a : b),
      );
      double maxValue = probabilities[predictedIndex];

      print("✅ Prediction: ${_labels[predictedIndex]} (${(maxValue * 100).toStringAsFixed(2)}%)");

      setState(() {
        _isLoading = false;
      });

      if (maxValue < 0.69) {
        final retryLabel = source == ImageSource.camera ? "Retake Photo" : "Upload Again";

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Try Again"),
            content: const Text(
              "We couldn't classify this stool image.\n"
              "Please try again with a clearer and closer photo under good lighting.",
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.brown,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(source); 
                },
                child: Text(retryLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
        return;
      }

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
      setState(() {
        _isLoading = false; 
      });
      print("❌ Error running model: $e\n$stack");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                      'images/logo.png',
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
                padding: const EdgeInsets.all(16.0),
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
                          icon:
                              const Icon(Icons.close, color: Color(0xFFCBBD93)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), 
                    _buildMenuItem(Icons.history, "History", () { 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen())); 
                    }), 
                    _buildMenuItem(Icons.medical_services, "Contact Vet", () { 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContactVetScreen())); 
                    }), 
                    _buildMenuItem(Icons.privacy_tip, "Privacy Policy", () { 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyScreen())); 
                    }), 
                    _buildMenuItem(Icons.article, "Terms and Conditions", () { 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TermsAndConditionsScreen())); 
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20),
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
                          icon:
                              const Icon(Icons.upload, color: Colors.black),
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
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.black),
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
        ),

        // 🔥 Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
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
        return "💧 Ensure adequate water intake; add wet food or fiber-rich diet (boiled squash, banana, or plain yogurt).";
      case "Normal":
        return "✅ Maintain a balanced diet; continue regular feeding. Include rice, boiled chicken, and vegetables like carrots or pumpkin.";
      case "Soft":
        return "🥣 Gradually shift to high-quality natural food (boiled egg, pumpkin, or rice). Avoid sudden food changes or excessive treats.";
      case "Loose":
        return "⚠️ Withhold solid food for 12 to 24 hrs; give clean water and homemade electrolyte solution (1 tsp salt + 1 tbsp sugar per liter of water). Feed bland diet afterward (boiled chicken and rice). Consult vet if persists.";
      case "With Parasite":
        return "⚠️ Deworm as prescribed by a vet. Feed easily digestible, natural meals (boiled sweet potato, squash, or egg). Keep the feeding area clean.";
      case "With Blood":
        return "⚠️ Seek immediate vet advice. Temporarily give soft, bland meals (rice, pumpkin, boiled chicken). Avoid fatty or processed foods.";
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