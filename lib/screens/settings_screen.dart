import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variabel untuk menampung nilai pengaturan
  bool _isDataSaverOn = false;
  bool _isCrossfadeOn = true;
  double _crossfadeDuration = 6.0;

  @override
  void initState() {
    super.initState();
    // Muat pengaturan saat halaman pertama kali dibuka
    _loadSettings();
  }

  // Fungsi untuk memuat pengaturan dari local storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil nilai yang tersimpan, jika tidak ada, gunakan nilai default
      _isDataSaverOn = prefs.getBool('dataSaver') ?? false;
      _isCrossfadeOn = prefs.getBool('crossfade') ?? true;
      _crossfadeDuration = prefs.getDouble('crossfadeDuration') ?? 6.0;
    });
  }

  // Fungsi untuk menyimpan pengaturan ke local storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dataSaver', _isDataSaverOn);
    await prefs.setBool('crossfade', _isCrossfadeOn);
    await prefs.setDouble('crossfadeDuration', _crossfadeDuration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Pengaturan Playback
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Playback', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          ),
          SwitchListTile(
            title: const Text('Data Saver'),
            subtitle: const Text('Memutar musik dalam kualitas lebih rendah'),
            value: _isDataSaverOn,
            onChanged: (value) {
              setState(() {
                _isDataSaverOn = value;
              });
              _saveSettings(); // Simpan perubahan
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data Saver ${value ? "diaktifkan" : "dinonaktifkan"}')),
              );
            },
            secondary: const Icon(Icons.signal_cellular_alt_rounded),
          ),
          SwitchListTile(
            title: const Text('Crossfade'),
            subtitle: const Text('Transisi mulus antar lagu'),
            value: _isCrossfadeOn,
            onChanged: (value) {
              setState(() {
                _isCrossfadeOn = value;
              });
              _saveSettings(); // Simpan perubahan
            },
            secondary: const Icon(Icons.swap_horiz_rounded),
          ),
          // Slider akan muncul jika Crossfade aktif
          if (_isCrossfadeOn)
            ListTile(
              title: Text('Durasi Crossfade: ${_crossfadeDuration.toInt()} detik'),
              subtitle: Slider(
                value: _crossfadeDuration,
                min: 0,
                max: 12,
                divisions: 12,
                label: '${_crossfadeDuration.toInt()} s',
                onChanged: (value) {
                  setState(() {
                    _crossfadeDuration = value;
                  });
                },
                // Simpan perubahan setelah selesai menggeser slider
                onChangeEnd: (value) {
                  _saveSettings();
                },
              ),
            ),
          const Divider(),

          // Pengaturan Cache
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Penyimpanan', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded),
            title: const Text('Bersihkan Cache'),
            subtitle: const Text('Kosongkan cache gambar dan lagu'),
            onTap: () {
              // Simulasi membersihkan cache
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache berhasil dibersihkan!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
