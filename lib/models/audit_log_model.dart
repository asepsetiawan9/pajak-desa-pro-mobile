class AuditLogModel {
  final int id;
  final int? userId;
  final String action;
  final String module;
  final Map<String, dynamic>? payload;
  final String? ipAddress;
  final String createdAt;
  final String userNama;
  final String userRole;
  final String desaNama;

  AuditLogModel({
    required this.id,
    this.userId,
    required this.action,
    required this.module,
    this.payload,
    this.ipAddress,
    required this.createdAt,
    required this.userNama,
    required this.userRole,
    required this.desaNama,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    String nama = 'Sistem / Anonim';
    String role = '-';
    String desa = 'Desa';

    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      final userObj = json['user'] as Map<String, dynamic>;
      nama = userObj['name'] ?? userObj['username'] ?? 'Pengguna';
      role = userObj['role'] ?? '-';
      if (userObj['desa'] != null && userObj['desa'] is Map<String, dynamic>) {
        desa = userObj['desa']['nama_desa'] ?? 'Desa';
      }
    }

    Map<String, dynamic>? payloadMap;
    if (json['payload'] != null) {
      if (json['payload'] is Map<String, dynamic>) {
        payloadMap = json['payload'] as Map<String, dynamic>;
      } else if (json['payload'] is String) {
        payloadMap = {'detail': json['payload']};
      }
    }

    return AuditLogModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString())) : null,
      action: json['action'] ?? 'ACTION',
      module: json['module'] ?? 'MODULE',
      payload: payloadMap,
      ipAddress: json['ip_address'],
      createdAt: json['created_at'] ?? '',
      userNama: nama,
      userRole: role,
      desaNama: desa,
    );
  }
}
