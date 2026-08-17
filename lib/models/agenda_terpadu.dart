class AgendaItem {
  final String tipe; // 'kuliah', 'asisten', 'uts', 'uas'
  final String hari;
  final String jam;
  final String ruang;
  final String matakuliah;
  final String detail;

  AgendaItem({
    required this.tipe,
    required this.hari,
    required this.jam,
    required this.ruang,
    required this.matakuliah,
    required this.detail,
  });

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      tipe: json['tipe']?.toString() ?? 'kuliah',
      hari: json['hari']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      matakuliah: json['matakuliah']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
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
