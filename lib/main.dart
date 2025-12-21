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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefsFuture = SharedPreferences.getInstance();
  
  runApp(DogFecalScanApp(prefsFuture: prefsFuture));
}

class DogFecalScanApp extends StatelessWidget {
  final Future<SharedPreferences> prefsFuture;
  
  const DogFecalScanApp({super.key, required this.prefsFuture});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Fecal Scan',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
      ),
      home: FutureBuilder<SharedPreferences>(
        future: prefsFuture,
        builder: (context, snapshot) {
          // Show splash screen immediately
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // If error, default to onboarding
          if (snapshot.hasError) {
            return const OnboardingScreen();
          }
          
          // Check onboarding status
          final prefs = snapshot.data!;
          final seenOnboarding = prefs.getBool("seenOnboarding") ?? false;
          
          return seenOnboarding ? const HomeScreen() : const OnboardingScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD6B588),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.pets,
                size: 50,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Color(0xFFD6B588),
            ),
            const SizedBox(height: 20),
            const Text(
              "DogFecalScan",
              style: TextStyle(
                color: Color(0xFFCBBD93),
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
  final picker = ImagePicker();
  Interpreter? _interpreter;
  Interpreter? _yoloInterpreter;
  final double parasiteThreshold = 0.76;
  Interpreter? _bloodInterpreter;
  final double bloodThreshold = 0.87;
  bool _isLoading = false;
  bool _modelsLoaded = false;
  double _loadingProgress = 0.0;
  String _loadingStage = "Starting...";
  final List<String> _labels = ["Dry", "Watery", "Normal", "Soft"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModel();
    });
  }

  Future<void> _loadModel() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingProgress = 0.0;
        _loadingStage = "Initializing AI models...";
      });

      print("⏳ Loading models...");

      // ---- CLASSIFICATION MODEL ----
      setState(() {
        _loadingProgress = 20.0;
        _loadingStage = "Loading stool type classifier...";
      });
      
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth delay
      
      _interpreter = await Interpreter.fromAsset(
        'model/v2.tflite',
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );

      print("✅ Classification model loaded.");

      // ---- YOLO PARASITE MODEL (YOLOv5) ----
      setState(() {
        _loadingProgress = 50.0;
        _loadingStage = "Loading parasite detector...";
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _yoloInterpreter = await Interpreter.fromAsset(
        'model/parasite-fp16.tflite',
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );

      print("🟢 YOLOv5 parasite model loaded successfully");

      // ---- YOLO BLOOD MODEL (YOLOv5) ----
      setState(() {
        _loadingProgress = 80.0;
        _loadingStage = "Loading blood detector...";
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      _bloodInterpreter = await Interpreter.fromAsset(
        'model/blood-fp16.tflite',
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );

      print("🩸 YOLOv5 blood model loaded successfully");

      // ---- FINAL SETUP ----
      setState(() {
        _loadingProgress = 95.0;
        _loadingStage = "Finalizing setup...";
      });
      
      await Future.delayed(const Duration(milliseconds: 500));

      print("🔥 Models fully initialized.");

      // ✅ Models successfully loaded
      setState(() {
        _loadingProgress = 100.0;
        _loadingStage = "Ready!";
      });

      // Brief delay to show 100% completion
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _modelsLoaded = true;
        _isLoading = false;
      });

    } catch (e, stack) {
      print("❌ Failed to load model: $e\n$stack");
      setState(() {
        _isLoading = false;
        _modelsLoaded = false;
        _loadingStage = "Failed to load models. Please restart the app.";
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4B2E1E),
        title: const Text(
          "Error",
          style: TextStyle(color: Color(0xFFCBBD93)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(color: Color(0xFFD6B588)),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (!_modelsLoaded) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF4B2E1E),
            title: const Text(
              "Models Not Ready",
              style: TextStyle(color: Color(0xFFCBBD93)),
            ),
            content: const Text(
              "Please wait for the AI models to finish loading.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Color(0xFFD6B588)),
                ),
              ),
            ],
          ),
        );
        return;
      }

      final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        // Show processing overlay
        setState(() {
          _isLoading = true;
          _loadingProgress = 0.0;
          _loadingStage = "Processing image...";
        });
        
        // Process the image
        await _runModel(imageFile, source: source);
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Failed to process image. Please try again.");
    }
  }
  Float32List _preprocessImage(File file, int inputSize) {
    final raw = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) throw Exception("Failed to decode image");

    img.Image resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    final Float32List floatList = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        floatList[index++] = pixel.r.toDouble();
        floatList[index++] = pixel.g.toDouble();
        floatList[index++] = pixel.b.toDouble();
      }
    }

    return floatList;
  }
  
   List<double> _yoloPreprocessDouble(File file, int inputSize) {
    final raw = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) throw Exception("YOLO decode error");

    img.Image resized = img.copyResize(decoded, width: inputSize, height: inputSize);
    final List<double> floatList = List.filled(inputSize * inputSize * 3, 0.0);
    int index = 0;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        floatList[index++] = pixel.r / 255.0;
        floatList[index++] = pixel.g / 255.0;
        floatList[index++] = pixel.b / 255.0;
      }
    }

    return floatList;
  }

  Future<Map<String, dynamic>> detectBloodStatus(File file) async {
    if (_bloodInterpreter == null) return {"status": "none", "confidence": 0.0};

    final raw = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) return {"status": "none", "confidence": 0.0};

    var inputShape = _bloodInterpreter!.getInputTensor(0).shape;
    int inputH = inputShape[1];
    int inputW = inputShape[2];

    List<double> input = _yoloPreprocessDouble(file, inputW);

    var outputTensor = _bloodInterpreter!.getOutputTensor(0);
    List outputShape = outputTensor.shape;

    // YOLOv5 typically outputs [1, 25200, 85] or similar
    // Format: [batch, num_detections, 5+num_classes]
    // For blood detection, we typically have 1 class (blood)
    List<List<List<double>>> outputBuffer = [
      List.generate(outputShape[1], (_) => List.filled(outputShape[2], 0.0))
    ];

    _bloodInterpreter!.run(
      input.reshape([1, inputH, inputW, 3]),
      outputBuffer,
    );

    List<double> validScores = [];

    // Parse YOLOv5 output
    for (var det in outputBuffer[0]) {
      // det[4] is the objectness score in YOLOv5
      double confidence = det[4];
      
      // For single-class detection (blood), we use the objectness score
      if (confidence >= bloodThreshold) {
        validScores.add(confidence);
      }
    }

    if (validScores.isNotEmpty) {
      double avgConfidence = validScores.reduce((a, b) => a + b) / validScores.length;
      
      print("🩸 Blood detected! Average confidence: ${avgConfidence.toStringAsFixed(4)}");
      return {"status": "with_blood", "confidence": avgConfidence};
    } else {
      print("🩸 No blood detected");
      return {"status": "none", "confidence": 0.0};
    }
  }

  Future<Map<String, dynamic>> detectParasiteStatus(File file) async {
    if (_yoloInterpreter == null) return {"status": "none", "confidence": 0.0};

    final raw = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(raw);
    if (decoded == null) return {"status": "none", "confidence": 0.0};

    var inputShape = _yoloInterpreter!.getInputTensor(0).shape;
    int inputH = inputShape[1];
    int inputW = inputShape[2];

    List<double> input = _yoloPreprocessDouble(file, inputW);

    var outputTensor = _yoloInterpreter!.getOutputTensor(0);
    List outputShape = outputTensor.shape;

    List<List<List<double>>> outputBuffer = [
      List.generate(outputShape[1], (_) => List.filled(outputShape[2], 0.0))
    ];

    _yoloInterpreter!.run(
      input.reshape([1, inputH, inputW, 3]),
      outputBuffer,
    );

    List<double> validScores = [];

    // Parse YOLOv5 output for parasite detection
    for (var det in outputBuffer[0]) {
      double confidence = det[4]; // objectness score
      
      // For single-class parasite detection
      if (confidence >= parasiteThreshold) {
        validScores.add(confidence);
      }
    }

    if (validScores.isNotEmpty) {
      double avgConfidence = validScores.reduce((a, b) => a + b) / validScores.length;
      print("🐛 Parasite detected! Average confidence: ${avgConfidence.toStringAsFixed(4)}");
      return {"status": "with_parasite", "confidence": avgConfidence};
    } else {
      print("🐛 No parasite detected.");
      return {"status": "none", "confidence": 0.0};
    }
  }

Future<void> _runModel(File file, {required ImageSource source}) async {
  if (_interpreter == null) return;
  
  print("🔄 Starting _runModel - setting isLoading to true");
  setState(() { 
    _isLoading = true;
    _loadingProgress = 0.0;
    _loadingStage = "Initializing...";
  });
  
  try {
    // Add initial delay to ensure loading UI is visible
    
    setState(() {
      _loadingProgress = 10.0;
      _loadingStage = "Processing image...";
    });
    await Future.delayed(const Duration(milliseconds: 250));
    
    print("🔄 Running classification model...");
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

    print("🎯 Prediction: ${_labels[predictedIndex]} ($maxValue)");
    setState(() {
      _loadingProgress = 40.0;
      _loadingStage = "Analyzing stool type...";
    });
    await Future.delayed(const Duration(milliseconds: 250));

    if (maxValue < 0.69) {
      final retryLabel = source == ImageSource.camera ? "Retake Photo" : "Upload Again";

      print("❌ Low confidence - showing retry dialog");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Try Again"),
          content: const Text(
            "We couldn't classify this stool image.\n"
            "Please try again with a clearer and closer photo.",
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.brown,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() { 
                  _isLoading = false; 
                });
                _pickImage(source);
              },
              child: Text(retryLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() { 
                  _isLoading = false; 
                });
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
      return;
    }
    
    setState(() {
      _loadingProgress = 60.0;
      _loadingStage = "Checking for visible parasites...";
    });
     await Future.delayed(const Duration(milliseconds: 250));
    print("🔄 Running parasite detection...");
    final parasiteStatus = await detectParasiteStatus(file);
    
    setState(() {
      _loadingProgress = 80.0;
      _loadingStage = "Checking for visible blood...";
    });
    
    await Future.delayed(const Duration(milliseconds: 250));
    print("🔄 Running blood detection...");
    final bloodStatus = await detectBloodStatus(file);

    setState(() {
      _loadingProgress = 95.0;
      _loadingStage = "Finalizing results...";
    });

    // Add artificial delay to show loading for at least 1.5 seconds total
    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      _loadingProgress = 100.0;
      _loadingStage = "Complete!";
    });

    await Future.delayed(const Duration(milliseconds: 300));

    print("🔄 All models completed - setting isLoading to false");
    setState(() { 
      _isLoading = false; 
    });

    print("🔄 Navigating to results screen");
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageFile: file,
          classification: _labels[predictedIndex],
          confidence: maxValue,
          parasiteDetections: parasiteStatus,
          bloodDetections: bloodStatus,
        ),
      ),
    );

  } catch (e, stack) {
    print("❌ Error in _runModel: $e\n$stack");
    setState(() { 
      _isLoading = false; 
    });
  }
}

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFCBBD93)),
      title: Text(
        title,
        style: const TextStyle(color: Color(0xFFCBBD93)),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
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
                  'images/logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Text(
              'DogFecalScan',
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
                      icon: const Icon(Icons.close, color: Color(0xFFCBBD93)),
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
      body: Stack(
        children: [
          // Main Content
          SafeArea(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _modelsLoaded ? () => _pickImage(ImageSource.gallery) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _modelsLoaded ? const Color(0xFFD6B588) : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: Icon(Icons.upload, color: _modelsLoaded ? Colors.black : Colors.white),
                          label: Text(
                            'Upload',
                            style: TextStyle(color: _modelsLoaded ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _modelsLoaded ? () => _pickImage(ImageSource.camera) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _modelsLoaded ? const Color(0xFFD6B588) : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: Icon(Icons.camera_alt, color: _modelsLoaded ? Colors.black : Colors.white),
                          label: Text(
                            'Take a Photo',
                            style: TextStyle(color: _modelsLoaded ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Change this part in your Stack widget:
          if (_isLoading && !_modelsLoaded)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD6B588)),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        _loadingStage, // CHANGED FROM HARDCODED TEXT
                        style: const TextStyle(
                          color: Color(0xFFCBBD93),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ADD THIS - Progress percentage
                    Text(
                      "${_loadingProgress.toInt()}%",
                      style: const TextStyle(
                        color: Color(0xFFCBBD93),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Image Processing Overlay - Simple Design
          if (_isLoading && _modelsLoaded)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Text
                    Text(
                      _loadingStage,
                      style: const TextStyle(
                        color: Color(0xFFCBBD93),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Progress Bar Container
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          // Progress Fill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            width: (MediaQuery.of(context).size.width * 0.7) * (_loadingProgress / 100),
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6B588),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Percentage
                    Text(
                      "${_loadingProgress.toInt()}%",
                      style: const TextStyle(
                        color: Color(0xFFCBBD93),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }     
}

/// RESULT SCREEN
class ResultScreen extends StatefulWidget {
  final File imageFile;
  final String classification;
  final double confidence;
  final Map<String, dynamic> parasiteDetections;
  final Map<String, dynamic> bloodDetections;
  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.classification,
    required this.confidence,
    required this.parasiteDetections,
    required this.bloodDetections,
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

    // Get the combined recommendations
    final recommendations = getCombinedRecommendations();

    final result = {
      "date": DateTime.now().toIso8601String().split("T")[0],
      "status": widget.classification,
      "confidence": double.parse((widget.confidence * 100).toStringAsFixed(2)),
      "imagePath": widget.imageFile.path,
      "parasite": widget.parasiteDetections['status'],
      "parasiteConfidence": double.parse((widget.parasiteDetections['confidence'] * 100).toStringAsFixed(2)),
      "blood": widget.bloodDetections['status'],
      "bloodConfidence": double.parse((widget.bloodDetections['confidence'] * 100).toStringAsFixed(2)),
      "recommendations": jsonEncode(recommendations), // Save recommendations as JSON string
    };

    history.add(jsonEncode(result));
    await prefs.setStringList("history", history);
  }

  List<String> getAbnormalityList() {
    List<String> abnormalities = [];

    // Check parasite detection
    if (widget.parasiteDetections['status'] != null &&
        widget.parasiteDetections['status'] != "none") {
      abnormalities.add("With Parasite");
    }

    // Check blood detection
    if (widget.bloodDetections['status'] != null &&
        widget.bloodDetections['status'] != "none") {
      abnormalities.add("With Blood");
    }

    return abnormalities;
  }

  // SIMPLIFIED: Only combine when needed, otherwise return original
  List<String> getCombinedRecommendations() {
    final hasBlood = widget.bloodDetections['status'] != null &&
                    widget.bloodDetections['status'] != "none";
    final hasParasite = widget.parasiteDetections['status'] != null &&
                      widget.parasiteDetections['status'] != "none";
    
    // Special case: Blood detection is always high priority
    if (hasBlood) {
      return _getBloodEmergencyRecommendations();
    }
    
    // Special case: Parasite detection - combine and remove duplicates
    if (hasParasite) {
      return _getParasiteCombinedRecommendations();
    }
    
    // If no additional findings, just return the primary classification recommendations
    return getRecommendationList(widget.classification);
  }

  // SIMPLEST: Manual combination for parasite cases
  List<String> _getParasiteCombinedRecommendations() {
    final recommendations = <String>[];
    
    // Always start with deworming
    recommendations.add("⚠️ Regular deworming required");
    
    // Add primary classification recommendations (filter out individual food instructions)
    final primaryRecs = getRecommendationList(widget.classification);
    for (final rec in primaryRecs) {
      if (!rec.toLowerCase().contains('include') && 
          !rec.toLowerCase().contains('add') && 
          !rec.toLowerCase().contains('feed') && 
          !rec.toLowerCase().contains('give')) {
        recommendations.add(rec);
      }
    }
    
    // Always add hygiene
    recommendations.add("Keep the feeding area clean");
    
    // Add combined foods from both primary and parasite recommendations
    final allFoods = _extractAllFoods([
      ...getRecommendationList(widget.classification),
      ...getRecommendationList("With Parasite")
    ]);
    
    if (allFoods.isNotEmpty) {
      recommendations.add("Feed easily digestible meals (${allFoods.join(', ')})");
    }
    
    return recommendations;
  }

  // SIMPLE & RELIABLE: Manual ordering for blood cases
  List<String> _getBloodEmergencyRecommendations() {
    final recommendations = <String>[];
    
    // Get all recommendations first
    final allRecs = <String>[];
    allRecs.addAll(getRecommendationList(widget.classification));
    allRecs.addAll(getRecommendationList("With Blood"));
    
    // Manual ordering - guaranteed correct sequence
    recommendations.add("🚨 SEEK IMMEDIATE VETERINARY CARE");
    
    // Find and add "Withhold solid food"
    final withholdFood = allRecs.firstWhere(
      (rec) => rec.toLowerCase().contains('withhold solid food'),
      orElse: () => "⚠️ Withhold solid food for 12 to 24 hrs"
    );
    recommendations.add(withholdFood);
    
    // Find and add "Give clean water"
    final cleanWater = allRecs.firstWhere(
      (rec) => rec.toLowerCase().contains('clean water') || rec.toLowerCase().contains('electrolyte'),
      orElse: () => "Give clean water and homemade electrolyte solution (1 tsp salt + 1 tbsp sugar per liter of water)"
    );
    recommendations.add(cleanWater);
    
    // Extract all foods and create combined feeding instruction
    final allFoods = _extractAllFoods(allRecs);
    if (allFoods.isNotEmpty) {
      final feedingInstruction = _createBloodFeedingInstruction(allFoods);
      recommendations.add(feedingInstruction);
    }
    
    // Find and add "Avoid fatty foods"
    final avoidFoods = allRecs.firstWhere(
      (rec) => rec.toLowerCase().contains('avoid fatty') || rec.toLowerCase().contains('avoid processed'),
      orElse: () => "Avoid fatty or processed foods"
    );
    recommendations.add(avoidFoods);
    
    return recommendations;
  }

  // Helper: Extract all food items from recommendations
  List<String> _extractAllFoods(List<String> recommendations) {
    final foods = <String>[];
    final foodItems = ['rice', 'boiled chicken', 'pumpkin', 'carrots', 'squash', 
                      'banana', 'plain yogurt', 'boiled egg', 'sweet potato'];
    
    for (final rec in recommendations) {
      for (final food in foodItems) {
        if (rec.toLowerCase().contains(food.toLowerCase())) {
          foods.add(food);
        }
      }
    }
    
    return foods.toSet().toList(); // Return unique foods
  }

  // Helper: Create combined feeding instruction for blood cases
  String _createBloodFeedingInstruction(List<String> foods) {
    // Group foods by category for better organization
    final proteins = foods.where((food) => food.contains('chicken') || food.contains('egg')).toList();
    final carbs = foods.where((food) => food.contains('rice') || food.contains('sweet potato')).toList();
    final vegetables = foods.where((food) => food.contains('pumpkin') || food.contains('carrots') || food.contains('squash')).toList();
    final others = foods.where((food) => food.contains('banana') || food.contains('yogurt')).toList();
    
    final List<String> organizedFoods = [];
    if (carbs.isNotEmpty) organizedFoods.addAll(carbs);
    if (proteins.isNotEmpty) organizedFoods.addAll(proteins);
    if (vegetables.isNotEmpty) organizedFoods.addAll(vegetables);
    if (others.isNotEmpty) organizedFoods.addAll(others);
    
    return "Temporarily feed bland meals (${organizedFoods.join(', ')})";
  }

  // Your original recommendation lists (WITH EMOJIS)
  List<String> getRecommendationList(String type) {
    switch (type) {
      case "Dry":
        return [
          "💧 Ensure adequate water intake",
          "Add wet food or fiber-rich diet (boiled squash, banana, or plain yogurt)"
        ];
      case "Normal":
        return [
          "✅ Maintain a balanced diet",
          "Continue regular feeding",
          "Include rice, boiled chicken, and vegetables like carrots or pumpkin"
        ];
      case "Soft":
        return [
          "🥣 Gradually shift to high-quality natural food (boiled egg, pumpkin, or rice)",
          "Avoid sudden food changes or excessive treats"
        ];
      case "Watery":
        return [
          "⚠️ Consult a veterinarian immediately if persists",
          "Withhold solid food for 12 to 24 hrs",
          "Provide clean water and a vet-approved electrolyte solution",
          "Feed bland diet afterward (boiled chicken and rice)"
        ];
      case "With Parasite":
        return [
          "⚠️ Regular deworming required",
          "Feed easily digestible, natural meals (boiled sweet potato, squash, or egg)",
          "Keep the feeding area clean"
        ];
      case "With Blood":
        return [
          "⚠️ Seek immediate vet advice",
          "Temporarily give soft, bland meals (rice, pumpkin, boiled chicken)",
          "Avoid fatty or processed foods"
        ];
      default:
        return ["ℹ️ No specific recommendation available"];
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
      case "Watery":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (widget.confidence * 100).toStringAsFixed(2);
    final pconfidencePercent = (widget.parasiteDetections['confidence'] * 100).toStringAsFixed(2);
    final bconfidencePercent = (widget.bloodDetections['confidence'] * 100).toStringAsFixed(2);
    final abnormalityList = getAbnormalityList();
    final combinedRecommendations = getCombinedRecommendations(); // NEW
    
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

            /// 🩺 Additional Findings Display (Simpler Version)
            if (abnormalityList.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Additional Findings",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Parasite finding
                            if (widget.parasiteDetections['status'] != null &&
                                widget.parasiteDetections['status'] != "none")
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  "• Visible Parasite (${pconfidencePercent}% confidence)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            // Blood finding
                            if (widget.bloodDetections['status'] != null &&
                                widget.bloodDetections['status'] != "none")
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  "• Visible Blood (${bconfidencePercent}% confidence)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            /// 📝 Combined Recommendation Card (UPDATED)
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.pets, color: Colors.brown, size: 30),
                        const SizedBox(width: 12),
                        const Text(
                          "Dietary Recommendations",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Recommendations list - full width, no icon influence
                    ...combinedRecommendations.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bullet point
                            Text(
                              "• ",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.brown,
                                height: 1.4,
                              ),
                            ),
                            // Recommendation text
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.brown,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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