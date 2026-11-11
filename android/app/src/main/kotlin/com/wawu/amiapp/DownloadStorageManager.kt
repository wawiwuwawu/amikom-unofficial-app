package com.wawu.amiapp

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/**
 * Menyimpan berkas unduhan (PDF dsb) ke folder Download publik lewat MediaStore
 * API (Android 10+) — satu-satunya cara resmi menulis ke koleksi Downloads
 * tanpa izin storage apa pun. Direct-write dart:io ke
 * /storage/emulated/0/Download memicu EPERM saat menimpa berkas yatim
 * (bukan milik install aktif) atau di beberapa OEM.
 *
 * Android 9- (≤ API 28) tetap pakai path langsung: WRITE_EXTERNAL_STORAGE
 * dengan maxSdkVersion=28 sudah dideklarasikan dan dijangkau sistem file lama.
 *
 * Dedupe: bila MediaStore sudah punya berkas bernama sama milik app ini
 * (per-install, bukan berkas yatim), tulis ulang lewat openOutputStream —
 * nama tidak bertambah _1/_2 tiap unduh ulang. Berkas yatim ditangani
 * MediaStore (diberi suffix otomatis).
 */
object DownloadStorageManager {
    private const val CHANNEL = "amikom/download_storage"
    private const val TAG = "DownloadStorage"

    @Volatile
    private var appContext: Context? = null
    @Volatile
    private var channel: MethodChannel? = null

    fun attach(engine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        if (channel == null) {
            channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).also {
                it.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "simpan" -> {
                            val nama = call.argument<String>("namaFile") ?: ""
                            val bytes = call.argument<ByteArray>("bytes")
                            if (nama.isEmpty() || bytes == null) {
                                result.error("invalid_args", "namaFile/bytes wajib", null)
                                return@setMethodCallHandler
                            }
                            try {
                                result.success(simpan(nama, bytes))
                            } catch (e: Exception) {
                                android.util.Log.w(TAG, "simpan gagal: ${e.message}")
                                result.error("simpan_gagal", e.message, null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
            }
        }
    }

    /** Dipanggil Dart lewat channel. Return path tampilan (bukan path fisik). */
    fun simpan(namaFile: String, bytes: ByteArray): String {
        val context = appContext
            ?: throw IOException("Storage manager belum terpasang")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            simpanMediaStore(context.contentResolver, namaFile, bytes)
        } else {
            val dir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, namaFile)
            file.writeBytes(bytes)
            file.absolutePath
        }
    }

    private fun simpanMediaStore(resolver: ContentResolver, namaFile: String, bytes: ByteArray): String {
        val existing = cariBerkasApp(resolver, namaFile)
        if (existing != null) {
            try {
                resolver.openOutputStream(existing.second, "w").use { out ->
                    out?.write(bytes) ?: throw IOException("OutputStream null")
                }
                return existing.first
            } catch (e: Exception) {
                android.util.Log.w(TAG, "tulis-ulang gagal (${e.message}) — insert baru")
            }
        }
        // Insert baru. Query berkasnya balik supaya bisa lapor path Display tampilan.
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, namaFile)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeDari(namaFile))
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("MediaStore menolak berkas baru")
        resolver.openOutputStream(uri, "w").use { out ->
            out?.write(bytes) ?: throw IOException("OutputStream null")
        }
        return "${Environment.DIRECTORY_DOWNLOADS}/$namaFile"
    }

    /** (displayPath, uri) berkas bernama sama yang dibuat install app INI, atau null. */
    private fun cariBerkasApp(resolver: ContentResolver, namaFile: String): Pair<String, Uri>? {
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.RELATIVE_PATH,
        )
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
        val cursor = resolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            arrayOf(namaFile),
            null,
        ) ?: return null
        cursor.use {
            val idCol = it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameCol = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val pathCol = it.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
            while (it.moveToNext()) {
                val relative = it.getString(pathCol) ?: ""
                if (!relative.trimEnd('/').equals(Environment.DIRECTORY_DOWNLOADS, ignoreCase = true)) continue
                val nama = it.getString(nameCol) ?: ""
                val uri = MediaStore.Downloads.EXTERNAL_CONTENT_URI.buildUpon()
                    .appendPath(it.getString(idCol)).build()
                return Pair("${relative.trimEnd('/')}/$nama", uri)
            }
        }
        return null
    }

    private fun mimeDari(namaFile: String): String {
        val ext = namaFile.substringAfterLast('.', "").lowercase()
        return when (ext) {
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "zip" -> "application/zip"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            else -> "application/octet-stream"
        }
    }
}
