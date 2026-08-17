import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ppks.dart';
import '../services/ppks_service.dart';
import '../widgets/glass_card.dart';

class PpksPage extends StatefulWidget {
  final VoidCallback? onBack;

  const PpksPage({super.key, this.onBack});

  @override
  State<PpksPage> createState() => _PpksPageState();
}

class _PpksPageState extends State<PpksPage> {
  final PpksService _service = PpksService();

  bool _isLoading = true;
  String _error = '';
  PpksData? _data;

  // Form State
  String _statusPelapor = 'korban'; // 'korban' or 'saksi'

  // Fields if Saksi
  final TextEditingController _namaKorbanController = TextEditingController();
  String? _selectedJkKorban;
  String? _selectedStatusKorban;

  // General Fields
  String? _selectedDisabilitasKorban;
  final TextEditingController _namaTerlaporController = TextEditingController();
  String? _selectedJkTerlapor;
  String? _selectedStatusTerlapor;

  final Set<String> _selectedAlasan = {};
  final Set<String> _selectedKebutuhan = {};
  final TextEditingController _kebutuhanLainnyaController = TextEditingController();

  DateTime? _tanggalKejadian;
  final TextEditingController _lokasiKejadianController = TextEditingController();
  final TextEditingController _kronologiKejadianController = TextEditingController();
  final TextEditingController _buktiController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _namaKorbanController.dispose();
    _namaTerlaporController.dispose();
    _kebutuhanLainnyaController.dispose();
    _lokasiKejadianController.dispose();
    _kronologiKejadianController.dispose();
    _buktiController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final res = await _service.getPpksData();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateApi(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _selectTanggalKejadian() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKejadian ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalKejadian = picked);
    }
  }

  void _resetForm() {
    setState(() {
      _statusPelapor = 'korban';
      _namaKorbanController.clear();
      _selectedJkKorban = null;
      _selectedStatusKorban = null;
      _selectedDisabilitasKorban = null;
      _namaTerlaporController.clear();
      _selectedJkTerlapor = null;
      _selectedStatusTerlapor = null;
      _selectedAlasan.clear();
      _selectedKebutuhan.clear();
      _kebutuhanLainnyaController.clear();
      _tanggalKejadian = null;
      _lokasiKejadianController.clear();
      _kronologiKejadianController.clear();
      _buktiController.clear();
      _nomorHpController.clear();
    });
  }

  Future<void> _submitForm() async {
    if (_statusPelapor == 'saksi') {
      if (_namaKorbanController.text.trim().isEmpty ||
          _selectedJkKorban == null ||
          _selectedStatusKorban == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap lengkapi Nama, Jenis Kelamin, dan Status Korban'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_namaTerlaporController.text.trim().isEmpty ||
        _selectedJkTerlapor == null ||
        _selectedStatusTerlapor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi Nama, Jenis Kelamin, dan Status Terlapor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAlasan.isEmpty || _selectedKebutuhan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih minimal satu Alasan Pengaduan dan Kebutuhan Korban'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedKebutuhan.contains('Lainnya') && _kebutuhanLainnyaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap sebutkan Kebutuhan Lainnya'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tanggalKejadian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Tanggal Kejadian'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_lokasiKejadianController.text.trim().isEmpty ||
        _kronologiKejadianController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Lokasi Kejadian dan Kronologi Kejadian'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_nomorHpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Nomor HP yang dapat dihubungi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final body = <String, dynamic>{
      'status': _statusPelapor,
      'disabilitas_korban': _selectedDisabilitasKorban ?? 'Tidak',
      'nama_terlapor': _namaTerlaporController.text.trim(),
      'jk_terlapor': _selectedJkTerlapor ?? '',
      'status_terlapor': _selectedStatusTerlapor ?? '',
      'alasan_pengaduan': _selectedAlasan.toList(),
      'kebutuhan_korban': _selectedKebutuhan.toList(),
      'tanggal_kejadian': _formatDateApi(_tanggalKejadian!),
      'lokasi_kejadian': _lokasiKejadianController.text.trim(),
      'kronologi_kejadian': _kronologiKejadianController.text.trim(),
      'bukti': _buktiController.text.trim(),
      'nomor_hp': _nomorHpController.text.trim(),
    };

    if (_selectedKebutuhan.contains('Lainnya')) {
      body['kebutuhan_korban_lainnya'] = _kebutuhanLainnyaController.text.trim();
    }

    if (_statusPelapor == 'saksi') {
      body['nama_korban'] = _namaKorbanController.text.trim();
      body['jk_korban'] = _selectedJkKorban ?? '';
      body['status_korban'] = _selectedStatusKorban ?? '';
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _service.submitPpks(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Pengaduan berhasil dikirim'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFF),
      appBar: AppBar(
        title: const Text(
          'Satgas PPKS Amikom',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF501F66)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF501F66)))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501F66)),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: const Color(0xFF501F66),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPrivacyBanner(),
                      const SizedBox(height: 16),
                      _buildFormCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPrivacyBanner() {
    final info = _data?.infoPrivacy;
    if (info == null || info.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.shield_fill, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kerahasiaan & Keamanan Dijamin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildFormCard() {
    final opts = _data?.options;
    if (opts == null) return const SizedBox.shrink();

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.doc_text_fill, color: Color(0xFF501F66), size: 20),
              SizedBox(width: 8),
              Text(
                'Formulir Pengaduan Kekerasan Seksual',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF501F66)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Radio Anda Sebagai (Status Pelapor)
          const Text('Anda Melapor Sebagai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
          const SizedBox(height: 8),
          Row(
            children: opts.statusPelapor.map((opt) {
              final isSelected = _statusPelapor == opt.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF501F66),
                    onSelected: (val) {
                      if (val) setState(() => _statusPelapor = opt.value);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Fields Korban jika Status Pelapor == 'saksi'
          if (_statusPelapor == 'saksi') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF501F66).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF501F66).withValues(alpha: 0.15)),
              ),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identitas Korban (Pelapor Saksi):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _namaKorbanController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Korban',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.person, color: Color(0xFF501F66)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedJkKorban,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Kelamin Korban',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.person_2, color: Color(0xFF501F66)),
                    ),
                    items: opts.jenisKelamin.map((jk) {
                      return DropdownMenuItem<String>(
                        value: jk,
                        child: Text(jk, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedJkKorban = val),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedStatusKorban,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status Korban',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(CupertinoIcons.briefcase, color: Color(0xFF501F66)),
                    ),
                    items: opts.statusPihak.map((st) {
                      return DropdownMenuItem<String>(
                        value: st,
                        child: Text(st, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStatusKorban = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Disabilitas Korban
          DropdownButtonFormField<String>(
            value: _selectedDisabilitasKorban,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Korban Memiliki Disabilitas?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.exclamationmark_circle, color: Color(0xFF501F66)),
            ),
            items: opts.disabilitas.map((d) {
              return DropdownMenuItem<String>(
                value: d,
                child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDisabilitasKorban = val),
          ),
          const SizedBox(height: 16),

          // Identitas Terlapor Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
            ),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identitas Terlapor (Pelaku):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                const SizedBox(height: 10),

                TextField(
                  controller: _namaTerlaporController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Terlapor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.person_badge_minus, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedJkTerlapor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin Terlapor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.person_2, color: Colors.red),
                  ),
                  items: opts.jenisKelamin.map((jk) {
                    return DropdownMenuItem<String>(
                      value: jk,
                      child: Text(jk, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedJkTerlapor = val),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedStatusTerlapor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status Terlapor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(CupertinoIcons.briefcase, color: Colors.red),
                  ),
                  items: opts.statusPihak.map((st) {
                    return DropdownMenuItem<String>(
                      value: st,
                      child: Text(st, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStatusTerlapor = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Multi Checkbox Alasan Pengaduan
          const Text('Alasan Pengaduan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
          const SizedBox(height: 6),
          ...opts.alasanPengaduan.map((alasan) {
            final isChecked = _selectedAlasan.contains(alasan);
            return CheckboxListTile(
              dense: true,
              value: isChecked,
              activeColor: const Color(0xFF501F66),
              title: Text(alasan, style: const TextStyle(fontSize: 12)),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedAlasan.add(alasan);
                  } else {
                    _selectedAlasan.remove(alasan);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 16),

          // Multi Checkbox Kebutuhan Korban
          const Text('Identifikasi Kebutuhan Korban:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF501F66))),
          const SizedBox(height: 6),
          ...opts.kebutuhanKorban.map((kebutuhan) {
            final isChecked = _selectedKebutuhan.contains(kebutuhan);
            return CheckboxListTile(
              dense: true,
              value: isChecked,
              activeColor: const Color(0xFF501F66),
              title: Text(kebutuhan, style: const TextStyle(fontSize: 12)),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedKebutuhan.add(kebutuhan);
                  } else {
                    _selectedKebutuhan.remove(kebutuhan);
                  }
                });
              },
            );
          }),

          // Input Kebutuhan Lainnya jika "Lainnya" dicentang
          if (_selectedKebutuhan.contains('Lainnya')) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _kebutuhanLainnyaController,
              decoration: const InputDecoration(
                labelText: 'Sebutkan Kebutuhan Lainnya',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.pencil, color: Color(0xFF501F66)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Date Picker Tanggal Kejadian
          InkWell(
            onTap: _selectTanggalKejadian,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal Kejadian',
                border: OutlineInputBorder(),
                prefixIcon: Icon(CupertinoIcons.calendar, color: Color(0xFF501F66)),
              ),
              child: Text(
                _tanggalKejadian != null ? _formatDateDisplay(_tanggalKejadian!) : 'Pilih Tanggal Kejadian',
                style: TextStyle(
                  fontSize: 13,
                  color: _tanggalKejadian != null ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lokasi Kejadian
          TextField(
            controller: _lokasiKejadianController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Lokasi Kejadian',
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.location_solid, color: Color(0xFF501F66)),
            ),
          ),
          const SizedBox(height: 16),

          // Kronologi Kejadian
          TextField(
            controller: _kronologiKejadianController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Kronologi Kejadian',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.text_quote, color: Color(0xFF501F66)),
            ),
          ),
          const SizedBox(height: 16),

          // Link Bukti
          TextField(
            controller: _buktiController,
            decoration: const InputDecoration(
              labelText: 'Link Bukti (Google Drive / URL)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.link, color: Color(0xFF501F66)),
            ),
          ),
          const SizedBox(height: 16),

          // Nomor HP
          TextField(
            controller: _nomorHpController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP Saksi/Korban yang Dapat Dihubungi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.phone_fill, color: Color(0xFF501F66)),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF501F66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 18),
              label: const Text(
                'Kirim Pengaduan PPKS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
