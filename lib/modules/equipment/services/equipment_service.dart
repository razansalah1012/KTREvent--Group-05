import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/equipment_model.dart';
import '../models/equipment_request_model.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addEquipment(EquipmentModel equipment) async {
    await _firestore.collection('equipment').add(equipment.toMap());
  }

  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    await _firestore.collection('equipment').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEquipment(String id) async {
    await _firestore.collection('equipment').doc(id).delete();
  }

  Stream<List<EquipmentModel>> getAllEquipment() {
    return _firestore.collection('equipment').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EquipmentModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> submitRequest({
    required String equipmentId,
    required String equipmentName,
    required int quantity,
    required String eventName,
    String? eventId,
    required String reason,
    required DateTime borrowedDate,
    required DateTime returnDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final existing = await _firestore
        .collection('equipment_requests')
        .where('requesterId', isEqualTo: user.uid)
        .where('equipmentName', isEqualTo: equipmentName)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You already have a pending request for this item.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final request = EquipmentRequestModel(
      id: '',
      equipmentName: equipmentName,
      quantity: quantity,
      requesterId: user.uid,
      requesterName: userData['fullname'] ?? userData['name'] ?? 'Unknown',
      requesterEmail: user.email ?? '',
      eventName: eventName,
      eventId: eventId,
      reason: reason,
      borrowedDate: borrowedDate,
      returnDate: returnDate,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('equipment_requests').add(request.toMap());
  }

  Stream<List<EquipmentRequestModel>> getRequests({
    String? userId,
    String? status,
  }) {
    Query query = _firestore.collection('equipment_requests');
    if (userId != null) {
      query = query.where('requesterId', isEqualTo: userId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(
            (doc) => EquipmentRequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<void> updateRequestStatus(
    String requestId,
    String newStatus, {
    String? adminComment,
  }) async {
    final batch = _firestore.batch();
    final requestRef = _firestore
        .collection('equipment_requests')
        .doc(requestId);

    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) return;

    final requestData = requestDoc.data() as Map<String, dynamic>;
    final equipmentName = requestData['equipmentName'];
    final quantity = requestData['quantity'] ?? 0;
    final requesterId = requestData['requesterId'];

    Map<String, dynamic> updateData = {
      'status': newStatus.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (adminComment != null) updateData['adminComment'] = adminComment;

    batch.update(requestRef, updateData);

    if (newStatus.toLowerCase() == 'approved') {
      final equipSnapshot = await _firestore
          .collection('equipment')
          .where('name', isEqualTo: equipmentName)
          .limit(1)
          .get();

      if (equipSnapshot.docs.isNotEmpty) {
        final equipDoc = equipSnapshot.docs.first;
        final available = equipDoc.data()['availableQuantity'] ?? 0;
        if (available >= quantity) {
          batch.update(equipDoc.reference, {
            'availableQuantity': FieldValue.increment(-quantity),
          });
        } else {
          throw Exception('Not enough equipment available');
        }
      }
    } else if (newStatus.toLowerCase() == 'returned') {
      final equipSnapshot = await _firestore
          .collection('equipment')
          .where('name', isEqualTo: equipmentName)
          .limit(1)
          .get();

      if (equipSnapshot.docs.isNotEmpty) {
        batch.update(equipSnapshot.docs.first.reference, {
          'availableQuantity': FieldValue.increment(quantity),
        });
      }
    }

    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': requesterId,
      'title': 'Equipment Request ${newStatus.toUpperCase()}',
      'message':
          'Your request for $equipmentName ($quantity units) has been $newStatus.',
      'type': 'equipment_request_update',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }
}
