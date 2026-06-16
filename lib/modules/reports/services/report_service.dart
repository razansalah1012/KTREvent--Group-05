import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  Future<void> submitReport(ReportModel report) async {
    await _firestore.collection(_collection).add({
      ...report.toMap(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      ),
    });
  }

  Stream<List<ReportModel>> getReportsForEvent(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ReportModel>> getReportsSubmittedBy(String userId) {
    return _firestore
        .collection(_collection)
        .where('submittedBy', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String? reviewerId,
    String? reviewerComment,
  }) async {
    await _firestore.collection(_collection).doc(reportId).update({
      'status': status,
      'reviewerId': reviewerId,
      'reviewerComment': reviewerComment,
    });
  }
}
