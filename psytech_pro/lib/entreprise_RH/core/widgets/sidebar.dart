import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/app_router.dart';
import '../navigation/nav_items.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import 'psytech_logo.dart';

/// Sidebar de navigation (fixe à gauche sur grand écran, Drawer sinon).
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.currentRoute});

  final String currentRoute;

  void _go(BuildContext context, String route) {
    if (route == currentRoute) {
      Scaffold.maybeOf(context)?.closeDrawer();
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _logout(BuildContext context) {
    AuthService().logout();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: PsyTechLogo(),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entreprise (RH)',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gestion de tests psychotechniques',
                    style: GoogleFonts.inter(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (final item in navItems)
              _SidebarItem(
                item: item,
                active: item.route == currentRoute,
                onTap: () => _go(context, item.route),
              ),
            const Spacer(),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _SidebarItem(
                item: const NavItem(
                  label: 'Déconnexion',
                  icon: Icons.logout,
                  route: AppRoutes.login,
                ),
                active: false,
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem(
      {required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.turquoise : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? AppColors.turquoiseLight : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}