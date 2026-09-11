class NilaiOpsiItem {
  final String value;
  final String label;

  const NilaiOpsiItem({
    required this.value,
    required this.label,
  });

  factory NilaiOpsiItem.fromJson(Map<String, dynamic> json) {
    return NilaiOpsiItem(
      value: json['value']?.toString() ??
          json['id']?.toString() ??
          json['kode']?.toString() ??
          '',
      label: json['label']?.toString() ??
          json['nama']?.toString() ??
          json['text']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NilaiOpsiItem &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => value.hashCode ^ label.hashCode;
}

class MatkulNilaiItem {
  final String kode;
  final String nama;
  final Map<String, dynamic> nilai;
  final String nilaiAkhir;
  final String nilaiHuruf;

  const MatkulNilaiItem({
    required this.kode,
    required this.nama,
    required this.nilai,
    required this.nilaiAkhir,
    required this.nilaiHuruf,
  });

  factory MatkulNilaiItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedNilai = {};
    if (json['nilai'] is Map) {
      parsedNilai = Map<String, dynamic>.from(json['nilai'] as Map);
    }

    return MatkulNilaiItem(
      kode: json['kode']?.toString() ??
          json['kdmk']?.toString() ??
          json['kode_matkul']?.toString() ??
          '',
      nama: json['nama']?.toString() ??
          json['nmmk']?.toString() ??
          json['nama_matkul']?.toString() ??
          '',
      nilai: parsedNilai,
      nilaiAkhir: json['nilai_akhir']?.toString() ??
          json['nilaiAkhir']?.toString() ??
          json['na']?.toString() ??
          '',
      nilaiHuruf: json['nilai_huruf']?.toString() ??
          json['nilaiHuruf']?.toString() ??
          json['nh']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'nama': nama,
        'nilai': nilai,
        'nilai_akhir': nilaiAkhir,
        'nilai_huruf': nilaiHuruf,
      };
}

class KelompokNilaiItem {
  final String jenis; // 'reguler' | 'mbkm'
  final List<String> kolom;
  final List<MatkulNilaiItem> matkul;

  const KelompokNilaiItem({
    required this.jenis,
    required this.kolom,
    required this.matkul,
  });

  factory KelompokNilaiItem.fromJson(Map<String, dynamic> json) {
    final rawKolom = json['kolom'];
    final List<String> parsedKolom = (rawKolom is List)
        ? rawKolom.map((e) => e.toString()).toList()
        : <String>[];

    final rawMatkul = json['matkul'] ?? json['data'];
    final List<MatkulNilaiItem> parsedMatkul = (rawMatkul is List)
        ? rawMatkul
            .map((e) => MatkulNilaiItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <MatkulNilaiItem>[];

    return KelompokNilaiItem(
      jenis: json['jenis']?.toString() ?? 'reguler',
      kolom: parsedKolom,
      matkul: parsedMatkul,
    );
  }

  Map<String, dynamic> toJson() => {
        'jenis': jenis,
        'kolom': kolom,
        'matkul': matkul.map((e) => e.toJson()).toList(),
      };
}

class RentangNilaiItem {
  final String rentang;
  final String huruf;
  final String bobot;

  const RentangNilaiItem({
    required this.rentang,
    required this.huruf,
    required this.bobot,
  });

  factory RentangNilaiItem.fromJson(Map<String, dynamic> json) {
    return RentangNilaiItem(
      rentang: json['rentang']?.toString() ?? '',
      huruf: json['huruf']?.toString() ??
          json['nilai_huruf']?.toString() ??
          json['nilaiHuruf']?.toString() ??
          '',
      bobot: json['bobot']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'rentang': rentang,
        'huruf': huruf,
        'bobot': bobot,
      };
}

class RincianNilaiResponse {
  final String thnAkademik;
  final String semesterId;
  final String semesterLabel;
  final String thnAktif;
  final List<KelompokNilaiItem> kelompok;
  final List<RentangNilaiItem> rentangNilai;

  const RincianNilaiResponse({
    required this.thnAkademik,
    required this.semesterId,
    required this.semesterLabel,
    required this.thnAktif,
    required this.kelompok,
    required this.rentangNilai,
  });

  factory RincianNilaiResponse.fromJson(Map<String, dynamic> json) {
    // Kelompok parsing supports:
    // 1. json['kelompok'] as List
    // 2. json['data'] as List
    // 3. json['data'] as Map with keys 'reguler', 'mbkm'
    List<KelompokNilaiItem> parsedKelompok = [];
    final rawKelompok = json['kelompok'] ?? json['data'];

    if (rawKelompok is List) {
      parsedKelompok = rawKelompok
          .map((e) => KelompokNilaiItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawKelompok is Map) {
      rawKelompok.forEach((key, value) {
        if (value is Map) {
          final mapVal = Map<String, dynamic>.from(value);
          mapVal.putIfAbsent('jenis', () => key.toString());
          parsedKelompok.add(KelompokNilaiItem.fromJson(mapVal));
        }
      });
    }

    // Rentang Nilai parsing
    final rawRentang = json['rentang_nilai'] ?? json['rentangNilai'];
    final List<RentangNilaiItem> parsedRentang = (rawRentang is List)
        ? rawRentang
            .map((e) => RentangNilaiItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <RentangNilaiItem>[];

    // Semester ID & Label parsing
    String semId = '';
    String semLabel = '';
    final rawSemester = json['semester'];
    if (rawSemester is Map) {
      semId = rawSemester['id']?.toString() ??
          rawSemester['value']?.toString() ??
          '';
      semLabel = rawSemester['label']?.toString() ??
          rawSemester['nama']?.toString() ??
          '';
    } else if (rawSemester != null) {
      semId = rawSemester.toString();
      semLabel = rawSemester.toString();
    }
    if (json['semester_id'] != null) {
      semId = json['semester_id'].toString();
    }
    if (json['semesterId'] != null) {
      semId = json['semesterId'].toString();
    }
    if (json['semester_label'] != null) {
      semLabel = json['semester_label'].toString();
    }
    if (json['semesterLabel'] != null) {
      semLabel = json['semesterLabel'].toString();
    }

    return RincianNilaiResponse(
      thnAkademik: json['thn_akademik']?.toString() ??
          json['thnAkademik']?.toString() ??
          '',
      semesterId: semId,
      semesterLabel: semLabel.isNotEmpty ? semLabel : semId,
      thnAktif: json['thn_aktif']?.toString() ??
          json['thnAktif']?.toString() ??
          '',
      kelompok: parsedKelompok,
      rentangNilai: parsedRentang,
    );
  }

  Map<String, dynamic> toJson() => {
        'thn_akademik': thnAkademik,
        'semester_id': semesterId,
        'semester_label': semesterLabel,
        'thn_aktif': thnAktif,
        'kelompok': kelompok.map((e) => e.toJson()).toList(),
        'rentang_nilai': rentangNilai.map((e) => e.toJson()).toList(),
      };
}
