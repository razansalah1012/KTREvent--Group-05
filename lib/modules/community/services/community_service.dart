import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<EventCommunityModel> getOrCreateCommunity(
    String eventId,
    String eventTitle,
    String leaderId,
    String leaderName,
  ) async {
    final snapshot = await _firestore
        .collection('event_communities')
        .where('eventId', isEqualTo: eventId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return EventCommunityModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    }

    final newCommunity = EventCommunityModel(
      eventId: eventId,
      eventTitle: eventTitle,
      leaderId: leaderId,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('event_communities')
        .add(newCommunity.toMap());

    await addMember(
      communityId: docRef.id,
      eventId: eventId,
      userId: leaderId,
      userName: leaderName,
      role: 'Leader',
    );

    return EventCommunityModel(
      id: docRef.id,
      eventId: eventId,
      eventTitle: eventTitle,
      leaderId: leaderId,
      createdAt: newCommunity.createdAt,
    );
  }

  Stream<List<EventCommunityModel>> getMyCommunities(String userId) {
    return _firestore
        .collection('community_members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((memberSnapshot) async {
          if (memberSnapshot.docs.isEmpty) return [];

          final communityIds = memberSnapshot.docs
              .map((d) => d.data()['communityId'] as String)
              .toList();

          List<EventCommunityModel> communities = [];
          for (int i = 0; i < communityIds.length; i += 10) {
            final chunk = communityIds.sublist(
              i,
              i + 10 > communityIds.length ? communityIds.length : i + 10,
            );
            final commSnapshot = await _firestore
                .collection('event_communities')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            communities.addAll(
              commSnapshot.docs.map(
                (d) => EventCommunityModel.fromMap(d.id, d.data()),
              ),
            );
          }

          return communities;
        });
  }

  Future<void> addMember({
    required String communityId,
    required String eventId,
    required String userId,
    required String userName,
    required String role,
  }) async {
    final existing = await _firestore
        .collection('community_members')
        .where('communityId', isEqualTo: communityId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existing.docs.isNotEmpty) return;

    final member = CommunityMemberModel(
      communityId: communityId,
      eventId: eventId,
      userId: userId,
      userName: userName,
      role: role,
      joinedAt: DateTime.now(),
    );

    await _firestore.collection('community_members').add(member.toMap());
  }

  Future<void> removeMember(String communityId, String userId) async {
    final snapshot = await _firestore
        .collection('community_members')
        .where('communityId', isEqualTo: communityId)
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<CommunityMemberModel>> getMembers(String communityId) {
    return _firestore
        .collection('community_members')
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs
              .map((doc) => CommunityMemberModel.fromMap(doc.id, doc.data()))
              .toList();
          members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
          return members;
        });
  }

  Future<void> sendMessage(
    String communityId,
    String senderId,
    String senderName,
    String text, [
    String? eventTitle,
  ]) async {
    final msg = CommunityMessageModel(
      communityId: communityId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: DateTime.now(),
    );
    await _firestore.collection('community_messages').add(msg.toMap());

    try {
      final membersSnap = await _firestore
          .collection('community_members')
          .where('communityId', isEqualTo: communityId)
          .get();

      final title = eventTitle != null
          ? 'New message in $eventTitle'
          : 'New Community Message';
      final snippet = text.length > 40 ? '${text.substring(0, 40)}...' : text;

      for (var doc in membersSnap.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null && userId != senderId) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'title': title,
            'message': '$senderName: $snippet',
            'type': 'chat_message',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {}
  }

  Stream<List<CommunityMessageModel>> getMessages(String communityId) {
    return _firestore
        .collection('community_messages')
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => CommunityMessageModel.fromMap(doc.id, doc.data()))
              .toList();
          messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return messages;
        });
  }
}
