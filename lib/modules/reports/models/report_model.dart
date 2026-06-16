import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String type;
  final String fileName;
  final String fileUrl;
  final String financialReportUrl;
  final String submittedBy;
  final String submittedByEmail;
  final DateTime submittedAt;
  final String status;
  final String? reviewerId;
  final String? reviewerComment;
  final DateTime expiresAt;

  ReportModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.financialReportUrl,
    required this.submittedBy,
    required this.submittedByEmail,
    required this.submittedAt,
    required this.status,
    this.reviewerId,
    this.reviewerComment,
    required this.expiresAt,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['submittedAt'] as Timestamp?;
    final Timestamp? expTs = data['expiresAt'] as Timestamp?;
    return ReportModel(
      id: id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      type: data['type'] ?? '',
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      financialReportUrl: data['financialReportUrl'] ?? '',
      submittedBy: data['submittedBy'] ?? '',
      submittedByEmail: data['submittedByEmail'] ?? '',
      submittedAt: ts != null ? ts.toDate() : DateTime.now(),
      status: data['status'] ?? 'submitted',
      reviewerId: data['reviewerId'],
      reviewerComment: data['reviewerComment'],
      expiresAt: expTs != null ? expTs.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'type': type,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'financialReportUrl': financialReportUrl,
      'submittedBy': submittedBy,
      'submittedByEmail': submittedByEmail,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'reviewerId': reviewerId,
      'reviewerComment': reviewerComment,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
