import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/api_client.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  final int refreshTrigger;

  const DashboardPage({super.key, this.refreshTrigger = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _dashboardService = DashboardService();
  Dashboard? _dashboard;
  bool _loading = true;
  String? _error;
  int _lastRefresh = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != _lastRefresh) {
      _lastRefresh = widget.refreshTrigger;
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    try {
      final data = await _dashboardService.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Sesi berakhir')) {
        ApiClient.instance.clearTokens();
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final p = _dashboard!.profile;
    final s = _dashboard!.statistik;
    final st = _dashboard!.status;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(p),
            const SizedBox(height: 16),
            _buildStatistikCard(s),
            const SizedBox(height: 16),
            _buildStatusCard(st),
            const SizedBox(height: 16),
            _buildInfoCard(p),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Profile p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: p.fotoUrl.isNotEmpty
                  ? NetworkImage(p.fotoUrl)
                  : null,
              child: p.fotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 36)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nama,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('NPM: ${p.npm}',
                      style: const TextStyle(color: Colors.grey)),
                  Text('${p.prodi} - ${p.fakultas}',
                      style: const TextStyle(color: Colors.grey)),
                  Text('Angkatan ${p.angkatan}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard(Statistik s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistik Akademik',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem('IPK', s.ipk.toStringAsFixed(2), Colors.indigo),
                _statItem('SKS Total', '${s.totalSks}', Colors.teal),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statItem('SKS Maks', '${s.totalSksMaksimal}', Colors.orange),
                _statItem('SKS Aktif', '${s.sksSekarang}', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Status st) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statusItem('Status', st.status, Colors.green),
            _statusItem('Masa Studi', st.masaStudi, Colors.blue),
            _statusItem('Sisa', st.sisaMasaStudi, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoCard(Profile p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Lainnya',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('Pembimbing Akademik', p.pembimbingAkademik),
            _infoRow('No. HP', p.noHp),
            _infoRow('Email', p.email),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child:
                Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
