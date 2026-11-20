import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_table.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_badge.dart';
import '../../../models/candidate_result.dart';

class ResultDetailsCard extends StatelessWidget {
  const ResultDetailsCard({super.key, required this.result, this.loading = false});

  final CandidateResult? result;

  /// Détail par question en cours de chargement.
  final bool loading;

  Widget _info(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final res = result;

    return CustomCard(
      title: 'Résultats détaillés par candidat',
      child: res == null
          ? const EmptyState(
              icon: Icons.description_outlined,
              title: 'Aucun résultat à afficher',
              message:
                  'Lorsqu’un candidat aura des résultats, sélectionnez-le pour consulter le détail ici.',
              verticalPadding: 64,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 40,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    _info('Candidat', res.candidate),
                    _info('Email', res.email),
                    _info('Test', res.testTitle),
                    _info('Score',
                        '${res.score} / ${res.total} (${res.percent.round()} %)'),
                    StatusBadge(
                      res.passed ? 'Réussi' : 'Échoué',
                      tone: res.passed ? BadgeTone.success : BadgeTone.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (loading && res.lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: CustomTable(
                    minWidth: 640,
                    headers: const [
                      'N°',
                      'Question',
                      'Réponse du candidat',
                      'Bonne réponse',
                      'Points',
                    ],
                    flexes: const [1, 5, 3, 3, 2],
                    rows: [
                      for (var i = 0; i < res.lines.length; i++)
                        [
                          CustomTable.cell('${i + 1}'),
                          CustomTable.cell(res.lines[i].question),
                          CustomTable.cell(res.lines[i].chosen),
                          CustomTable.cell(res.lines[i].correct, muted: true),
                          StatusBadge(
                            '${res.lines[i].earned} / ${res.lines[i].points}',
                            tone: res.lines[i].earned > 0
                                ? BadgeTone.success
                                : BadgeTone.danger,
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
