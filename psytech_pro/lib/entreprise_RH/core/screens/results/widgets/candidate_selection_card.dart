import 'package:flutter/material.dart';

import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/info_note.dart';
import '../../../models/candidate_result.dart';

class CandidateSelectionCard extends StatelessWidget {
  const CandidateSelectionCard({
    super.key,
    required this.results,
    required this.selected,
    required this.onChanged,
    required this.onExport,
  });

  /// Candidats ayant soumis leur test.
  final List<CandidateResult> results;
  final CandidateResult? selected;
  final ValueChanged<String> onChanged;

  /// Reçoit « csv » ou « pdf ».
  final ValueChanged<String> onExport;

  bool get hasResult => selected != null;

  @override
  Widget build(BuildContext context) {
    final dropdown = CustomDropdown<String>(
      label: 'Candidat',
      hint: results.isEmpty ? 'Aucun candidat disponible' : 'Sélectionner un candidat',
      enabled: results.isNotEmpty,
      value: selected?.invitationId,
      items: [
        for (final r in results)
          DropdownItem(r.invitationId, '${r.candidate} — ${r.testTitle}'),
      ],
      onChanged: onChanged,
    );

    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CustomButton(
          label: 'Exporter en CSV',
          icon: Icons.download_outlined,
          compact: true,
          variant: ButtonVariant.secondary,
          onPressed: hasResult ? () => onExport('csv') : null,
        ),
        CustomButton(
          label: 'Exporter en PDF',
          icon: Icons.download_outlined,
          compact: true,
          variant: ButtonVariant.secondary,
          onPressed: hasResult ? () => onExport('pdf') : null,
        ),
      ],
    );

    return CustomCard(
      title: 'Sélection du candidat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [dropdown, const SizedBox(height: 12), buttons],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: dropdown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  buttons,
                ],
              );
            },
          ),
          if (!hasResult) ...[
            const SizedBox(height: 14),
            const InfoNote(
                'Les exports seront disponibles lorsque des résultats pourront être consultés.'),
          ],
        ],
      ),
    );
  }
}
