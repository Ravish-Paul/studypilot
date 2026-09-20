import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/root_shell.dart';
import 'screens/subject_detail_screen.dart';

class StudyPilotApp extends StatelessWidget {
  const StudyPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPilot',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.dark),
      darkTheme: _buildTheme(Brightness.dark),
      routes: {
        '/paywall': (context) => const PaywallScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/onboarding') {
          return MaterialPageRoute<void>(
            builder: (_) => const OnboardingScreen(),
          );
        }
        if (settings.name == '/subject') {
          final subjectId = settings.arguments as String;
          return MaterialPageRoute<void>(
            builder: (_) => SubjectDetailScreen(subjectId: subjectId),
          );
        }
        return null;
      },
      home: const RootShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C7CFF),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF12141F)
          : const Color(0xFFF5F6FB),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF171A28)
            : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.25),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
