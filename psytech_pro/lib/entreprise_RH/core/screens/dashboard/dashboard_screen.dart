import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stat_card.dart';
import '../../navigation/app_router.dart';
import '../../services/data_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Les maquettes affichent « — » tant qu'il n'y a pas de données.
  static const String _empty = '—';

  final _store = DataStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runGuarded(context, _store.loadDashboard);
    });
  }

  String _percent(double? v) {
    if (v == null) return _empty;
    return v == v.roundToDouble() ? '${v.round()} %' : '${v.toStringAsFixed(1)} %';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.dashboard,
      pageLabel: 'Tableau de bord',
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final stats = _store.stats;
          final cards = [
            StatCard(
              label: 'Tests',
              icon: Icons.assignment_outlined,
              value: stats.tests == 0 ? _empty : '${stats.tests}',
            ),
            StatCard(
              label: 'Candidats',
              icon: Icons.group_outlined,
              value: stats.candidats == 0 ? _empty : '${stats.candidats}',
            ),
            StatCard(
              label: 'Taux de réussite',
              icon: Icons.check_circle_outline,
              value: _percent(stats.tauxReussite),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'Tableau de bord'),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 700) {
                    return Column(
                      children: [
                        for (final c in cards) ...[c, const SizedBox(height: 16)],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
