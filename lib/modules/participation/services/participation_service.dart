import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/participation_model.dart';

class ParticipationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'participations';

  // US20: Register for Event
  Future<void> registerForEvent(String eventId, String eventTitle) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Prevent duplicate registration
    final existing = await _firestore.collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();
        
    if (existing.docs.isNotEmpty) {
      throw Exception('You are already registered for this event.');
    }

    // Fetch user profile to save name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final record = ParticipationModel(
      eventId: eventId,
      eventTitle: eventTitle,
      userId: user.uid,
      userName: userData['fullname'] ?? userData['fullName'] ?? userData['name'] ?? user.email ?? 'Student',
      userEmail: user.email ?? '',
      status: 'Registered',
      registeredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add(record.toMap());
  }

  // US21: Track participants for organizers - Sorted in memory to avoid index requirement
  Stream<List<ParticipationModel>> getParticipantsForEvent(String eventId) {
    if (eventId.isEmpty) return Stream.value([]);
    
    return _firestore.collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => ParticipationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
            .toList();
          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          return list;
        });
  }

  // Check if user is registered for a specific event
  Stream<ParticipationModel?> getUserParticipation(String eventId) {
    final user = _auth.currentUser;
    if (user == null || eventId.isEmpty) return Stream.value(null);

    return _firestore.collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ParticipationModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data() as Map<String, dynamic>?);
        });
  }

  // Get all events a user has registered for - Sorted in memory
  Stream<List<ParticipationModel>> getUserParticipations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) {
              try {
                return ParticipationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>?);
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

  // US21: Organizer can mark participant status
  Future<void> updateParticipationStatus(String participationId, String status) async {
    final updates = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'Attended') {
      updates['attendanceMarkedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection(_collection).doc(participationId).update(updates);
  }

  // US23: Submit feedback
  Future<void> submitFeedback(String participationId, String comment, double rating) async {
    final batch = _firestore.batch();
    
    final participationRef = _firestore.collection(_collection).doc(participationId);
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

  // Get feedback for an event
  Stream<List<Map<String, dynamic>>> getFeedbackForEvent(String eventId) {
    if (eventId.isEmpty) return Stream.value([]);
    
    return _firestore.collection('eventFeedback')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Check if feedback already submitted for event by user
  Future<bool> hasSubmittedFeedback(String eventId) async {
    final user = _auth.currentUser;
    if (user == null || eventId.isEmpty) return false;

    final existing = await _firestore.collection('eventFeedback')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();
    
    return existing.docs.isNotEmpty;
  }
}
