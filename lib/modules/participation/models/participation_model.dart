import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipationModel {
  String? id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String status; // Registered / Attended / Cancelled
  final DateTime registeredAt;
  final DateTime? attendanceMarkedAt;
  final bool feedbackSubmitted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParticipationModel({
    this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.registeredAt,
    this.attendanceMarkedAt,
    this.feedbackSubmitted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'status': status,
      'registeredAt': registeredAt,
      'attendanceMarkedAt': attendanceMarkedAt,
      'feedbackSubmitted': feedbackSubmitted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime(2000); 
  }

  factory ParticipationModel.fromMap(String documentId, Map<String, dynamic>? map) {
    if (map == null) {
      return ParticipationModel(
        id: documentId,
        eventId: '',
        eventTitle: 'Unknown Event',
        userId: '',
        userName: 'Unknown',
        userEmail: '',
        status: 'Error',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      return ParticipationModel(
        id: documentId,
        eventId: (map['eventId'] ?? '').toString(),
        eventTitle: (map['eventTitle'] ?? map['title'] ?? 'Untitled Event').toString(),
        userId: (map['userId'] ?? '').toString(),
        userName: (map['userName'] ?? map['fullname'] ?? map['fullName'] ?? 'User').toString(),
        userEmail: (map['userEmail'] ?? '').toString(),
        status: (map['status'] ?? 'Registered').toString(),
        registeredAt: _parseDate(map['registeredAt']),
        attendanceMarkedAt: map['attendanceMarkedAt'] != null ? _parseDate(map['attendanceMarkedAt']) : null,
        feedbackSubmitted: map['feedbackSubmitted'] == true,
        createdAt: _parseDate(map['createdAt'] ?? map['registeredAt']),
        updatedAt: _parseDate(map['updatedAt'] ?? map['registeredAt']),
      );
    } catch (e) {
      return ParticipationModel(
        id: documentId,
        eventId: '',
        eventTitle: 'Parsing Error',
        userId: '',
        userName: '',
        userEmail: '',
        status: 'Error',
        registeredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}
