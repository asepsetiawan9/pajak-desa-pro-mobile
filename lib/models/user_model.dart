class UserModel {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String role; // 'superadmin', 'bendahara', 'kolektor', 'kepaladesa'
  final dynamic dusunAkses;
  final bool statusAktif;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    required this.role,
    this.dusunAkses,
    required this.statusAktif,
  });

  bool get isKolektor => role.toLowerCase().replaceAll('_', '') == 'kolektor';
  bool get isKepalaDesa => role.toLowerCase().replaceAll('_', '') == 'kepaladesa';

  /// Roles allowed to access Mobile app
  bool get isMobileAllowed => isKolektor || isKepalaDesa;

  List<String> get allowedDusuns {
    if (dusunAkses == null) return [];
    if (dusunAkses is List) {
      return (dusunAkses as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (dusunAkses is String) {
      final str = (dusunAkses as String).trim();
      if (str.isEmpty || str == 'all' || str == '*') return [];
      return str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      dusunAkses: json['dusun_akses'],
      statusAktif: json['status_aktif'] == true || json['status_aktif'] == 1 || json['status_aktif'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'dusun_akses': dusunAkses,
      'status_aktif': statusAktif,
    };
  }
}
