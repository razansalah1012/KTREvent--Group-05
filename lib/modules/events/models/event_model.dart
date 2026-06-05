import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  String? id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;
  final int crewSlots;
  final DateTime? crewDeadline;
  final int acceptedCrewCount;
  final DateTime? createdAt;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
    this.crewSlots = 0,
    this.crewDeadline,
    this.acceptedCrewCount = 0,
    this.createdAt,
  });

  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'organizerId': organizerId,
      'crewSlots': crewSlots,
      'crewDeadline': crewDeadline != null ? Timestamp.fromDate(crewDeadline!) : null,
      'acceptedCrewCount': acceptedCrewCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'organizerId': organizerId,
      'crewSlots': crewSlots,
      'crewDeadline': crewDeadline != null ? Timestamp.fromDate(crewDeadline!) : null,
      'acceptedCrewCount': acceptedCrewCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EventModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      date: _parseDate(data['date']),
      location: (data['location'] ?? '').toString(),
      organizerId: (data['organizerId'] ?? '').toString(),
      crewSlots: int.tryParse(data['crewSlots']?.toString() ?? '0') ?? 0,
      crewDeadline: data['crewDeadline'] != null ? _parseDate(data['crewDeadline']) : null,
      acceptedCrewCount: int.tryParse(data['acceptedCrewCount']?.toString() ?? '0') ?? 0,
      createdAt: data['createdAt'] != null ? _parseDate(data['createdAt']) : null,
    );
  }
}
