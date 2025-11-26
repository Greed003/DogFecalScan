import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';

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
      case "Watery":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade400;
    }
  }

  void _showHistoryDetails(Map<String, dynamic> item) {
    final String status = item["status"];
    final String? imagePath = item["imagePath"];
    final double confidence = double.tryParse(item["confidence"].toString()) ?? 0;
    final String confidencePercent = confidence.toStringAsFixed(2);
    
    // Additional findings
    final parasiteStatus = item["parasite"];
    final parasiteConfidence = double.tryParse(item["parasiteConfidence"].toString()) ?? 0;
    final bloodStatus = item["blood"];
    final bloodConfidence = double.tryParse(item["bloodConfidence"].toString()) ?? 0;
    
    // Check if there are any additional findings
    final hasAdditionalFindings = (parasiteStatus != null && parasiteStatus != "none") || 
                                 (bloodStatus != null && bloodStatus != "none");
    
    // Recommendations
    List<String> recommendations = [];
    if (item["recommendations"] != null) {
      try {
        if (item["recommendations"] is String) {
          // Try to decode as JSON first
          final decoded = jsonDecode(item["recommendations"]);
          if (decoded is List) {
            recommendations = List<String>.from(decoded);
          } else if (item["recommendations"].contains('||')) {
            // Fallback to string split method
            recommendations = (item["recommendations"] as String).split('||');
          } else {
            // Single recommendation
            recommendations = [item["recommendations"] as String];
          }
        } else if (item["recommendations"] is List) {
          // Handle list format directly
          recommendations = List<String>.from(item["recommendations"]);
        }
      } catch (e) {
        // If all else fails, try string split
        if (item["recommendations"] is String) {
          recommendations = (item["recommendations"] as String).split('||');
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF3B2A20),
          appBar: AppBar(
            title: const Text("Saved Result", style: TextStyle(color: Color(0xFFD7C49E))),
            backgroundColor: const Color(0xFF3B2A20),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 🖼️ Image with Blur (like result screen)
                if (imagePath != null && File(imagePath).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Image.file(
                            File(imagePath),
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
                            File(imagePath),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (imagePath != null && File(imagePath).existsSync()) 
                  const SizedBox(height: 24),

                /// 🏷 Classification Label
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
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
                      child: LinearProgressIndicator(
                        value: confidence / 100,
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// 🩺 Additional Findings Display (like result screen)
                if (hasAdditionalFindings) ...[
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
                                if (parasiteStatus != null && parasiteStatus != "none")
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• ",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.orange.shade700,
                                                height: 1.4,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: "Parasite",
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text: " (${parasiteConfidence.toStringAsFixed(2)}% confidence)",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Blood finding
                                if (bloodStatus != null && bloodStatus != "none")
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• ",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.orange.shade700,
                                                height: 1.4,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: "Blood ",
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text: "(${bloodConfidence.toStringAsFixed(2)}% confidence)",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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

                /// 📝 Recommendation Card (like result screen)
                if (recommendations.isNotEmpty)
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
                          ...recommendations.map((item) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get additional findings text for list view
  String _getAdditionalFindingsText(Map<String, dynamic> item) {
    final parasiteStatus = item["parasite"];
    final bloodStatus = item["blood"];
    final List<String> findings = [];

    if (parasiteStatus != null && parasiteStatus != "none") {
      final parasiteConfidence = double.tryParse(item["parasiteConfidence"].toString()) ?? 0;
      findings.add("Parasite (${parasiteConfidence.toStringAsFixed(2)}%)");
    }

    if (bloodStatus != null && bloodStatus != "none") {
      final bloodConfidence = double.tryParse(item["bloodConfidence"].toString()) ?? 0;
      findings.add("Blood (${bloodConfidence.toStringAsFixed(2)}%)");
    }

    return findings.isEmpty ? "Additional Findings: None" : "Additional Findings: ${findings.join(", ")}";
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
                  ? "${(double.tryParse(item["confidence"].toString()) ?? 0).toStringAsFixed(2)}%"
                  : "N/A";
                
                final additionalFindingsText = _getAdditionalFindingsText(item);

                return GestureDetector(
                  onTap: () => _showHistoryDetails(item),
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
                              const SizedBox(height: 2),
                              Text(
                                additionalFindingsText,
                                style: TextStyle(
                                  color: additionalFindingsText == "Additional Findings: None" 
                                    ? Colors.white54 
                                    : Colors.orange.shade300,
                                  fontSize: 11,
                                ),
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