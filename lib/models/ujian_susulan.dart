class UjianSusulanBadge {
  final String key;
  final String value;

  UjianSusulanBadge({
    required this.key,
    required this.value,
  });

  factory UjianSusulanBadge.fromJson(Map<String, dynamic> json) {
    return UjianSusulanBadge(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class UjianSusulanItem {
  final String kode;
  final String mkl;
  final int sks;
  final String kelas;
  final String dosen;
  final String status;

  UjianSusulanItem({
    required this.kode,
    required this.mkl,
    required this.sks,
    required this.kelas,
    required this.dosen,
    required this.status,
  });

  factory UjianSusulanItem.fromJson(Map<String, dynamic> json) {
    return UjianSusulanItem(
      kode: json['kode']?.toString() ?? '',
      mkl: json['mkl']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '0') ?? 0,
      kelas: json['kelas']?.toString() ?? '',
      dosen: json['dosen']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class UjianSusulanData {
  final String jenis;
  final bool isAvailable;
  final String message;
  final List<UjianSusulanBadge> badges;
  final List<UjianSusulanItem> items;

  UjianSusulanData({
    required this.jenis,
    required this.isAvailable,
    required this.message,
    required this.badges,
    required this.items,
  });

  factory UjianSusulanData.fromJson(Map<String, dynamic> json) {
    return UjianSusulanData(
      jenis: json['jenis']?.toString() ?? '',
      isAvailable: json['is_available'] == true,
      message: json['message']?.toString() ?? '',
      badges: (json['badges'] as List?)
              ?.map((e) => UjianSusulanBadge.fromJson(e))
              .toList() ??
          [],
      items: (json['items'] as List?)
              ?.map((e) => UjianSusulanItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
