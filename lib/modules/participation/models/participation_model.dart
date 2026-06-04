class ParticipationModel {
  String? id;
  final String eventId;
  final String userId;
  final String userName; 
  final String userEmail;
  final DateTime registeredAt;
  String? feedback;
  double? rating;

  ParticipationModel({
    this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.registeredAt,
    this.feedback,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'registeredAt': registeredAt.toIso8601String(),
      'feedback': feedback,
      'rating': rating,
    };
  }

  factory ParticipationModel.fromMap(String documentId, Map<String, dynamic> map) {
    return ParticipationModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      userEmail: map['userEmail'] ?? '',
      registeredAt: DateTime.parse(map['registeredAt']),
      feedback: map['feedback'],
      rating: map['rating']?.toDouble(),
    );
  }
}