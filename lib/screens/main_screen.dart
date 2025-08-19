// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/song_provider.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'music_player_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final bool isPlayerVisible = songProvider.currentSong != null;
    final bool isFullPlayerOpen = isPlayerVisible && !songProvider.isPlayerMinimized;

    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          
          // Player Layar Penuh dengan Animasi
          if (isFullPlayerOpen)
            const MusicPlayerScreen(), // Animasi sekarang ditangani di dalam widget player
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PERUBAHAN: Mini Player sekarang punya animasi muncul
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isPlayerVisible && songProvider.isPlayerMinimized
                  ? const MiniPlayer()
                  : const SizedBox.shrink(),
            ),
            
            // Sembunyikan Navigasi Bar saat player layar penuh aktif
            if (!isFullPlayerOpen)
              NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
