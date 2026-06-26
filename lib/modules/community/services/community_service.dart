import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EventCommunityModel>> getMyCommunities(String userId) {
    return _firestore
        .collection('communities')
        .where('leaderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventCommunityModel.fromFirestore(doc))
            .toList());
  }

  Future<EventCommunityModel> getOrCreateCommunity(
      String eventId, String eventTitle, String userId, String userName) async {
    final query = await _firestore
        .collection('communities')
        .where('eventId', isEqualTo: eventId)
        .get();

    if (query.docs.isNotEmpty) {
      return EventCommunityModel.fromFirestore(query.docs.first);
    }

    final docRef = await _firestore.collection('communities').add({
      'eventId': eventId,
      'eventTitle': eventTitle,
      'leaderId': userId,
      'leaderName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return EventCommunityModel.fromFirestore(doc);
  }

  Stream<List<CommunityMemberModel>> getMembers(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMemberModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addMember({
    required String communityId,
    required String eventId,
    required String userId,
    required String userName,
    required String role,
  }) async {
    final query = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) {
      await _firestore
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .add({
        'userId': userId,
        'userName': userName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeMember(String communityId, String userId) async {
    final query = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }
}