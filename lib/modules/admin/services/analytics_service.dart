import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Event Statistics
  Stream<Map<String, dynamic>> getEventStats() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      int totalEvents = snapshot.docs.length;
      int upcomingEvents = 0;
      int pastEvents = 0;

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] != null) {
          final eventDate = (data['date'] as Timestamp).toDate();
          if (eventDate.isAfter(now)) {
            upcomingEvents++;
          } else {
            pastEvents++;
          }
        }
      }

      return {
        'total': totalEvents,
        'upcoming': upcomingEvents,
        'past': pastEvents,
      };
    });
  }

  // Equipment Requests Statistics
  Stream<Map<String, dynamic>> getEquipmentStats() {
    return _firestore.collection('equipment_requests').snapshots().map((snapshot) {
      int totalRequests = snapshot.docs.length;
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status == 'pending') {
          pendingRequests++;
        } else if (status == 'approved') {
          approvedRequests++;
        } else if (status == 'rejected') {
          rejectedRequests++;
        }
      }

      return {
        'total': totalRequests,
        'pending': pendingRequests,
        'approved': approvedRequests,
        'rejected': rejectedRequests,
      };
    });
  }

  // User Engagement Statistics
  Stream<Map<String, dynamic>> getUserStats() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      int totalUsers = snapshot.docs.length;
      int students = 0;
      int clubMembers = 0;
      int admins = 0;

      for (var doc in snapshot.docs) {
        final role = doc.data()['role'] ?? 'student';
        if (role == 'student') {
          students++;
        } else if (role == 'club_member') {
          clubMembers++;
        } else if (role == 'admin') {
          admins++;
        }
      }

      return {
        'total': totalUsers,
        'students': students,
        'clubMembers': clubMembers,
        'admins': admins,
      };
    });
  }

  // Proposal Statistics
  Stream<Map<String, dynamic>> getProposalStats() {
    return _firestore.collection('proposals').snapshots().map((snapshot) {
      int totalProposals = snapshot.docs.length;
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        if (status == 'pending') {
          pending++;
        } else if (status == 'approved') {
          approved++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }

      return {
        'total': totalProposals,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    });
  }
}
