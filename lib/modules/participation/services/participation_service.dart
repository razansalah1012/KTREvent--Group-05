import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/participation_model.dart';

class ParticipationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'participations';

  Future<String> registerForEvent(
    String eventId,
    String eventTitle, {
    Map<String, dynamic>? registrationResponses,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final existing = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You are already registered for this event.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final record = ParticipationModel(
      eventId: eventId,
      eventTitle: eventTitle,
      userId: user.uid,
      userName:
          userData['fullname'] ??
          userData['fullName'] ??
          userData['name'] ??
          user.email ??
          'Student',
      userEmail: user.email ?? '',
      status: 'Registered',
      registeredAt: DateTime.now(),
      registrationResponses: registrationResponses,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore.collection(_collection).add(record.toMap());

    await _firestore.collection('events').doc(eventId).update({
      'registeredCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  Stream<List<ParticipationModel>> getParticipantsForEvent(String eventId) {
    if (eventId.isEmpty) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => ParticipationModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>?,
                ),
              )
              .toList();
          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          return list;
        });
  }

  Stream<ParticipationModel?> getUserParticipation(String eventId) {
    final user = _auth.currentUser;
    if (user == null || eventId.isEmpty) return Stream.value(null);

    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ParticipationModel.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>?,
          );
        });
  }

  Future<ParticipationModel> getParticipationById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Participation record not found');
    return ParticipationModel.fromMap(doc.id, doc.data());
  }

  Stream<List<ParticipationModel>> getUserParticipations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) {
                try {
                  return ParticipationModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>?,
                  );
                } catch (e) {
                  return null;
                }
              })
              .whereType<ParticipationModel>()
              .toList();

          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          return list;
        });
  }

  Future<void> updateParticipationStatus(
    String participationId,
    String status,
  ) async {
    final updates = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'Attended') {
      updates['attendanceMarkedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore
        .collection(_collection)
        .doc(participationId)
        .update(updates);
  }

  Future<void> submitFeedback(
    String participationId,
    String comment,
    double rating,
  ) async {
    final batch = _firestore.batch();

    final participationRef = _firestore
        .collection(_collection)
        .doc(participationId);
    batch.update(participationRef, {
      'feedbackSubmitted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final feedbackRef = _firestore.collection('eventFeedback').doc();

    final partDoc = await participationRef.get();
    final partData = partDoc.data();
    if (partData == null) return;

    batch.set(feedbackRef, {
      'eventId': partData['eventId'],
      'eventTitle': partData['eventTitle'],
      'userId': partData['userId'],
      'userName': partData['userName'],
      'rating': rating,
      'comment': comment,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getFeedbackForEvent(String eventId) {
    if (eventId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('eventFeedback')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<bool> hasSubmittedFeedback(String eventId) async {
    final user = _auth.currentUser;
    if (user == null || eventId.isEmpty) return false;

    final existing = await _firestore
        .collection('eventFeedback')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();

    return existing.docs.isNotEmpty;
  }
}
