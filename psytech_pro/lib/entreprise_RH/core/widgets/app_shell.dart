import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'sidebar.dart';

/// Coque commune des écrans internes : sidebar + fil d'Ariane + contenu.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.pageLabel,
    required this.child,
  });

  final String currentRoute;

  /// Dernier élément du fil d'Ariane (ex. « Tableau de bord »).
  final String pageLabel;
  final Widget child;

  static const double sidebarWidth = 240;
  static const double breakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        final horizontal = wide ? 32.0 : 16.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: wide
              ? null
              : Drawer(
                  width: sidebarWidth,
                  child: Sidebar(currentRoute: currentRoute),
                ),
          body: Row(
            children: [
              if (wide)
                SizedBox(
                  width: sidebarWidth,
                  child: Sidebar(currentRoute: currentRoute),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(label: pageLabel, showMenu: !wide),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            EdgeInsets.fromLTRB(horizontal, 32, horizontal, 32),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.label, required this.showMenu});

  final String label;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: showMenu ? 8 : 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Text(
            'Entreprise (RH)',
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: GoogleFonts.inter(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
