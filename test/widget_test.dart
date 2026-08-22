// Smoke test: memastikan aplikasi bisa boot sampai splash screen.
// Dijalankan otomatis di CI (GitHub Actions) via `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_amikom/main.dart';

void main() {
  setUpAll(() {
    // Jangan fetch font dari internet saat test — fokus: verifikasi boot UI.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Splash screen menampilkan brand + status unofficial.
    expect(find.text('Ini Amikom?'), findsOneWidget);
    expect(find.text('Unofficial App'), findsOneWidget);

    // Tunggu animasi splash selesai agar tidak ada ticker/timer tersisa.
    await tester.pump(const Duration(seconds: 1));
  });
}