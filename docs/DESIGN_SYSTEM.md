# BRIEF REDESIGN — amikom-unofficial-app

Baca file ini SEBELUM mengerjakan. Ini kontrak kerja untuk semua agent redesign.

## Repo
- Path: `/tmp/amikom-audit` (branch `redesign/ui-nav-refactor`). Kerjakan HANYA di folder itu.
- Flutter SDK: `export PATH="/home/dede/flutter/bin:$PATH"`

## Design system (SUDAH ADA — pakai, jangan ubah)

`lib/theme/app_theme.dart`:
- `AppColors`: primary, primarySoft, scaffold, surface, surfaceMuted, textPrimary, textSecondary, textMuted, border, borderStrong, success, successBg, warning, warningBg, danger, dangerBg, info, infoBg
- `AppSpacing`: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32 (juga `.page`, `.card`)
- `AppRadius`: sm=10, md=14, lg=20, pill
- `AppText`: display, h1, h2, h3, body, bodySm, label, overline, button, metric
  **SEMUA GETTER, BUKAN const** → jangan tulis `const` pada widget yang memakainya.
- `AppDeco`: `card()`, `panel()`, `softPrimary()`, `listGroup()`
- `GradeStyle.of('A')` → `(Color bg, Color fg)`

`lib/widgets/app_kit.dart`:
- `AppScaffold(title:, subtitle:, body:, actions:, scrollable:, padding:, floatingActionButton:, bottomNavigationBar:, drawer:, background:)`
- `AppSection(title:, trailing:, child:, topGap:)`
- `AppSurface(child:, variant: AppSurfaceVariant.plain|hero|warning|danger|success, padding:, onTap:, radius:)`
- `AppListGroup.from([...row])` / `AppListGroup(children: [...])`
- `AppListRow(leading:, title:, subtitle:, trailing:, onTap:, padding:)`
- `AppGradeBadge(grade:)`
- `AppPill(label, tone: AppPillTone.neutral|success|warning|danger|info)`
- `AppStatTile(value:, label:, icon:, accent:)`
- `AppKeyValue(label:, value:, emphasize:)`
- `AppLoading(message:)`
- `AppEmptyState(title:, message:, icon:, actionLabel:, onAction:)`
- `AppErrorState(message:, onRetry:)`
- `AppAsyncView<T>(loading:, error:, data:, isEmpty:, builder:, onRetry:, loadingMessage:, emptyTitle:, emptyMessage:, emptyIcon:, wrapInSurface:)`
- `AppSearchField(controller:, hint:, onChanged:, onClear:)`

Import: `import '../theme/app_theme.dart'; import '../widgets/app_kit.dart';`

## Aturan KETAT
1. JANGAN sentuh `lib/services/` dan `lib/models/`. Panggilan API + nama field harus tetap persis.
2. JANGAN ubah nama class halaman maupun parameter konstruktornya (dipakai file lain).
3. SEMUA logika (state, service call, navigasi, parsing, unduh) tetap sama. HANYA tampilan yang berubah.
4. `Color(0x...)` keras → `AppColors.*`
5. `TextStyle(...)` ad-hoc → `AppText.*`
6. `Scaffold + AppBar` → `AppScaffold`
7. `CircularProgressIndicator` mentah → `AppLoading` / `AppAsyncView`
8. Data yang dibaca/dibandingkan (nilai, jadwal, tagihan, daftar) → `AppListGroup` + `AppListRow`.
   **JANGAN satu kartu per baris data.** Ini tujuan utama redesign.
9. `AppSurface` (kartu) hanya untuk konten visual & ringkasan: berita, pengumuman, prestasi, banner.
10. Hindari lint `use_null_aware_elements`: tulis `?x` bukan `if (x != null) x!,` untuk elemen list tunggal.
11. Hindari lint `unnecessary_underscores`: tulis `(_, _, _)` bukan `(_, __, ___)`.
12. Verifikasi: `export PATH="/home/dede/flutter/bin:$PATH"; cd /tmp/amikom-audit && flutter analyze`
    → pastikan TIDAK ada issue yang menyebut file tugasmu. Issue di file lain abaikan (agent lain sedang mengerjakannya).
13. JANGAN `git commit`, JANGAN `git push`, JANGAN buat file baru.
14. JANGAN ubah teks/string konten (judul, label, pesan). Hanya tampilan.

## Target perubahan visual
Masalah yang diperbaiki: aplikasi terasa seperti template Flutter dasar karena
983 warna hardcoded, 920 `TextStyle` ad-hoc, dan setiap item data dibungkus kartu
sendiri sehingga tampak penuh dan sulit dipindai mata.

Prinsip jawaban: **data yang dibaca = list; konten yang dilihat = kartu.**

## Laporan akhir
Sebutkan: daftar file yang diubah, ringkasan perubahan tampilan, baris terakhir `flutter analyze`.
