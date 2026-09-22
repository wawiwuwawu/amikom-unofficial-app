/// Kegagalan yang AMAN ditampilkan ke pengguna.
///
/// Kontrak:
///  * [message] selalu pesan Bahasa Indonesia yang ramah — tidak pernah berisi
///    nama exception, tipe data, stack trace, status code mentah, atau teks
///    teknis dari library/server.
///  * Detail teknis asli tidak pernah ikut disimpan — yang bertahan hanya pesan
///    ramah (lihat [_looksTechnical] dan `ApiClient.handleError`).
///  * [toString] mengembalikan [message], sehingga pemakaian lama seperti
///    `e.toString().replaceFirst('Exception: ', '')` tetap menampilkan pesan
///    ramah (dan tidak pernah membocorkan detail teknis).
///
/// Seluruh error yang dilempar service WAJIB berbentuk [AppFailure] — lihat
/// `ApiClient.handleError`. Di UI gunakan `userErrorMessage(e, fallback)` dari
/// `widgets/app_kit.dart`.
class AppFailure implements Exception {
  /// Pesan siap tampil (Bahasa Indonesia, ramah pengguna).
  final String message;

  const AppFailure(this.message);

  /// Bungkus pesan yang berasal dari server. Pesan server dipakai apa adanya
  /// selama terlihat seperti kalimat untuk manusia; kalau mengandung jejak
  /// teknis (stack, nama exception, kode SQL, URL internal, dsb.) pesan
  /// diganti [fallback] agar tidak membocorkan detail internal.
  factory AppFailure.fromServer(
    dynamic rawMessage, {
    String fallback = 'Terjadi kesalahan',
  }) {
    final text = rawMessage?.toString().trim() ?? '';
    if (text.isEmpty || _looksTechnical(text)) {
      return AppFailure(fallback);
    }
    return AppFailure(text);
  }

  /// Cek cepat apakah sebuah teks mengandung jejak teknis.
  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    const markers = <String>[
      'stack',
      'traceback',
      'exception',
      'typeerror',
      'cannot read',
      'undefined is not',
      'is not a subtype',
      'null check operator',
      'nosuchmethod',
      'econnrefused',
      'etimedout',
      'enotfound',
      'socketexception',
      'sqlstate',
      'sequelize',
      'node_modules',
      'at object.',
      '<!doctype',
      '<html',
      'internal server error',
      'syntaxerror',
      'formatexception',
      'platformexception',
      'status code',
    ];
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  /// Pesan ramah-pengguna dari error apa pun. Error non-[AppFailure] tidak
  /// pernah ditampilkan mentah — dikembalikan [fallback].
  static String messageOf(Object? error, [String fallback = 'Terjadi kesalahan']) =>
      error is AppFailure ? error.message : fallback;

  @override
  String toString() => message;
}
