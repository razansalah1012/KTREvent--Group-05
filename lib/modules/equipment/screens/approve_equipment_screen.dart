import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveEquipmentScreen extends StatelessWidget {
  const ApproveEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Approve Requests"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipment_requests')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {

              return ListTile(
                title:
                Text(doc['equipmentName']),

                subtitle:
                Text(doc['status']),

                trailing: ElevatedButton(
                  child: const Text("Approve"),

                  onPressed: () async {

                    await FirebaseFirestore.instance
                        .collection(
                        'equipment_requests')
                        .doc(doc.id)
                        .update({
                      'status': 'Approved'
                    });
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
