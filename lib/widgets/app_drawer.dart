import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/jobs_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Hire Teens',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 24),
            _DrawerTile(
              icon: Icons.home_rounded,
              label: 'Homepage',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
            ),
            _DrawerTile(
              icon: Icons.add_circle_outline_rounded,
              label: 'Post a Job',
              onTap: () {
                Navigator.pop(context);
                // TODO: Post a job screen
              },
            ),
            _DrawerTile(
              icon: Icons.search_rounded,
              label: 'Find a Job',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const JobsScreen(),
                  ),
                );
              },
            ),
            _DrawerTile(
              icon: Icons.login_rounded,
              label: 'Log in',
              onTap: () {
                Navigator.pop(context);
                // TODO: Log in screen
              },
            ),
            _DrawerTile(
              icon: Icons.person_add_rounded,
              label: 'Join now',
              onTap: () {
                Navigator.pop(context);
                // TODO: Join / sign up screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.indigo600, size: 24),
      title: Text(label),
      onTap: onTap,
    );
  }
}
