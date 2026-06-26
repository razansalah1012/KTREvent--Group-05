import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getProposals() {
    return _firestore.collection('proposals').snapshots();
  }

  Future<void> approveProposal(String id) async {
    await _firestore.collection('proposals').doc(id).update({
      'status': 'approved',
      'reason': null, 
    });
  }

  Future<void> rejectProposal(String id) async {
    await _firestore.collection('proposals').doc(id).update({
      'status': 'rejected',
      'reason': 'Not approved',
    });
  }
}