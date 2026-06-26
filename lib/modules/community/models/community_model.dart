import 'package:cloud_firestore/cloud_firestore.dart';

class EventCommunityModel {
  final String? id;
  final String eventId;
  final String eventTitle;
  final String leaderId;
  final String leaderName;

  EventCommunityModel({
    this.id,
    required this.eventId,
    required this.eventTitle,
    required this.leaderId,
    required this.leaderName,
  });

  factory EventCommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventCommunityModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      leaderId: data['leaderId'] ?? '',
      leaderName: data['leaderName'] ?? '',
    );
  }
}

class CommunityMemberModel {
  final String? id;
  final String userId;
  final String userName;
  final String role;
  
  CommunityMemberModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.role,
  });

  factory CommunityMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityMemberModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      role: data['role'] ?? '',
    );
  }
}