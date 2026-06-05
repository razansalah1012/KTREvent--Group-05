import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackEquipmentScreen extends StatelessWidget {
  const TrackEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Equipment"),
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

              return Card(
                child: ListTile(
                  title:
                  Text(doc['equipmentName']),

                  subtitle: Text(
                      "Quantity: ${doc['quantity']}"
                  ),

                  trailing: Text(
                      doc['status']
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
