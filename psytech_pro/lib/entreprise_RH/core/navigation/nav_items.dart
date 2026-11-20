import 'package:flutter/material.dart';

import 'app_router.dart';

class NavItem {
  const NavItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

/// Menu de la sidebar (noms identiques aux maquettes).
const List<NavItem> navItems = [
  NavItem(
      label: 'Tableau de bord',
      icon: Icons.grid_view_outlined,
      route: AppRoutes.dashboard),
  NavItem(
      label: 'Tests',
      icon: Icons.assignment_outlined,
      route: AppRoutes.tests),
  NavItem(
      label: 'Questions',
      icon: Icons.checklist_rounded,
      route: AppRoutes.questions),
  NavItem(
      label: 'Invitations',
      icon: Icons.mail_outline,
      route: AppRoutes.invitations),
  NavItem(
      label: 'Résultats',
      icon: Icons.description_outlined,
      route: AppRoutes.results),
];
