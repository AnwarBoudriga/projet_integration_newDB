import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/page_header.dart';
import '../../widgets/responsive_row.dart';
import '../../navigation/app_router.dart';
import '../../services/data_store.dart';
import 'widgets/generate_key_card.dart';
import 'widgets/import_csv_card.dart';
import 'widgets/invited_candidates_card.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  // Test et expiration choisis dans la carte « Générer une clé candidat »,
  // réutilisés par l'import CSV.
  String? _testId;
  int? _days;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final store = DataStore.instance;
      await runGuarded(context, store.loadTests); // tests publiés du menu déroulant
      if (mounted) await runGuarded(context, store.loadInvitations);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.invitations,
      pageLabel: 'Invitations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Gestion des invitations',
            subtitle: 'Générez des clés candidat individuellement ou par import CSV.',
          ),
          ResponsiveRow(
            flexes: const [6, 5],
            children: [
              GenerateKeyCard(
                testId: _testId,
                days: _days,
                onTestChanged: (id) => setState(() => _testId = id),
                onDaysChanged: (d) => setState(() => _days = d),
              ),
              ImportCsvCard(testId: _testId, days: _days),
            ],
          ),
          const SizedBox(height: 20),
          const InvitedCandidatesCard(),
        ],
      ),
    );
  }
}
