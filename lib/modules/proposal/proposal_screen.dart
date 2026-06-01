import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/proposal_service.dart';

class ProposalScreen extends StatelessWidget {
  final ProposalService service = ProposalService();

  ProposalScreen({super.key});

  // ✅ Status colors

  Color getStatusColor(String status) {
  if (status == "approved") return Colors.green;
  if (status == "rejected") return Colors.red;
  return Colors.grey; // clean instead of orange
}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ✅ AppBar
      appBar: AppBar(
        title: const Text(
          "Proposal Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade900,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: service.getProposals(),
        builder: (context, snapshot) {

          // ✅ Loading
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var proposals = snapshot.data!.docs;

          // ✅ Empty state
          if (proposals.isEmpty) {
            return const Center(
              child: Text(
                "No proposals available",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              var data = proposals[index];


return Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  elevation: 3,
  child: Padding(
    padding: const EdgeInsets.all(12),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ✅ TITLE
        Text(
          data['title'] ?? "No Title",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        // ✅ STATUS
        Text(
          "Status: ${data['status']}",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: getStatusColor(data['status']),
          ),
        ),

        // ✅ REASON (only if rejected)
        if (data['status'] == 'rejected')
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Reason: ${data['reason'] ?? 'Not approved'}",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),

        const SizedBox(height: 10),

        // ✅ BUTTONS (ONLY WHEN PENDING)
        if (data['status'] == 'pending')
          Row(
            children: [

              // ✅ APPROVE BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () {
                  service.approveProposal(data.id);
                },
                child: const Text("Approve"),
              ),

              const SizedBox(width: 10),

              // ✅ REJECT BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(100, 40),
                ),
                onPressed: () {
                  service.rejectProposal(data.id);
                },
                child: const Text("Reject"),
              ),
            ],
          ),
      ],
    ),
  ),
);
            },
          );
        },
      ),
    );
  }
}