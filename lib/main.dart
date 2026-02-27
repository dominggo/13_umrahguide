import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/audio_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const UmrahGuideApp());
}

class UmrahGuideApp extends StatelessWidget {
  const UmrahGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: MaterialApp(
        title: 'Panduan Umrah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
