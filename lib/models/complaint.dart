import 'package:hive/hive.dart';

part 'complaint.g.dart';

@HiveType(typeId: 1)
class Complaint extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final int orderId;
  @HiveField(2)
  final int consumerId;
  @HiveField(3)
  final int supplierId;
  @HiveField(4)
  final String description;
  @HiveField(5)
  final String status;
  @HiveField(6)
  final String? resolution;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime? resolvedAt;
  @HiveField(9)
  final String? assignedTo;
  @HiveField(10)
  final String? priority;

  Complaint({
    required this.id,
    required this.orderId,
    required this.consumerId,
    required this.supplierId,
    required this.description,
    required this.status,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
    this.assignedTo,
    this.priority,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      orderId: json['order_id'],
      consumerId: json['consumer_id'],
      supplierId: json['supplier_id'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      resolution: json['resolution'],
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      assignedTo: json['assigned_to'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'consumer_id': consumerId,
      'supplier_id': supplierId,
      'description': description,
      'status': status,
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'assigned_to': assignedTo,
      'priority': priority,
    };
  }
}
