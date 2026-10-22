import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../utils/format.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    // Go to Home shortly after the fade-in finishes.
    _ctrl.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/images/custom_icons/splash_icon.png',
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.mosque,
                      size: 72,
                      color: kPrimaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Panduan Umrah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Developed by Faeq!\ndengan Audios dan Doa\ndari M-Umrah Pro!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
