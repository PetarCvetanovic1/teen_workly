import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../screens/home_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/post_service_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/huddle_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final loggedIn = state.isLoggedIn;

        return Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loggedIn) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.indigo600,
                                Color(0xFF7C3AED),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              state.profile!.initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.profile!.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                              Text(
                                state.profile!.email,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'TeenWorkly',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                _DrawerTile(
                  icon: Icons.home_rounded,
                  label: 'Homepage',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushAndRemoveUntil(
                      SmoothPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Post a Job',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(builder: (_) => const PostJobScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.groups_rounded,
                  label: 'The Huddle',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(builder: (_) => const HuddleScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.handyman_rounded,
                  label: 'Post a Service',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(
                          builder: (_) => const PostServiceScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.search_rounded,
                  label: 'Find a Job',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        builder: (_) => const JobsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(
                          builder: (_) => const DashboardScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.chat_rounded,
                  label: 'Messages',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(
                          builder: (_) => const ConversationsScreen()),
                    );
                  },
                ),
                if (loggedIn)
                  _DrawerTile(
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        SmoothPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                const Divider(height: 24),
                _DrawerTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Contact Us',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      SmoothPageRoute(
                          builder: (_) => const ContactScreen()),
                    );
                  },
                ),
                if (!loggedIn) ...[
                  const Divider(height: 24),
                  _DrawerTile(
                    icon: Icons.login_rounded,
                    label: 'Log in',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        SmoothPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_add_rounded,
                    label: 'Join now',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        SmoothPageRoute(
                            builder: (_) => const SignUpScreen()),
                      );
                    },
                  ),
                ],
                if (loggedIn) ...[
                  const Spacer(),
                  const Divider(height: 1),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    color: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AppState>().logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Logged out'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.indigo600, size: 24),
      title: Text(
        label,
        style: color != null
            ? TextStyle(color: color, fontWeight: FontWeight.w600)
            : null,
      ),
      onTap: onTap,
    );
  }
}
