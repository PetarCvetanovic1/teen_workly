import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

/// App logo matching website: "Teen" (slate) + "Workly" (indigo).
/// Tap navigates to homepage when [onTap] is set.
class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teenColor = isDark ? Colors.white : AppColors.slate900;
    final worklyColor = isDark ? AppColors.indigo400 : AppColors.indigo600;

    final logo = RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(text: 'Teen', style: TextStyle(color: teenColor)),
          TextSpan(text: 'Workly', style: TextStyle(color: worklyColor)),
        ],
      ),
    );

    if (onTap == null) return logo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: logo,
      ),
    );
  }
}
