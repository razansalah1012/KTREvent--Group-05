import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> requestEquipment({
    required String equipmentName,
    required int quantity,
    required String requester,
  }) async {
    await _firestore.collection('equipment_requests').add({
      'equipmentName': equipmentName,
      'quantity': quantity,
      'requester': requester,
      'status': 'Pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getRequests() {
    return _firestore.collection('equipment_requests').snapshots();
  }
}
