import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String role;
  final DateTime issuedAt;
  final String fileUrl;

  CertificateModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.role,
    required this.issuedAt,
    required this.fileUrl,
  });

  factory CertificateModel.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['issuedAt'] as Timestamp?;
    return CertificateModel(
      id: id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      role: data['role'] ?? '',
      issuedAt: ts != null ? ts.toDate() : DateTime.now(),
      fileUrl: data['fileUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'role': role,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'fileUrl': fileUrl,
    };
  }
}
