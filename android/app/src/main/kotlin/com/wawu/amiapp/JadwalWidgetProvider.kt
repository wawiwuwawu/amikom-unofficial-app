package com.wawu.amiapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget home screen "Jadwal Hari Ini".
 *
 * Data ditulis dari Dart via home_widget (SharedPreferences group plugin):
 *  - `keadaan`        : "ada" | "kosong" | "tanpa_data"
 *  - `judul_tanggal`  : contoh "Jadwal Hari Ini · Jumat, 24 Okt"
 *  - `baris1..baris4` : teks siap tampil "09:00 · Pemrograman Web · LT2"
 *
 * Widget sengaja TIDAK memicu fetch apa pun — ia hanya membaca cache yang
 * diperbarui app saat dibuka (kesepakatan Fase 4: tanpa wajib login,
 * tanpa background service tambahan).
 */
class JadwalWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val keadaan = prefs.getString(KUNCI_KEADAAN, KEADAAN_TANPA_DATA)
        val judul = prefs.getString(KUNCI_JUDUL, "Jadwal Hari Ini")

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.jadwal_widget)
            views.setTextViewText(R.id.widget_judul, judul)

            val idBaris = intArrayOf(
                R.id.widget_baris1,
                R.id.widget_baris2,
                R.id.widget_baris3,
                R.id.widget_baris4
            )

            when (keadaan) {
                KEADAAN_ADA -> {
                    var terisi = false
                    for (i in idBaris.indices) {
                        val teks = prefs.getString("${KUNCI_BARIS}${i + 1}", null)
                        if (teks.isNullOrBlank()) {
                            views.setViewVisibility(idBaris[i], View.GONE)
                        } else {
                            views.setViewVisibility(idBaris[i], View.VISIBLE)
                            views.setTextViewText(idBaris[i], teks)
                            terisi = true
                        }
                    }
                    views.setViewVisibility(
                        R.id.widget_info,
                        if (terisi) View.GONE else View.VISIBLE
                    )
                    if (!terisi) {
                        views.setTextViewText(R.id.widget_info, "Tidak ada kelas hari ini")
                    }
                }
                KEADAAN_KOSONG -> {
                    for (id in idBaris) views.setViewVisibility(id, View.GONE)
                    views.setViewVisibility(R.id.widget_info, View.VISIBLE)
                    views.setTextViewText(R.id.widget_info, "Tidak ada kelas hari ini")
                }
                else -> {
                    for (id in idBaris) views.setViewVisibility(id, View.GONE)
                    views.setViewVisibility(R.id.widget_info, View.VISIBLE)
                    views.setTextViewText(R.id.widget_info, "Buka app untuk memuat jadwal")
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

    companion object {
        const val KUNCI_KEADAAN = "keadaan"
        const val KUNCI_JUDUL = "judul_tanggal"
        const val KUNCI_BARIS = "baris"
        const val KEADAAN_ADA = "ada"
        const val KEADAAN_KOSONG = "kosong"
        const val KEADAAN_TANPA_DATA = "tanpa_data"
    }
}
