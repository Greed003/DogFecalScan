import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactVetScreen extends StatefulWidget {
  const ContactVetScreen({super.key});

  @override
  State<ContactVetScreen> createState() => _ContactVetScreenState();
}

class _ContactVetScreenState extends State<ContactVetScreen> {
  final List<Map<String, String>> vets = [
    {
      "city": "San Juan",
      "clinic": "Animaland Veterinary Clinic and Diagnostic Center",
      "address": "Urbiztondo, San Juan, La Union",
      "phone": "09175002313"
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  /// 📞 Tap to call
  void _callVet(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar("Unable to open phone dialer.");
    }
  }

  /// 📋 Long press to copy
  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    _showSnackBar("📋 Phone number $phone copied");
  }

  /// 💬 Handle SMS - ALWAYS check SharedPreferences directly (no memory variable)
  void _handleSmsVet(String phone, String clinicName) async {
    // Always check SharedPreferences directly to get the latest data
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList("history") ?? [];
    
    if (history.isEmpty) {
      // No history - open SMS directly with no message
      _openSMS(phone);
    } else {
      // Has history - get the latest scan and ask user
      final decoded = history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      final currentLastScan = decoded.last;
      _showSmsOptionDialog(phone, clinicName, currentLastScan);
    }
  }

  /// 🗨️ Show dialog to choose SMS option with better UI
  void _showSmsOptionDialog(String phone, String clinicName, Map<String, dynamic> currentScan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      Icons.medical_services,
                      size: 48,
                      color: Colors.brown[700],
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      "Include Scan Results?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      "Would you like to include your latest stool scan results in the message to the vet?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        // No button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _openSMS(phone); // Open with no message
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.brown[700],
                              side: BorderSide(color: Colors.brown[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Just Message",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Yes button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendSMSWithScan(phone, clinicName, currentScan);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Include Results",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Close (X) button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  color: Colors.grey[600],
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 💬 Send SMS with specific scan data
  void _sendSMSWithScan(String phone, String clinicName, Map<String, dynamic> scanData) async {
    final status = scanData["status"] ?? "Unknown";
    final date = scanData["date"] ?? DateFormat('MMM d, yyyy').format(DateTime.now());
    
    // Get additional findings
    final parasiteStatus = scanData["parasite"];
    final bloodStatus = scanData["blood"];

    // Build the stool description
    String stoolDescription = _buildStoolDescription(status, parasiteStatus, bloodStatus);

    String message =
        "Date: $date\n\n"
        "Hello Dr. $clinicName,\n\n"
        "$stoolDescription\n\n"
        "Could you please advise me on what to do next?\n\n"
        "Thank you!";

    final smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Your device's SMS app cannot handle messages from apps.");
    }
  }

  /// 💬 Open SMS with no pre-filled message
  void _openSMS(String phone) async {
    String message = "";
    final smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
  
    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Your device's SMS app cannot handle messages from apps.");
    }
  }

  /// 🔹 Build stool description based on classification and additional findings
  String _buildStoolDescription(String status, dynamic parasiteStatus, dynamic bloodStatus) {
    final hasParasite = parasiteStatus != null && parasiteStatus != "none";
    final hasBlood = bloodStatus != null && bloodStatus != "none";
    
    String description = "My dog's stool is $status";
    
    if (hasParasite && hasBlood) {
      description += " with possible Parasite and Blood";
    } else if (hasParasite) {
      description += " with possible Parasite";
    } else if (hasBlood) {
      description += " with possible Blood";
    }
    
    description += ".";
    
    return description;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
                    onLongPress: () => _copyPhone(vet["phone"]!),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        // ------------- SMS BUTTON -------------
                        GestureDetector(
                          onTap: () => _handleSmsVet(vet["phone"]!, vet["clinic"]!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.sms, color: Colors.white),
                          ),
                        ),
                        // ------------- CALL BUTTON -------------
                        GestureDetector(
                          onTap: () => _callVet(vet["phone"]!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.call, color: Colors.white),
                          ),
                        ),
                      ],
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