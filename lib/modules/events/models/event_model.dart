class EventModel {
  String? id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'organizerId': organizerId,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}