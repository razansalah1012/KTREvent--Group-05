import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'events';

  Future<void> createEvent(EventModel event) async {
    try {
      // Ensure we have a logged-in user to assign as the organizer
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Add the document to Firestore
      DocumentReference docRef = await _firestore.collection(_collectionName).add({
        ...event.toMap(),
        'organizerId': currentUser.uid, // Override with actual UID for security
      });
      
      // Optional: Update the model with the generated Firestore ID
      event.id = docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Fetches all events created by the currently logged-in user
  Stream<List<EventModel>> getMyEvents() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    return _firestore
        .collection(_collectionName)
        .where('organizerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          date: DateTime.parse(data['date']),
          location: data['location'] ?? '',
          organizerId: data['organizerId'] ?? '',
        );
      }).toList();
    });
  }

  /// Updates an existing event in Firestore
  Future<void> updateEvent(EventModel event) async {
    try {
      if (event.id == null) throw Exception('Event ID is missing');
      
      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toMap());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Deletes an event from Firestore
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
}