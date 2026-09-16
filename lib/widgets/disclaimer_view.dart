import 'package:url_launcher/url_launcher.dart';

/// Buka wiki Disclaimer di browser eksternal.
///
/// Isi penafian ditampilkan langsung oleh halaman Penafian dan oleh gerbang
/// persetujuan di halaman login, jadi tidak ada widget tersendiri di sini.
Future<void> openFullDisclaimer() async {
  final uri = Uri.parse(
    'https://github.com/wawiwuwawu/amikom-unofficial-app/wiki/Disclaimer',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
