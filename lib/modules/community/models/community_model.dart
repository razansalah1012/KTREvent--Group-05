import 'package:cloud_firestore/cloud_firestore.dart';

class EventCommunityModel {
  String? id;
  final String eventId;
  final String eventTitle;
  final String leaderId;
  final DateTime createdAt;

  EventCommunityModel({
    this.id,
    required this.eventId,
    required this.eventTitle,
    required this.leaderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'leaderId': leaderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EventCommunityModel.fromMap(String id, Map<String, dynamic> map) {
    return EventCommunityModel(
      id: id,
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? 'Unknown Event',
      leaderId: map['leaderId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class CommunityMemberModel {
  String? id;
  final String communityId;
  final String eventId;
  final String userId;
  final String userName;
  final String role;
  final DateTime joinedAt;

  CommunityMemberModel({
    this.id,
    required this.communityId,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory CommunityMemberModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityMemberModel(
      id: id,
      communityId: map['communityId'] ?? '',
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      role: map['role'] ?? 'Organizer',
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class CommunityMessageModel {
  String? id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  CommunityMessageModel({
    this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory CommunityMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityMessageModel(
      id: id,
      communityId: map['communityId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      text: map['text'] ?? '',
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
