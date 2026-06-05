import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'events';

  Future<void> createEvent(EventModel event) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final eventToCreate = EventModel(
        title: event.title,
        description: event.description,
        date: event.date,
        location: event.location,
        organizerId: currentUser.uid,
        crewSlots: event.crewSlots,
        crewDeadline: event.crewDeadline,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(eventToCreate.toCreateMap());

      event.id = docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Stream<List<EventModel>> getMyEvents() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection(_collectionName)
        .where('organizerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  Stream<List<EventModel>> getAllEvents() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      if (event.id == null) {
        throw Exception('Event ID is missing');
      }

      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toUpdateMap());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<EventModel> getEventById(String eventId) async {
    final doc = await _firestore.collection(_collectionName).doc(eventId).get();
    if (!doc.exists) throw Exception('Event not found');
    return EventModel.fromFirestore(doc);
  }
}
