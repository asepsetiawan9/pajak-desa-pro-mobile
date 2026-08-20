import 'desa_model.dart';

class UserModel {
  final int id;
  final int? desaId;
  final String name;
  final String username;
  final String? email;
  final String role; // 'superadmin', 'bendahara', 'kolektor', 'kepaladesa'
  final dynamic dusunAkses;
  final bool statusAktif;
  final DesaModel? desa;

  UserModel({
    required this.id,
    this.desaId,
    required this.name,
    required this.username,
    this.email,
    required this.role,
    this.dusunAkses,
    required this.statusAktif,
    this.desa,
  });

  bool get isKolektor => role.toLowerCase().replaceAll('_', '') == 'kolektor';
  bool get isKepalaDesa => role.toLowerCase().replaceAll('_', '') == 'kepaladesa';
  bool get isSuperAdminSystem => role.toLowerCase().replaceAll('_', '') == 'superadminsystem';
  bool get isSuperAdmin => role.toLowerCase().replaceAll('_', '') == 'superadmin';
  bool get isBendahara => role.toLowerCase().replaceAll('_', '') == 'bendahara';

  /// Roles allowed to access Mobile app
  bool get isMobileAllowed => isKolektor || isKepalaDesa || isSuperAdminSystem;

  List<String> get allowedDusuns {
    if (dusunAkses == null) return [];
    if (dusunAkses is List) {
      return (dusunAkses as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (dusunAkses is String) {
      final str = (dusunAkses as String).trim();
      final lower = str.toLowerCase();
      if (str.isEmpty || lower == 'all' || lower == 'semua' || str == '*') return [];
      return str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      desaId: json['desa_id'] != null ? (json['desa_id'] is int ? json['desa_id'] : int.tryParse(json['desa_id'].toString())) : null,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      dusunAkses: json['dusun_akses'],
      statusAktif: json['status_aktif'] == true || json['status_aktif'] == 1 || json['status_aktif'] == '1',
      desa: json['desa'] != null && json['desa'] is Map<String, dynamic> ? DesaModel.fromJson(json['desa']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'desa_id': desaId,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'dusun_akses': dusunAkses,
      'status_aktif': statusAktif,
      'desa': desa?.toJson(),
    };
  }
}
