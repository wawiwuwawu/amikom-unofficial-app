class AgendaItem {
  final String tipe; // 'kuliah', 'asisten', 'uts', 'uas'
  final String hari;
  final String jam;
  final String jamMulai;
  final String jamSelesai;
  final String ruang;
  final String matakuliah;
  final String detail;

  /// Komponen perkuliahan dari portal — hanya berarti untuk `tipe == 'kuliah'`:
  /// `'teori'` atau `'praktek'`. `null` pada respons lama yang tidak mengirim
  /// field ini; tampilan lalu jatuh ke perilaku warisan.
  final String? komponen;

  AgendaItem({
    required this.tipe,
    required this.hari,
    required this.jam,
    this.jamMulai = '',
    this.jamSelesai = '',
    required this.ruang,
    required this.matakuliah,
    required this.detail,
    this.komponen,
  });

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      tipe: json['tipe']?.toString() ?? 'kuliah',
      hari: json['hari']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      jamMulai: json['jam_mulai']?.toString() ?? '',
      jamSelesai: json['jam_selesai']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      matakuliah: json['matakuliah']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      komponen: json['komponen']?.toString(),
    );
  }
}

class AgendaTerpaduData {
  final int totalAgenda;
  final Map<String, List<AgendaItem>> agenda;

  AgendaTerpaduData({
    required this.totalAgenda,
    required this.agenda,
  });

  factory AgendaTerpaduData.fromJson(Map<String, dynamic> json) {
    final rawAgenda = json['agenda'];
    final Map<String, List<AgendaItem>> parsedMap = {};

    if (rawAgenda is Map<String, dynamic>) {
      rawAgenda.forEach((day, list) {
        if (list is List) {
          parsedMap[day] = list.map((e) => AgendaItem.fromJson(e)).toList();
        }
      });
    }

    return AgendaTerpaduData(
      totalAgenda: int.tryParse(json['total_agenda']?.toString() ?? '0') ?? 0,
      agenda: parsedMap,
    );
  }
}
