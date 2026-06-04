import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewCrewScreen extends StatelessWidget {
  const ViewCrewScreen({super.key});

  Future<void> acceptApplication(String id) async {
    await FirebaseFirestore.instance
        .collection('crew_applications')
        .doc(id)
        .update({'status': 'accepted'});
  }

  Future<void> rejectApplication(String id) async {
    await FirebaseFirestore.instance
        .collection('crew_applications')
        .doc(id)
        .update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crew Applications"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('crew_applications')
            .snapshots(),

        builder: (context, snapshot) {

          // ✅ HANDLE ERROR (IMPORTANT FIX)
          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong ❌"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Applications Found"),
            );
          }

          var applications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {

              try {
                var data = applications[index];
                String id = data.id;

                final map = data.data() as Map<String, dynamic>;

                String name = map['name'] ?? 'N/A';
                String email = map['email'] ?? 'N/A';
                String status = map['status'] ?? 'N/A';
                String contact = map['contact'] ?? 'N/A';
                String nationality = map['nationality'] ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text("Name: $name"),
                        Text("Email: $email"),
                        Text("Contact: $contact"),
                        Text("Nationality: $nationality"),
                        Text("Status: $status"),

                        const SizedBox(height: 10),

                        if (status == "pending")
                          Row(
                            children: [

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => acceptApplication(id),
                                child: const Text("Accept"),
                              ),

                              const SizedBox(width: 10),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => rejectApplication(id),
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );

              } catch (e) {
                return const ListTile(
                  title: Text("Error loading item"),
                );
              }
            },
          );
        },
      ),
    );
  }
}
