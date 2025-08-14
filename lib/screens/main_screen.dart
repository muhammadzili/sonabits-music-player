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
    final bool showBottomNav = !isPlayerVisible || songProvider.isPlayerMinimized;

    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          
          // Player Container with Animation
          if (isPlayerVisible && !songProvider.isPlayerMinimized)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));
                return SlideTransition(position: offsetAnimation, child: child);
              },
              child: const MusicPlayerScreen(),
            ),
        ],
      ),
      // PERBAIKAN: Bottom Navigation & Mini Player
      bottomNavigationBar: showBottomNav
          ? SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mini Player muncul di atas Nav Bar
                  if (isPlayerVisible && songProvider.isPlayerMinimized)
                    const MiniPlayer(),
                  
                  // Material 3 NavigationBar
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
            )
          : null, // Sembunyikan semua jika full player aktif
    );
  }
}
