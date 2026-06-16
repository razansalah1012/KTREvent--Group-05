import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final int totalQuantity;
  final int availableQuantity;
  final String condition;
  final String status;
  final String? imageUrl;
  final int borrowPeriod;
  final double deposit;
  final DateTime createdAt;
  final DateTime updatedAt;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.condition,
    required this.status,
    this.imageUrl,
    this.borrowPeriod = 3,
    this.deposit = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentModel.fromMap(String id, Map<String, dynamic> data) {
    return EquipmentModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      totalQuantity: data['totalQuantity'] ?? 0,
      availableQuantity: data['availableQuantity'] ?? 0,
      condition: data['condition'] ?? 'Good',
      status: data['status'] ?? 'available',
      imageUrl: data['imageUrl'],
      borrowPeriod: data['borrowPeriod'] ?? 3,
      deposit: (data['deposit'] ?? 0.0).toDouble(),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'condition': condition,
      'status': status,
      'imageUrl': imageUrl,
      'borrowPeriod': borrowPeriod,
      'deposit': deposit,
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
