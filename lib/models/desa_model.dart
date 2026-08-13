class DesaModel {
  final int id;
  final String kodeDesa;
  final String namaDesa;
  final String namaKecamatan;
  final String namaKabupaten;
  final String? namaProvinsi;
  final String? namaKades;
  final String? nipKades;
  final String? subdomain;
  final String? logoPath;

  DesaModel({
    required this.id,
    required this.kodeDesa,
    required this.namaDesa,
    required this.namaKecamatan,
    required this.namaKabupaten,
    this.namaProvinsi,
    this.namaKades,
    this.nipKades,
    this.subdomain,
    this.logoPath,
  });

  factory DesaModel.fromJson(Map<String, dynamic> json) {
    return DesaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      kodeDesa: json['kode_desa'] ?? '',
      namaDesa: json['nama_desa'] ?? 'Desa',
      namaKecamatan: json['nama_kecamatan'] ?? 'Kecamatan',
      namaKabupaten: json['nama_kabupaten'] ?? 'Kabupaten',
      namaProvinsi: json['nama_provinsi'] ?? 'Jawa Barat',
      namaKades: json['nama_kades'],
      nipKades: json['nip_kades'],
      subdomain: json['subdomain'],
      logoPath: json['logo_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_desa': kodeDesa,
      'nama_desa': namaDesa,
      'nama_kecamatan': namaKecamatan,
      'nama_kabupaten': namaKabupaten,
      'nama_provinsi': namaProvinsi,
      'nama_kades': namaKades,
      'nip_kades': nipKades,
      'subdomain': subdomain,
      'logo_path': logoPath,
    };
  }
}
