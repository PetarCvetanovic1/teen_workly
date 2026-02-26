import 'package:flutter/material.dart';
import 'app_bar_nav.dart';
import 'auth_button.dart';
import 'logo_title.dart';

/// Standard TeenWorkly AppBar.
/// Top row: hamburger, logo, auth buttons.
/// Bottom row: nav pills (icon-only on phones, icon+label on wide screens).
class TwAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogoTap;
  final Widget? leading;

  const TwAppBar({super.key, this.onLogoTap, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 4,
      leading: leading,
      title: LogoTitle(onTap: onLogoTap),
      actions: const [AuthButton()],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(52),
        child: AppBarNav(),
      ),
    );
  }
}
