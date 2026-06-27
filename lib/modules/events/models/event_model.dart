import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  String? id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;
  final String? organizerName;
  final int crewSlots;
  final DateTime? crewDeadline;
  final int acceptedCrewCount;
  final DateTime? createdAt;
  final String? imageUrl;
  final List<RegistrationField>? registrationFields;
  final double fee;
  final int capacity;
  final int registeredCount;
  final String? startTime;
  final String? endTime;
  final DateTime? registrationDeadline;
  final String? category;
  final List<String>? whatToExpect;
  final String? paperworkUrl;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
    this.organizerName,
    this.crewSlots = 0,
    this.crewDeadline,
    this.acceptedCrewCount = 0,
    this.createdAt,
    this.imageUrl,
    this.registrationFields,
    this.fee = 0.0,
    this.capacity = 100,
    this.registeredCount = 0,
    this.startTime,
    this.endTime,
    this.registrationDeadline,
    this.category,
    this.whatToExpect,
    this.paperworkUrl,
  });

  String getStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate.isAtSameMomentAs(today)) {
      return 'ONGOING';
    }

    if (eventDate.isBefore(today)) {
      return 'CLOSED';
    }

    if (registrationDeadline != null && registrationDeadline!.isBefore(now)) {
      return 'CLOSED';
    }

    if (registeredCount >= capacity) {
      return 'FULL';
    }

    if (capacity - registeredCount <= 5) {
      return 'CLOSING SOON';
    }

    return 'OPEN';
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'crewSlots': crewSlots,
      'crewDeadline': crewDeadline != null
          ? Timestamp.fromDate(crewDeadline!)
          : null,
      'acceptedCrewCount': acceptedCrewCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      'imageUrl': imageUrl,
      'registrationFields': registrationFields?.map((f) => f.toMap()).toList(),
      'fee': fee,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'startTime': startTime,
      'endTime': endTime,
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'category': category,
      'whatToExpect': whatToExpect,
      'paperworkUrl': paperworkUrl,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'crewSlots': crewSlots,
      'crewDeadline': crewDeadline != null
          ? Timestamp.fromDate(crewDeadline!)
          : null,
      'acceptedCrewCount': acceptedCrewCount,
      'updatedAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'registrationFields': registrationFields?.map((f) => f.toMap()).toList(),
      'fee': fee,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'startTime': startTime,
      'endTime': endTime,
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'category': category,
      'whatToExpect': whatToExpect,
      'paperworkUrl': paperworkUrl,
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
      organizerName: data['organizerName'] as String?,
      crewSlots: int.tryParse(data['crewSlots']?.toString() ?? '0') ?? 0,
      crewDeadline: data['crewDeadline'] != null
          ? _parseDate(data['crewDeadline'])
          : null,
      acceptedCrewCount:
          int.tryParse(data['acceptedCrewCount']?.toString() ?? '0') ?? 0,
      createdAt: data['createdAt'] != null
          ? _parseDate(data['createdAt'])
          : null,
      imageUrl: data['imageUrl'] as String?,
      registrationFields: (data['registrationFields'] as List<dynamic>?)
          ?.map((f) => RegistrationField.fromMap(f as Map<String, dynamic>))
          .toList(),
      fee: double.tryParse(data['fee']?.toString() ?? '0.0') ?? 0.0,
      capacity: int.tryParse(data['capacity']?.toString() ?? '100') ?? 100,
      registeredCount:
          int.tryParse(data['registeredCount']?.toString() ?? '0') ?? 0,
      startTime: data['startTime'] as String?,
      endTime: data['endTime'] as String?,
      registrationDeadline: data['registrationDeadline'] != null
          ? _parseDate(data['registrationDeadline'])
          : null,
      category: data['category'] as String?,
      whatToExpect: (data['whatToExpect'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      paperworkUrl: data['paperworkUrl'] as String?,
    );
  }
}

class RegistrationField {
  final String label;
  final String type;
  final bool isRequired;
  final List<String>? options;

  RegistrationField({
    required this.label,
    required this.type,
    this.isRequired = true,
    this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }

  factory RegistrationField.fromMap(Map<String, dynamic> map) {
    return RegistrationField(
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? true,
      options: (map['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
