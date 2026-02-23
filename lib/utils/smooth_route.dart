import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends MaterialPageRoute<T> {
  SmoothPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);
}
