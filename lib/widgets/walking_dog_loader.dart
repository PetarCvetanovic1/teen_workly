import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../app_colors.dart';

class WalkingDogLoader extends StatefulWidget {
  final String? label;
  const WalkingDogLoader({super.key, this.label});

  @override
  State<WalkingDogLoader> createState() => _WalkingDogLoaderState();
}

class _WalkingDogLoaderState extends State<WalkingDogLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = widget.label?.trim().isNotEmpty == true
        ? widget.label!.trim()
        : 'Loading...';

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          final dx = (t - 0.5) * 34;
          final bob = math.sin(t * math.pi * 2) * 2.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 130,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 20 + dx,
                      top: 18 + bob,
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        size: 30,
                        color: AppColors.indigo600,
                      ),
                    ),
                    Positioned(
                      left: 62 + dx,
                      top: 28 - bob,
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 22,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
