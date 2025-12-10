import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_application_1/contact.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> historyData = [];
  Map<String, List<Map<String, dynamic>>> groupedHistory = {};
  Map<String, bool> alertStatus = {};
  Map<String, String> originalCaseNames = {}; // Store original case for display

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
          .toList();
      
      // Group by dog name (case-insensitive)
      _groupHistory();
      _checkAlerts();
    });
  }

  void _groupHistory() {
    groupedHistory.clear();
    originalCaseNames.clear();
    
    for (var item in historyData) {
      String dogName = item["dogName"] ?? "Unknown Dog";
      String normalizedName = dogName.toLowerCase().trim();
      
      // Store the original case for display (use first occurrence's case)
      if (!originalCaseNames.containsKey(normalizedName)) {
        originalCaseNames[normalizedName] = dogName;
      }
      
      if (!groupedHistory.containsKey(normalizedName)) {
        groupedHistory[normalizedName] = [];
      }
      groupedHistory[normalizedName]!.add(item);
    }
    
    // Sort grouped history: "unknown dog" first, then alphabetically
    final sortedEntries = groupedHistory.entries.toList()
      ..sort((a, b) {
        // Put "unknown dog" first
        if (a.key == "unknown dog") return -1;
        if (b.key == "unknown dog") return 1;
        
        // Then sort alphabetically by display name
        final nameA = originalCaseNames[a.key] ?? a.key;
        final nameB = originalCaseNames[b.key] ?? b.key;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
    
    // Convert back to map with sorted order
    groupedHistory = Map.fromEntries(sortedEntries);
  }
  
  void _checkAlerts() {
    alertStatus.clear();
    final now = DateTime.now();
    
    groupedHistory.forEach((normalizedName, scans) {
      // Get original case name for display/checks
      String displayName = originalCaseNames[normalizedName] ?? normalizedName;
      
      // Skip alerts for "Unknown Dog" or empty names (case-insensitive check)
      if (normalizedName == "unknown dog" || normalizedName.isEmpty) {
        alertStatus[displayName] = false;
        return;
      }

      // Get unique dates with problematic scans
      Set<String> problematicDates = {};
      
      for (var scan in scans) {
        try {
          final scanDate = DateTime.parse(scan["date"]);
          final daysDifference = now.difference(scanDate).inDays;
          
          // Only check scans from last 3 days
          if (daysDifference <= 3) {
            final status = scan["status"]?.toString().toLowerCase() ?? "";
            final parasite = scan["parasite"]?.toString().toLowerCase() ?? "none";
            final blood = scan["blood"]?.toString().toLowerCase() ?? "none";
            
            // Check if this scan is problematic
            final isProblematic = status == "watery" || 
                                 parasite != "none" || 
                                 blood != "none";
            
            if (isProblematic) {
              // Add date to problematic dates (format: YYYY-MM-DD)
              final dateStr = "${scanDate.year}-${scanDate.month.toString().padLeft(2, '0')}-${scanDate.day.toString().padLeft(2, '0')}";
              problematicDates.add(dateStr);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Count unique problematic days (max 1 per day)
      final uniqueProblematicDays = problematicDates.length;

      // Alert if 3 or more unique days with problematic scans in last 3 days
      alertStatus[displayName] = uniqueProblematicDays >= 3;
    });
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = historyData
        .map((item) => jsonEncode(item))
        .toList()
        .reversed
        .toList();
    await prefs.setStringList("history", historyList.toList());
  }

  Future<void> deleteScan(Map<String, dynamic> scan) async {
    // Find the scan in historyData
    final index = historyData.indexWhere((item) {
      if (item["timestamp"] != null && scan["timestamp"] != null) {
        return item["timestamp"] == scan["timestamp"];
      }
      return item["date"] == scan["date"] && 
             item["status"] == scan["status"] &&
             (item["dogName"] ?? "Unknown Dog").toLowerCase() == (scan["dogName"] ?? "Unknown Dog").toLowerCase();
    });
    
    if (index != -1) {
      // Remove the scan and update state
      setState(() {
        historyData.removeAt(index);
        // Rebuild grouped data
        _groupHistory();
        _checkAlerts();
      });
      
      await saveHistory();
    }
  }

  Future<void> clearDogHistory(String dogName) async {
    String normalizedName = dogName.toLowerCase();
    
    setState(() {
      historyData.removeWhere((item) => 
        (item["dogName"] ?? "Unknown Dog").toLowerCase() == normalizedName);
      _groupHistory();
      _checkAlerts();
    });
    
    await saveHistory();
  }

  Future<void> updateScanDogName(Map<String, dynamic> scan, String newDogName) async {
    // Find and update the scan
    for (int i = 0; i < historyData.length; i++) {
      final item = historyData[i];
      if (item["timestamp"] != null && scan["timestamp"] != null) {
        if (item["timestamp"] == scan["timestamp"]) {
          setState(() {
            historyData[i] = {...item, "dogName": newDogName};
            _groupHistory();
            _checkAlerts();
          });
          break;
        }
      } else if (item["date"] == scan["date"] && 
                 item["status"] == scan["status"] &&
                 (item["dogName"] ?? "Unknown Dog").toLowerCase() == (scan["dogName"] ?? "Unknown Dog").toLowerCase()) {
        setState(() {
          historyData[i] = {...item, "dogName": newDogName};
          _groupHistory();
          _checkAlerts();
        });
        break;
      }
    }
    
    await saveHistory();
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

  Future<void> _showAddDogNameDialog(BuildContext context, {Map<String, dynamic>? existingScan}) async {
    String dogName = existingScan?["dogName"] ?? "";
    final TextEditingController controller = TextEditingController(text: dogName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3B2A20),
        title: const Text("Add/Edit Dog Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter dog name",
            hintStyle: const TextStyle(color: Colors.white60),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (value) {
            dogName = value.trim();
          },
          onSubmitted: (value) {
            dogName = value.trim();
            Navigator.pop(context, dogName);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              dogName = controller.text.trim();
              Navigator.pop(context, dogName);
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFFD7C49E))),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && existingScan != null) {
      await updateScanDogName(existingScan, result);
    }
  }

  void _showHistoryDetails(Map<String, dynamic> item, BuildContext context) {
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
          final decoded = jsonDecode(item["recommendations"]);
          if (decoded is List) {
            recommendations = List<String>.from(decoded);
          } else if (item["recommendations"].contains('||')) {
            recommendations = (item["recommendations"] as String).split('||');
          } else {
            recommendations = [item["recommendations"] as String];
          }
        } else if (item["recommendations"] is List) {
          recommendations = List<String>.from(item["recommendations"]);
        }
      } catch (e) {
        if (item["recommendations"] is String) {
          recommendations = (item["recommendations"] as String).split('||');
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (detailsContext) => Scaffold(
          backgroundColor: const Color(0xFF3B2A20),
          appBar: AppBar(
            title: Text("${item["dogName"] ?? "Unknown Dog"} - Result", 
              style: const TextStyle(color: Color(0xFFD7C49E))),
            backgroundColor: const Color(0xFF3B2A20),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFD7C49E)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await _showAddDogNameDialog(detailsContext, existingScan: item);
                  if (detailsContext.mounted) {
                    Navigator.pop(detailsContext);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: detailsContext,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF3B2A20),
                      title: const Text("Delete Scan", style: TextStyle(color: Colors.white)),
                      content: const Text(
                        "Are you sure you want to delete this scan?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                          onPressed: () => Navigator.pop(dialogContext, false),
                        ),
                        TextButton(
                          child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                          onPressed: () async {
                            await deleteScan(item);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                            if (detailsContext.mounted) {
                              Navigator.pop(detailsContext);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 🖼️ Image with Blur
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

                /// 🩺 Additional Findings Display
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
                                                  text: "Visible Parasite ",
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
                                                  text: "Visible Blood ",
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

                /// 📝 Recommendation Card
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
                          ...recommendations.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "• ",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.brown,
                                      height: 1.4,
                                    ),
                                  ),
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

    return findings.isEmpty ? "Additional Findings: None" : "Additional: ${findings.join(", ")}";
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
              tooltip: "Clear All History",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF3B2A20),
                    title: const Text("Clear All History", style: TextStyle(color: Colors.white)),
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
                        child: const Text("Clear All", style: TextStyle(color: Colors.redAccent)),
                        onPressed: () async {
                          setState(() {
                            historyData.clear();
                            groupedHistory.clear();
                            alertStatus.clear();
                            originalCaseNames.clear();
                          });
                          await saveHistory();
                          Navigator.pop(context, true);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        backgroundColor: const Color(0xFF3B2A20),
        color: const Color(0xFFD7C49E),
        child: historyData.isEmpty
            ? const Center(
                child: Text("No history yet", style: TextStyle(color: Colors.white)),
              )
            : ListView(
                children: [
                  // Alert Section - Only show for named dogs with alerts
                  if (alertStatus.entries.any((entry) => 
                      entry.value && 
                      entry.key.toLowerCase() != "unknown dog" && 
                      entry.key.trim().isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        color: Colors.red.shade900.withOpacity(0.8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade300),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Veterinary Alert",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...alertStatus.entries.where((entry) => 
                                entry.value && 
                                entry.key.toLowerCase() != "unknown dog" && 
                                entry.key.trim().isNotEmpty
                              ).map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${entry.key} has had problematic stool for 3 consecutive days. Veterinary attention is recommended.",
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ContactVetScreen()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                        child: const Text("Contact Vet"),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Grouped History - Display using original case names
                  ...groupedHistory.entries.map((entry) {
                    final normalizedName = entry.key;
                    final displayName = originalCaseNames[normalizedName] ?? normalizedName;
                    final scans = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Card(
                        color: const Color(0xFF4B3B2D),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dog Name Header
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Color(0xFFD7C49E),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Show warning icon only for named dogs with alerts
                                  if (alertStatus[displayName] == true && 
                                      normalizedName != "unknown dog" && 
                                      displayName.trim().isNotEmpty)
                                    Icon(Icons.warning, color: Colors.orange.shade300, size: 24),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                                    color: const Color(0xFF3B2A20),
                                    onSelected: (value) async {
                                      if (value == 'edit' && scans.isNotEmpty) {
                                        await _showAddDogNameDialog(context, existingScan: scans.first);
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF3B2A20),
                                            title: const Text("Delete All Scans", style: TextStyle(color: Colors.white)),
                                            content: Text(
                                              "Are you sure you want to delete all scans for $displayName?",
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                                onPressed: () async {
                                                  await clearDogHistory(displayName);
                                                  Navigator.pop(context, true);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Dog Name', style: TextStyle(color: Colors.white)),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete All for This Dog', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Scans List
                            ...scans.map((item) {
                              final String status = item["status"];
                              final String? imagePath = item["imagePath"];
                              final String confidence = item["confidence"] != null
                                ? "${(double.tryParse(item["confidence"].toString()) ?? 0).toStringAsFixed(2)}%"
                                : "N/A";
                              
                              final additionalFindingsText = _getAdditionalFindingsText(item);
                              
                              return GestureDetector(
                                onTap: () => _showHistoryDetails(item, context),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white30),
                                    borderRadius: BorderRadius.circular(15),
                                    color: const Color(0xFF5A4A3C),
                                  ),
                                  child: Row(
                                    children: [
                                      /// 🖼️ Thumbnail
                                      if (imagePath != null && File(imagePath).existsSync())
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: ImageFiltered(
                                            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                            child: Image.file(
                                              File(imagePath),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),

                                      const SizedBox(width: 12),

                                      /// Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item["date"], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "Confidence: $confidence",
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              additionalFindingsText,
                                              style: TextStyle(
                                                color: additionalFindingsText == "Additional Findings: None" 
                                                  ? Colors.white54 
                                                  : Colors.orange.shade300,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      /// Delete Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: const Color(0xFF3B2A20),
                                              title: const Text("Delete Scan", style: TextStyle(color: Colors.white)),
                                              content: const Text(
                                                "Are you sure you want to delete this scan?",
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                                                  onPressed: () => Navigator.pop(context, false),
                                                ),
                                                TextButton(
                                                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                                  onPressed: () async {
                                                    // Delete the scan
                                                    await deleteScan(item);
                                                    // Close the dialog
                                                    Navigator.pop(context, true);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
      ),
    );
  }
}