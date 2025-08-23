// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';

import 'providers/download_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/song_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';

late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mzili.sonabits.channel.audio',
      androidNotificationChannelName: 'Sonabits Music',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // --- PERBAIKAN: Sediakan AudioHandler ke seluruh aplikasi ---
        // Ini akan memperbaiki error ProviderNotFoundException.
        Provider<AudioHandler>(create: (_) => _audioHandler),
        
        // Sekarang SongProvider bisa dibuat dengan aman.
        ChangeNotifierProvider(create: (context) => SongProvider(_audioHandler)),
        
        ChangeNotifierProvider(create: (context) => PlaylistProvider()),
        ChangeNotifierProvider(create: (context) => DownloadProvider()),
      ],
      child: const SonabitsApp(),
    ),
  );
}

class SonabitsApp extends StatelessWidget {
  const SonabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1DB954),
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
      surface: const Color(0xFF181818),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );

    return MaterialApp(
      title: 'Sonabits',
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
