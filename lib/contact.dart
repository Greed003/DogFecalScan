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
  Map<String, dynamic>? lastScan;

  final List<Map<String, String>> vets = [
    {
      "city": "Bacnotan",
      "clinic": "NeerVet Animal Clinic",
      "address": "Leoncia Bldg., 118 Poblacion, Bacnotan, La Union",
      "phone": "09564926029"
    },
    {
      "city": "Bangar",
      "clinic": "Gentle Paws Animal Clinic",
      "address": "San Blas, Bangar, La Union",
      "phone": "09610127966"
    },
    {
      "city": "Santo Tomas",
      "clinic": "Paw-Protect Veterinary Clinic",
      "address": "Lomboy, Santo Tomas, La Union",
      "phone": "09177024726"
    },
    {
      "city": "Agoo",
      "clinic": "AGOO ANIMAL CLINIC AND GROOMING CENTER",
      "address": "002 San Vicente Sur, Agoo, 2504 La Union",
      "phone": "09693864631"
    },
    {
      "city": "Bauang",
      "clinic": "Bauang Vet Care Clinic",
      "address": "Villa Marand, Baccuit Sur, Bauang, La Union",
      "phone": "09357168082"
    },
    {
      "city": "San Fernando",
      "clinic": "Valley Vets Animal Clinic",
      "address": "Real Bldg., Lingsat, City of San Fernando, La Union",
      "phone": "09069620694"
    },
    {
      "city": "San Juan",
      "clinic": "Elyu Veterinary Care Clinic",
      "address": "Agripina Complex, Ili Norte, San Juan, La Union",
      "phone": "09568563904"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLastScan();
  }

  /// 🔹 Get the most recent history record
  Future<void> _loadLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList("history") ?? [];
    if (history.isNotEmpty) {
      final decoded = history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      setState(() {
        lastScan = decoded.last; // last (newest)
      });
    }
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

  /// 💬 Send SMS with last scan details
  void _smsVet(String phone, String clinicName) async {
    if (lastScan == null) {
      _showSnackBar("No recent scan found to send.");
      return;
    }

    final status = lastScan!["status"] ?? "Unknown";
    final confidence = lastScan!["confidence"]?.toString() ?? "N/A";
    final date = lastScan!["date"] ?? DateFormat('MMM d, yyyy').format(DateTime.now());

    final message =
        "Hello Dr. $clinicName,\n\n"
        "Here is my dog latest fecal scan result:\n"
        "Classification: $status\n"
        "Confidence: $confidence%\n"
        "Date: $date\n\n"
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
                    // Removed onTap — now user taps only the call button
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
                        // ------------- SMS BUTTON (same style as call) -------------
                        GestureDetector(
                          onTap: () => _smsVet(vet["phone"]!, vet["clinic"]!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,   // SMS color (feel free to change)
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
