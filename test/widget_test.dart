// Smoke test: memastikan aplikasi bisa boot sampai splash screen.
// Dijalankan otomatis di CI (GitHub Actions) via `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_amikom/main.dart';

void main() {
  setUpAll(() {
    // Splash kini mengecek toggle auto-login WiFi (prefs) sebelum health
    // check — tanpa mock, SharedPreferences.getInstance() menggantung di
    // test environment (timer 12s splash tersisa → assertion gagal).
    // Default OFF → splash tidak menyentuh portal sama sekali.
    SharedPreferences.setMockInitialValues({});
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
