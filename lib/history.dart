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
