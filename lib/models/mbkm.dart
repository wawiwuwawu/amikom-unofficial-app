class MbkmFakultas {
  final String id;
  final String npm;
  final String nama;
  final String prodi;
  final String program;
  final String mitra;
  final String thnAkademik;
  final String semester;
  final String dosbing;
  final String status;
  final String komitmen;
  final String fileLolos;

  MbkmFakultas({
    required this.id,
    required this.npm,
    required this.nama,
    required this.prodi,
    required this.program,
    required this.mitra,
    required this.thnAkademik,
    required this.semester,
    required this.dosbing,
    required this.status,
    required this.komitmen,
    required this.fileLolos,
  });

  factory MbkmFakultas.fromJson(Map<String, dynamic> json) => MbkmFakultas(
        id: json['ID']?.toString() ?? '',
        npm: json['NPM'] ?? '',
        nama: json['NAMA'] ?? '',
        prodi: json['PRODI'] ?? '',
        program: json['PROGRAM'] ?? '',
        mitra: json['MITRA'] ?? '',
        thnAkademik: json['THN_AKADEMIK'] ?? '',
        semester: json['SEMESTER']?.toString() ?? '',
        dosbing: json['DOSBING'] ?? '',
        status: json['STATUS']?.toString() ?? '',
        komitmen: json['KOMITMEN']?.toString() ?? '',
        fileLolos: json['FILE_LOLOS'] ?? '',
      );
}

class MbkmBimbingan {
  final String no;
  final String tanggal;
  final String bimbingan;
  final String status;
  final String aksi; // Usually contains HTML/Delete endpoint in web, but we'll parse it if needed

  MbkmBimbingan({
    required this.no,
    required this.tanggal,
    required this.bimbingan,
    required this.status,
    required this.aksi,
  });

  factory MbkmBimbingan.fromJson(Map<String, dynamic> json) => MbkmBimbingan(
        no: json['No']?.toString() ?? '',
        tanggal: json['Tanggal'] ?? '',
        bimbingan: json['Bimbingan'] ?? '',
        status: json['Status'] ?? '',
        aksi: json['Aksi'] ?? '',
      );
}
