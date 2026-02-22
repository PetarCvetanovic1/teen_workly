import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

const _smoothTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _SmoothPageTransitionsBuilder(),
    TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
    TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
    TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
    TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _SmoothPageTransitionsBuilder(),
  },
);


void main() {
  runApp(const TeenWorklyApp());
}

class TeenWorklyApp extends StatelessWidget {
  const TeenWorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..seedDemoData(),
      child: MaterialApp(
      title: 'TeenWorkly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: _smoothTransitions,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.indigo600,
          primary: AppColors.indigo600,
          brightness: Brightness.light,
          surface: AppColors.slate50,
        ),
        scaffoldBackgroundColor: AppColors.slate50,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.plusJakartaSans(),
          bodyMedium: GoogleFonts.plusJakartaSans(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppColors.indigo600, width: 1.5),
            foregroundColor: AppColors.indigo600,
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        appBarTheme: AppBarThemeData(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.slate900,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: _smoothTransitions,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.indigo500,
          primary: AppColors.indigo400,
          brightness: Brightness.dark,
          surface: AppColors.slate950,
        ),
        scaffoldBackgroundColor: AppColors.slate950,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFF1E293B),
        ),
        appBarTheme: AppBarThemeData(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
