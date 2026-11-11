package com.wawu.amiapp

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Login otomatis ke captive portal Hotspot@Amikom (MikroTik).
 *
 * Port dari referensi auto-login-app/ (AmikomHotspotLoginManager.kt) dengan
 * penyesuaian untuk dijalankan di bawah [MainActivity]:
 *
 *  - Hanya berjalan bila SSID perangkat PERSIS "Hotspot@Amikom" (case-sensitive).
 *    Pengecualian fail-open: bila SSID TIDAK TERBACA ("<unknown ssid>" — izin
 *    lokasi/nearby belum diberikan, Android 10+), login tetap dicoba — portal
 *    172.20.8.1 hanya terjangkau di jaringan kampus, jadi POST ke portal
 *    menjadi gerbang sebenarnya. Respons galat-koneksi/asing pada SSID yang
 *    tak terbaca dilaporkan sebagai "bukanWifiKampus" agar tidak dihitung
 *    kegagalan backoff di Dart (mis. WiFi rumah).
 *  - Izin baca SSID (NEARBY_WIFI_DEVICES API 33+ / ACCESS_FINE_LOCATION di
 *    bawahnya) diminta runtime sekali saat attach; granted → pemicu
 *    NetworkCallback + gerbang SSID bekerja penuh.
 *  - Semua request dipaksa lewat antarmuka WiFi via bindProcessToNetwork —
 *    tanpa ini HP berkuota seluler bisa merutekan request ke jaringan seluler
 *    sehingga portal 172.20.8.1 (IP privat) tidak terjangkau.
 *  - Portal di-hardcode ke http://172.20.8.1/login; kredensial tidak pernah
 *    dikirim ke host lain dan tidak pernah dicatat/log.
 *  - Kredensial dikirim dari Dart per attempt (setCredentials) dan hanya
 *    disimpan di memori native — tidak ada persistensi di sisi Kotlin.
 *
 * Dipanggil dari Dart (WifiKampusService) lewat MethodChannel
 * "amikom/wifi_kampus" yang terpasang di [MainActivity.configureFlutterEngine].
 */
class WifiKampusLoginManager private constructor(private val appContext: Context) {

    companion object {
        const val CHANNEL = "amikom/wifi_kampus"

        /** Tag logcat untuk diagnosis perangkat (tanpa kredensial). */
        const val TAG = "WifiKampus"

        /** Request code izin runtime baca SSID. */
        const val KODE_IZIN_SSID = 47011

        @Volatile
        private var instance: WifiKampusLoginManager? = null

        /** Dipanggil dari MainActivity sekali saat engine siap. */
        fun attach(engine: FlutterEngine, activity: Activity) {
            val manager = get(activity)
            val channel = MethodChannel(
                engine.dartExecutor.binaryMessenger,
                CHANNEL,
            )
            channel.setMethodCallHandler { call, result ->
                manager.handle(call.method, call.arguments, result)
            }
            // Pemicu dari native ke Dart saat WiFi kampus baru tersambung —
            // Dart yang menjalankan attempt login (kredensial ada di sana).
            manager.onWifiKampusUp = {
                runCatching { channel.invokeMethod("onWifiUp", null) }
            }
            manager.onIzinSsidGranted = {
                runCatching { channel.invokeMethod("onIzinSsidGranted", null) }
            }
            manager.pasangActivity(activity)
            manager.mulaiPantauWifi()
        }

        /** Izin runtime baca SSID sesuai API level (dipakai MainActivity). */
        fun izinSsidDibutuhkan(): Array<String> {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                arrayOf(Manifest.permission.NEARBY_WIFI_DEVICES)
            } else {
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
            }
        }

        fun get(context: Context): WifiKampusLoginManager {
            return instance ?: synchronized(this) {
                instance ?: WifiKampusLoginManager(context.applicationContext)
                    .also { instance = it }
            }
        }
    }

    // Konstanta portal — JANGAN mengganti portalUrl ke host lain (lihat
    // shared/login-flow.md di referensi auto-login-app/).
    private val ssid = "Hotspot@Amikom"
    private val portalUrl = "http://172.20.8.1/login"
    private val allowedPortalHost = "172.20.8.1"
    private val redirectUrl = "http://amikompurwokerto.ac.id"
    private val connectivityCheckUrl = "http://connectivitycheck.gstatic.com/generate_204"

    // Kredensial sesi (dari Dart) — memori saja, tidak pernah dipersist.
    // username portal = NIM mahasiswa (dari BE /wifi/kredensial), password =
    // tanggal lahir yyyymmdd dari BE — FE tidak mende derive sendiri.
    @Volatile
    private var usernamePortal: String? = null

    @Volatile
    private var password: String? = null

    /** Pemicu ke Dart saat WiFi kampus baru tersambung (dipasang di attach). */
    @Volatile
    var onWifiKampusUp: (() -> Unit)? = null

    /** Pemicu ke Dart setelah izin SSID baru saja diberikan (retry attempt). */
    @Volatile
    var onIzinSsidGranted: (() -> Unit)? = null

    private var callbackTerpasang = false

    /** Activity host untuk dialog izin runtime (null = tidak bisa minta). */
    @Volatile
    private var hostActivity: Activity? = null

    /** Dipasang dari attach; diputus di onDetach agar tak bocor. */
    fun pasangActivity(activity: Activity) {
        hostActivity = activity
    }

    fun lepasActivity() {
        hostActivity = null
    }

    /**
     * Pasang NetworkCallback yang memicu [onWifiKampusUp] tiap WiFi kampus
     * tersambung (availabilitas transport WiFi). Idempoten — boleh dipanggil
     * berulang; callback terpasang sekali per proses.
     */
    private fun mulaiPantauWifi() {
        if (callbackTerpasang) return
        val cm = appContext.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .build()
        callbackTerpasang = try {
            cm.registerNetworkCallback(
                request,
                object : ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: Network) {
                        // SSID menentukan ini WiFi kampus, bukan WiFi lain.
                        val caps = cm.getNetworkCapabilities(network)
                        val currentSsid = ssidDari(caps)
                        Log.d(TAG, "callback onAvailable ssid=${currentSsid ?: "<tidak terbaca>"}")
                        if (currentSsid == ssid) {
                            onWifiKampusUp?.invoke()
                        }
                    }
                },
            )
            true
        } catch (e: Exception) {
            // Gagal memasang callback bukan fatal — Dart tetap bisa trigger
            // manual saat app open/resume. Tidak ada kredensial di log.
            false
        }
    }

    private fun handle(method: String, arguments: Any?, result: MethodChannel.Result) {
        when (method) {
            "setCredentials" -> {
                val args = arguments as? Map<*, *>
                usernamePortal = (args?.get("username") as? String) ?: (args?.get("nim") as? String)
                password = args?.get("password") as? String
                result.success(null)
            }
            "clearCredentials" -> {
                usernamePortal = null
                password = null
                result.success(null)
            }
            "loginIfConnected" -> {
                val args = arguments as? Map<*, *>
                val user = (args?.get("username") as? String) ?: usernamePortal
                val pass = (args?.get("password") as? String) ?: password
                if (user.isNullOrBlank() || pass.isNullOrBlank()) {
                    result.success(mapOf("status" to "tanpaKredensial"))
                    return
                }
                loginAsync(user, pass, result)
            }
            "statusJaringan" -> result.success(statusJaringan())
            "izinSsidStatus" -> result.success(izinSsidGranted())
            "mintaIzinSsid" -> {
                val activity = hostActivity
                if (activity == null) {
                    result.success(false)
                } else {
                    ActivityCompat.requestPermissions(
                        activity,
                        WifiKampusLoginManager.izinSsidDibutuhkan(),
                        KODE_IZIN_SSID,
                    )
                    // Hasil sebenarnya lewat MainActivity.onRequestPermissionsResult.
                    result.success(true)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** true bila izin baca SSID sesuai API level sudah granted. */
    fun izinSsidGranted(): Boolean {
        val izin = WifiKampusLoginManager.izinSsidDibutuhkan()[0]
        return ActivityCompat.checkSelfPermission(appContext, izin) ==
            PackageManager.PERMISSION_GRANTED
    }

    /** Dipanggil MainActivity setelah dialog izin ditutup. */
    fun onIzinResult(granted: Boolean) {
        Log.d(TAG, "izin ssid granted=$granted")
        if (granted) {
            onIzinSsidGranted?.invoke()
        }
    }

    /** Minta izin runtime baca SSID (no-op bila sudah granted / tanpa activity). */
    fun mintaIzinSsid(): Boolean {
        if (izinSsidGranted()) return false
        val activity = hostActivity ?: return false
        ActivityCompat.requestPermissions(
            activity,
            WifiKampusLoginManager.izinSsidDibutuhkan(),
            KODE_IZIN_SSID,
        )
        return true
    }

    /**
     * Status jaringan ringkas untuk UI: dipanggil Dart saat app open/resume.
     * Map: {diWifiKampus: bool, ssidTerbaca: bool, portalTerjangkau: bool}.
     */
    private fun statusJaringan(): Map<String, Any> {
        val cm = appContext.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager
        val wifi = wifiNetwork(cm)
        val capabilities = wifi?.let { cm.getNetworkCapabilities(it) }
        val currentSsid = ssidDari(capabilities)
        val diWifi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true &&
            currentSsid == ssid
        return mapOf(
            "diWifiKampus" to diWifi,
            "ssidTerbaca" to (currentSsid != null),
            "portalTerjangkau" to (wifi != null),
        )
    }

    /**
     * Baca SSID dari capabilities (transportInfo, API 29+) dengan fallback
     * WifiManager.connectionInfo untuk Android < 10 — tanpa fallback, device
     * lama diam-diam tidak pernah bisa auto-login.
     */
    private fun ssidDari(capabilities: NetworkCapabilities?): String? {
        val viaTransport = capabilities?.transportInfo as? WifiInfo
        if (viaTransport != null) {
            return viaTransport.ssid?.trim('"')
                ?.takeUnless { it.isEmpty() || it == "<unknown ssid>" }
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            val info = (appContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .connectionInfo
            return info?.ssid?.trim('"')
                ?.takeUnless { it.isEmpty() || it == "<unknown ssid>" }
        }
        return null
    }

    private fun loginAsync(username: String, password: String, result: MethodChannel.Result) {
        Thread {
            val outcome = try {
                loginIfConnected(username, password)
            } catch (e: Exception) {
                mapOf("status" to "portalGagal", "alasan" to (e.message ?: "galat tak terduga"))
            }
            // result di-thread background aman: MethodChannel.Result thread-safe
            // untuk satu panggilan (dok. io.flutter.plugin.common.MethodChannel).
            runCatching { result.success(outcome) }
        }.start()
    }

    /** Inti alur login — port langsung dari AmikomHotspotLoginManager.loginIfConnected. */
    private fun loginIfConnected(username: String, password: String): Map<String, Any> {
        val cm = appContext.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager
        val wifi = wifiNetwork(cm)
            ?: return mapOf("status" to "bukanWifiKampus").also {
                Log.d(TAG, "gerbang: tanpa transport WiFi")
            }

        val bound = cm.bindProcessToNetwork(wifi)
        if (!bound) {
            Log.d(TAG, "gerbang: bindProcessToNetwork gagal")
            return mapOf("status" to "bukanWifiKampus")
        }

        try {
            // SSID dicek SETELAH bind agar sumbernya berasal dari network yang
            // sama dengan jalur request (bukan network aktif seluler).
            val capabilities = cm.getNetworkCapabilities(wifi)
            val currentSsid = ssidDari(capabilities)
            Log.d(TAG, "gerbang: ssid=${currentSsid ?: "<tidak terbaca>"}")
            if (currentSsid != ssid) {
                // Fail-open: SSID tak terbaca (izin belum granted) tapi transport
                // WiFi aktif → portal menjadi gerbang sebenarnya (172.20.8.1 hanya
                // terjangkau di jaringan kampus). SSID terbaca ≠ kampus → skip.
                // Respons galat saat SSID tak terbaca dilaporkan bukanWifiKampus
                // agar tidak dihitung kegagalan backoff (mis. WiFi rumah).
                val percayaSsid = currentSsid != null
                if (percayaSsid) {
                    return mapOf(
                        "status" to "bukanWifiKampus",
                        "ssid" to currentSsid,
                    )
                }
                Log.d(TAG, "gerbang: ssid tak terbaca → fail-open, coba portal")
            }

            val login = postLogin(username, password)
            Log.d(TAG, "portal: status=${login["status"]}")
            if (login["status"] == "berhasil") {
                if (verifyInternet()) return login
                Log.d(TAG, "verifikasi: 204 gagal")
                return mapOf("status" to "loginDiterimaTanpaInternet")
            }
            // SSID tak terbaca + portal tidak mengonfirmasi sukses → bukan WiFi
            // kampus (galat koneksi/asing), jangan hitung gagal di Dart.
            if (currentSsid == null && login["status"] != "berhasil") {
                return mapOf("status" to "bukanWifiKampus")
            }
            return login
        } finally {
            cm.bindProcessToNetwork(null)
            // wifi sengaja tidak diputus — koneksi WiFi tetap dipakai app lain.
        }
    }

    private fun wifiNetwork(cm: ConnectivityManager): Network? {
        return cm.allNetworks.firstOrNull { network ->
            cm.getNetworkCapabilities(network)
                ?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        }
    }

    private fun postLogin(username: String, password: String): Map<String, Any> {
        val portal = try {
            URL(portalUrl)
        } catch (e: Exception) {
            return mapOf("status" to "portalGagal", "alasan" to "URL portal tidak valid")
        }

        if (portal.host != allowedPortalHost) {
            return mapOf("status" to "portalGagal", "alasan" to "Host portal tidak diizinkan")
        }

        val body = listOf(
            "username" to username,
            "password" to password,
            "dst" to redirectUrl,
            "popup" to "false",
        ).joinToString("&") { (key, value) ->
            "${encode(key)}=${encode(value)}"
        }

        var connection: HttpURLConnection? = null
        return try {
            val conn = (portal.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 10_000
                instanceFollowRedirects = false
                doOutput = true
                setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
                setRequestProperty("Accept", "text/html")
                setRequestProperty("User-Agent", "AmikomHotspotAutoLogin/1.0")
            }
            connection = conn

            conn.outputStream.use { output ->
                output.write(body.toByteArray(Charsets.UTF_8))
            }

            val code = conn.responseCode
            val text = runCatching {
                val stream = if (code in 200..299) conn.inputStream else conn.errorStream
                stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            }.getOrDefault("")
            val location = conn.getHeaderField("Location")

            when {
                code in 200..299 &&
                    (text.contains("You are logged in", ignoreCase = true) ||
                        text.contains("Koneksi Aktif", ignoreCase = true)) -> {
                    mapOf("status" to "berhasil")
                }

                text.contains("invalid username or password", ignoreCase = true) -> {
                    mapOf("status" to "kredensialSalah")
                }

                code in 300..399 && location?.contains("/login") == true -> {
                    mapOf("status" to "kredensialSalah")
                }

                code in 200..299 && text.contains("name=\"password\"", ignoreCase = true) -> {
                    // Halaman login kembali tampil: kredensial tidak diterima.
                    mapOf("status" to "kredensialSalah")
                }

                else -> mapOf("status" to "responsTakDikenal", "httpCode" to code)
            }
        } catch (e: IOException) {
            mapOf("status" to "portalGagal", "alasan" to "Koneksi ke portal gagal")
        } finally {
            connection?.disconnect()
        }
    }

    /** Verifikasi internet nyata lewat generate_204 (bukan sekadar WiFi connected). */
    private fun verifyInternet(): Boolean {
        var connection: HttpURLConnection? = null
        return try {
            val conn = (URL(connectivityCheckUrl).openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 8_000
                readTimeout = 8_000
                instanceFollowRedirects = false
                setRequestProperty("User-Agent", "AmikomHotspotAutoLogin/1.0")
            }
            connection = conn
            conn.responseCode == 204
        } catch (e: IOException) {
            false
        } finally {
            connection?.disconnect()
        }
    }

    private fun encode(value: String): String =
        URLEncoder.encode(value, Charsets.UTF_8.name())
}
