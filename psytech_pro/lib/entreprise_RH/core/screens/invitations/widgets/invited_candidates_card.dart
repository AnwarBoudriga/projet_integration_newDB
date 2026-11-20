import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_table.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_badge.dart';
import '../../../services/data_store.dart';

class InvitedCandidatesCard extends StatelessWidget {
  const InvitedCandidatesCard({super.key});

  static BadgeTone _tone(String status) {
    switch (status) {
      case 'Terminé':
        return BadgeTone.success;
      case 'En cours':
        return BadgeTone.warning;
      case 'Expiré':
        return BadgeTone.danger;
      default:
        return BadgeTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final invitations = store.invitations;
        return CustomCard(
          title: 'Candidats invités',
          padding: EdgeInsets.zero,
          child: CustomTable(
            headers: const ['Nom', 'Email', 'Test', 'Expiration', 'Statut'],
            flexes: const [3, 4, 3, 2, 2],
            rows: [
              for (final i in invitations)
                [
                  CustomTable.cell(i.name),
                  CustomTable.cell(i.email, muted: true),
                  CustomTable.cell(i.testTitle),
                  CustomTable.cell(formatDate(i.expiresAt), muted: true),
                  StatusBadge(i.displayStatus, tone: _tone(i.displayStatus)),
                ],
            ],
            emptyState: const EmptyState(
              icon: Icons.mail_outline,
              title: 'Aucun candidat invité',
              message:
                  'Les candidats invités et leur statut apparaîtront ici après la génération des clés.',
              verticalPadding: 36,
            ),
          ),
        );
      },
    );
  }
}
