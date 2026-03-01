import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../state/app_state.dart';
import 'smooth_route.dart';

/// Centralized route helper for screens that require authentication.
SmoothPageRoute<T> appRoute<T>({
  required WidgetBuilder builder,
  bool requiresAuth = false,
  RouteSettings? settings,
}) {
  return SmoothPageRoute<T>(
    settings: settings,
    builder: (context) {
      if (!requiresAuth) return builder(context);
      final loggedIn = context.watch<AppState>().isLoggedIn;
      return loggedIn
          ? builder(context)
          : const LoginScreen(lockBackUntilAuth: true);
    },
  );
}
