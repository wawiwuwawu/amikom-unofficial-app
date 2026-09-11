class Agenda {
  final String title;
  final String mulai;
  final String selesai;

  Agenda({
    required this.title,
    required this.mulai,
    required this.selesai,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      title: json['title'] ?? json['TITLE'] ?? '',
      mulai: json['mulai'] ?? json['MULAI'] ?? '',
      selesai: json['selesai'] ?? json['SELESAI'] ?? '',
    );
  }
}
