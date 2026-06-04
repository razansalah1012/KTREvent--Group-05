import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/participation_model.dart';

class ParticipationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'participations';

  // SCRUM-85 & 87: Register a student for an event
  Future<void> registerForEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Prevent double registration
    final existing = await _firestore.collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: user.uid)
        .get();
        
    if (existing.docs.isNotEmpty) {
      throw Exception('You are already registered for this event.');
    }

    // Fetch user profile to save name/email
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final record = ParticipationModel(
      eventId: eventId,
      userId: user.uid,
      userName: userData['fullname'] ?? user.email ?? 'Student',
      userEmail: user.email ?? '',
      registeredAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add(record.toMap());
  }

  // SCRUM-86: Track participants for organizers
  Stream<List<ParticipationModel>> getParticipantsForEvent(String eventId) {
    return _firestore.collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // SCRUM-88: Submit feedback
  Future<void> submitFeedback(String participationId, String feedback, double rating) async {
    await _firestore.collection(_collection).doc(participationId).update({
      'feedback': feedback,
      'rating': rating,
    });
  }
}