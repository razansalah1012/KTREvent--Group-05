import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplyCrewScreen extends StatefulWidget {
  const ApplyCrewScreen({super.key});

  @override
  State<ApplyCrewScreen> createState() => _ApplyCrewScreenState();
}

class _ApplyCrewScreenState extends State<ApplyCrewScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final nationalityController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = false;
  String message = "";

  Future<void> applyAsCrew() async {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        nationalityController.text.isEmpty ||
        contactController.text.isEmpty ||
        emailController.text.isEmpty) {
      setState(() {
        message = "Please fill all fields ❌";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    int age = int.tryParse(ageController.text.trim()) ?? 0;

    try {
      await FirebaseFirestore.instance.collection('crew_applications').add({
        'name': nameController.text.trim(),
        'age': age,
        'nationality': nationalityController.text.trim(),
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'status': 'pending',
        'appliedAt': Timestamp.now(),
      });

      setState(() {
        message = "Application submitted ✅";
      });
    } catch (e) {
      setState(() {
        message = "Error ❌";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply as Crew")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: "Age"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: nationalityController,
              decoration: const InputDecoration(labelText: "Nationality"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: "Contact"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : applyAsCrew,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Apply", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 10),

            if (isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 10),

            Text(message),
          ],
        ),
      ),
    );
  }
}
