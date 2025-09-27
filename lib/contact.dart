import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/services.dart'; 

class ContactVetScreen extends StatelessWidget {
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