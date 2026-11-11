package com.wawu.amiapp

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Auto-login WiFi kampus: channel + NetworkCallback dipasang sekali
        // di sini (idempoten). Kredensial dikirim per attempt dari Dart.
        WifiKampusLoginManager.attach(flutterEngine, this)
        // Pemicu onWifiUp baru efektif setelah izin baca SSID granted —
        // minta sekali di sini; granted → Dart retry attempt lewat callback.
        WifiKampusLoginManager.get(applicationContext).mintaIzinSsid()
        // Unduhan PDF → Download publik via MediaStore (Android 10+, tanpa izin).
        DownloadStorageManager.attach(flutterEngine, applicationContext)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == WifiKampusLoginManager.KODE_IZIN_SSID) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            WifiKampusLoginManager.get(applicationContext).onIzinResult(granted)
        }
    }

    override fun onDestroy() {
        // Lepas referensi activity dari manager agar tidak bocor.
        WifiKampusLoginManager.get(applicationContext).lepasActivity()
        super.onDestroy()
    }
}
