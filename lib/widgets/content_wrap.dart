import 'package:flutter/material.dart';

/// Centers content at 60% of screen width on wide screens,
/// full width on narrow screens (< 700px).
class ContentWrap extends StatelessWidget {
  final Widget child;
  const ContentWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 700) return child;

    return Center(
      child: SizedBox(
        width: screenWidth * 0.6,
        child: child,
      ),
    );
  }
}
