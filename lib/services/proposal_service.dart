import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get proposals
  Stream<QuerySnapshot> getProposals() {
    return _firestore.collection('proposals').snapshots();
  }

  // ✅ Approve proposal
  Future<void> approveProposal(String id) async {
    await _firestore.collection('proposals').doc(id).update({
      'status': 'approved',
      'reason': null, // remove reason if previously rejected
    });
  }

  // ✅ Reject proposal with reason
  Future<void> rejectProposal(String id) async {
    await _firestore.collection('proposals').doc(id).update({
      'status': 'rejected',
      'reason': 'Not approved',
    });
  }
}