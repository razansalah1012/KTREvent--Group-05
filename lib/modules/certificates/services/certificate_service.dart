import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/certificate_model.dart';
import '../../reports/services/pdf_generator_service.dart';

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'certificates';

  Future<void> generateAndIssueCertificatesForEvent({
    required String eventId,
    required String eventTitle,
    required String organizerId,
    bool includeOrganizers = true,
    Map<String, String>? studentCustomRoles,
  }) async {
    final existingCerts = await _firestore
        .collection(_collectionName)
        .where('eventId', isEqualTo: eventId)
        .get();
    if (existingCerts.docs.isNotEmpty) {
      throw Exception('Certificates already generated for this event.');
    }

    if (includeOrganizers) {
      final organizerDoc = await _firestore
          .collection('users')
          .doc(organizerId)
          .get();
      final organizerName = organizerDoc.data()?['name'] ?? 'Organizer';

      await _createCertificate(
        eventId: eventId,
        eventTitle: eventTitle,
        userId: organizerId,
        userName: organizerName,
        role: 'Project Director',
      );

      final crewSnapshot = await _firestore
          .collection('crew_applications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in crewSnapshot.docs) {
        final data = doc.data();
        final crewUserId = data['userId'];
        final crewUserName = data['userName'] ?? 'Crew Member';
        final crewRole = data['role'] ?? 'Committee Member';

        await _createCertificate(
          eventId: eventId,
          eventTitle: eventTitle,
          userId: crewUserId,
          userName: crewUserName,
          role: 'Crew: $crewRole',
        );
      }

      final communityMembersSnapshot = await _firestore
          .collection('community_members')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (var doc in communityMembersSnapshot.docs) {
        final data = doc.data();
        final commUserId = data['userId'];
        final commUserName = data['userName'] ?? 'Organizer';
        final commRole = data['role'] ?? 'Organizer';

        if (commUserId == organizerId) continue;

        await _createCertificate(
          eventId: eventId,
          eventTitle: eventTitle,
          userId: commUserId,
          userName: commUserName,
          role: commRole,
        );
      }
    }

    if (studentCustomRoles != null && studentCustomRoles.isNotEmpty) {
      final participantsSnapshot = await _firestore
          .collection('participations')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'Attended')
          .get();

      for (var doc in participantsSnapshot.docs) {
        final data = doc.data();
        final partUserId = data['userId'] as String;

        if (studentCustomRoles.containsKey(partUserId)) {
          final partUserName = data['userName'] ?? 'Participant';
          final customRole = studentCustomRoles[partUserId] ?? 'Participant';

          await _createCertificate(
            eventId: eventId,
            eventTitle: eventTitle,
            userId: partUserId,
            userName: partUserName,
            role: customRole,
          );
        }
      }
    }
  }

  Future<void> _createCertificate({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    required String role,
  }) async {
    final now = DateTime.now();

    final pdfBytes = await PdfGeneratorService.generateCertificate(
      userName: userName,
      eventTitle: eventTitle,
      role: role,
      date: now,
    );

    final fileName =
        'certificates/${eventId}_${userId}_${now.millisecondsSinceEpoch}.pdf';
    final ref = _storage.ref().child(fileName);
    await ref.putData(pdfBytes);
    final fileUrl = await ref.getDownloadURL();

    final newCert = CertificateModel(
      id: '',
      eventId: eventId,
      eventTitle: eventTitle,
      userId: userId,
      userName: userName,
      role: role,
      issuedAt: now,
      fileUrl: fileUrl,
    );

    await _firestore.collection(_collectionName).add(newCert.toMap());
  }

  Stream<List<CertificateModel>> getMyCertificates(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final certs = snapshot.docs
              .map((doc) => CertificateModel.fromMap(doc.id, doc.data()))
              .toList();
          certs.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
          return certs;
        });
  }
}
