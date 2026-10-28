package com.wawu.amiapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/**
 * Widget home screen "Jadwal Hari Ini".
 *
 * Dart menulis SATU kunci `jadwal_json` via home_widget (SharedPreferences
 * group plugin): peta baris siap-tampil per kunci — nama hari Indonesia
 * ("Senin".."Minggu") untuk agenda mingguan, dan tanggal ISO `yyyy-MM-dd`
 * untuk ujian ber-tanggal. Provider inilah yang memilih baris sesuai tanggal
 * perangkat SETIAP kali widget dirender: saat app menulis data, saat sistem
 * men-update (tick periodik [AppWidgetInfo.updatePeriodMillis] 30 menit), dan
 * saat widget ditambahkan — sehingga pergantian hari terjadi TANPA membuka
 * app (bug versi pertama: baris dibekukan di hari terakhir app dibuka).
 *
 * Widget sengaja TIDAK memicu fetch apa pun — tanpa login, tanpa background
 * service tambahan; datanya cache terakhir yang ditulis app.
 */
class JadwalWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val jadwalJson = prefs.getString(KUNCI_JADWAL, null)

        val now = Calendar.getInstance()
        val hari = namaHari(now.get(Calendar.DAY_OF_WEEK))
        val iso = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val judul = "Jadwal Hari Ini · $hari, " +
            SimpleDateFormat("d MMM", Locale("id", "ID")).format(Date())

        // Kuliah/asisten dari kunci nama hari, ujian dari kunci tanggal ISO —
        // digabung (kelas dulu, ujian menyusul), maksimal 4 baris tampil.
        val baris = mutableListOf<String>()
        if (jadwalJson != null) {
            val obj = runCatching { JSONObject(jadwalJson) }.getOrNull()
            if (obj != null) {
                for (kunci in arrayOf(hari, iso)) {
                    val arr = obj.optJSONArray(kunci) ?: continue
                    for (i in 0 until arr.length()) {
                        val teks = arr.optString(i)
                        if (!teks.isNullOrBlank()) baris.add(teks)
                    }
                }
            }
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.jadwal_widget)
            views.setTextViewText(R.id.widget_judul, judul)

            val idBaris = intArrayOf(
                R.id.widget_baris1,
                R.id.widget_baris2,
                R.id.widget_baris3,
                R.id.widget_baris4
            )

            when {
                jadwalJson == null -> {
                    // Belum pernah ada data (belum buka app / setelah logout).
                    for (id in idBaris) views.setViewVisibility(id, View.GONE)
                    views.setViewVisibility(R.id.widget_info, View.VISIBLE)
                    views.setTextViewText(R.id.widget_info, "Buka app untuk memuat jadwal")
                }
                baris.isEmpty() -> {
                    for (id in idBaris) views.setViewVisibility(id, View.GONE)
                    views.setViewVisibility(R.id.widget_info, View.VISIBLE)
                    views.setTextViewText(R.id.widget_info, "Tidak ada kelas hari ini")
                }
                else -> {
                    var terisi = false
                    for (i in idBaris.indices) {
                        if (i < baris.size) {
                            views.setViewVisibility(idBaris[i], View.VISIBLE)
                            views.setTextViewText(idBaris[i], baris[i])
                            terisi = true
                        } else {
                            views.setViewVisibility(idBaris[i], View.GONE)
                        }
                    }
                    views.setViewVisibility(R.id.widget_info, View.GONE)
                    if (!terisi) {
                        views.setViewVisibility(R.id.widget_info, View.VISIBLE)
                        views.setTextViewText(R.id.widget_info, "Tidak ada kelas hari ini")
                    }
                }
            }

            // Ketukan widget → buka app (launcher intent utama).
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Calendar.SUNDAY..SATURDAY → "Minggu".."Sabtu" (nama identik dengan FE). */
    private fun namaHari(dayOfWeek: Int): String = when (dayOfWeek) {
        Calendar.SUNDAY -> "Minggu"
        Calendar.MONDAY -> "Senin"
        Calendar.TUESDAY -> "Selasa"
        Calendar.WEDNESDAY -> "Rabu"
        Calendar.THURSDAY -> "Kamis"
        Calendar.FRIDAY -> "Jumat"
        Calendar.SATURDAY -> "Sabtu"
        else -> ""
    }

    companion object {
        const val KUNCI_JADWAL = "jadwal_json"
    }
}
