import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentRequestModel {
  final String id;
  final String equipmentName;
  final int quantity;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String eventName;
  final String? eventId;
  final String reason;
  final DateTime borrowedDate;
  final DateTime returnDate;
  final String status;
  final String? adminComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get neededDate => borrowedDate;

  EquipmentRequestModel({
    required this.id,
    required this.equipmentName,
    required this.quantity,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.eventName,
    this.eventId,
    required this.reason,
    required this.borrowedDate,
    required this.returnDate,
    required this.status,
    this.adminComment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return EquipmentRequestModel(
      id: id,
      equipmentName: data['equipmentName'] ?? '',
      quantity: data['quantity'] ?? 1,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterEmail: data['requesterEmail'] ?? '',
      eventName: data['eventName'] ?? '',
      eventId: data['eventId'],
      reason: data['reason'] ?? '',
      borrowedDate: _parseDate(data['borrowedDate'] ?? data['neededDate']),
      returnDate: _parseDate(data['returnDate']),
      status: data['status'] ?? 'pending',
      adminComment: data['adminComment'],
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentName': equipmentName,
      'quantity': quantity,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'eventName': eventName,
      'eventId': eventId,
      'reason': reason,
      'borrowedDate': Timestamp.fromDate(borrowedDate),
      'returnDate': Timestamp.fromDate(returnDate),
      'status': status,
      if (adminComment != null) 'adminComment': adminComment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
