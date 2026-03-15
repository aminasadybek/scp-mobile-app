import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String password;
  @HiveField(4)
  final String phone;
  @HiveField(5)
  final String role;
  @HiveField(6)
  final int companyId;
  @HiveField(7)
  final DateTime? createdAt;
  @HiveField(8)
  final DateTime? updatedAt;
  @HiveField(9)
  final String? inviteCode; // for sales rep

  static const String ROLE_CONSUMER = 'consumer';
  static const String ROLE_SALES_REP = 'sales_rep';
  static const String ROLE_MANAGER = 'manager';
  static const String ROLE_OWNER = 'owner';

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    required this.companyId,
    this.createdAt,
    this.updatedAt,
    this.inviteCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'],
      companyId: json['company_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      inviteCode: json['invite_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'invite_code': inviteCode,
    };
  }
}