import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/info_note.dart';
import '../../../widgets/status_badge.dart';
import '../../../models/test_model.dart';
import '../../../services/data_store.dart';

class ManageTestCard extends StatelessWidget {
  const ManageTestCard({super.key});

  Future<void> _duplicate(BuildContext context, TestModel t) async {
    final store = DataStore.instance;
    TestModel? copy;
    final ok = await runGuarded(context, () async {
      copy = await store.duplicateTest(t.id);
    });
    if (ok && context.mounted) {
      AppSnackbar.success(context, 'Test dupliqué : « ${copy!.title} ».');
    }
  }

  Future<void> _publish(BuildContext context, TestModel t) async {
    final ok = await runGuarded(
        context, () => DataStore.instance.publishTest(t.id));
    if (ok && context.mounted) {
      AppSnackbar.success(context, 'Test « ${t.title} » publié.');
    }
  }

  Future<void> _unpublish(BuildContext context, TestModel t) async {
    final ok = await runGuarded(
        context, () => DataStore.instance.unpublishTest(t.id));
    if (ok && context.mounted) {
      AppSnackbar.success(context, 'Test « ${t.title} » dépublié.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tests = store.tests;
        final selected = store.selectedTest;

        return CustomCard(
          title: 'Gérer un test',
          subtitle: 'Sélectionnez un test existant pour agir sur sa publication.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomDropdown<String>(
                label: 'Test',
                hint: tests.isEmpty ? 'Aucun test disponible' : 'Sélectionner un test',
                enabled: tests.isNotEmpty,
                value: selected?.id,
                items: [for (final t in tests) DropdownItem(t.id, t.title)],
                onChanged: (id) => runGuarded(context, () => store.selectTest(id)),
              ),
              const SizedBox(height: 8),
              if (tests.isEmpty)
                const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Aucun test à gérer',
                  message: 'Les tests créés apparaîtront ici.',
                )
              else if (selected == null)
                const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Aucun test sélectionné',
                  message: 'Sélectionnez un test pour afficher ses détails.',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _TestDetails(
                    test: selected,
                    questionCount: selected.questionCount,
                  ),
                ),
              const Divider(height: 24, color: AppColors.border),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CustomButton(
                    label: 'Dupliquer',
                    icon: Icons.copy_outlined,
                    compact: true,
                    variant: ButtonVariant.secondary,
                    onPressed: (selected == null || store.busy)
                        ? null
                        : () => _duplicate(context, selected),
                  ),
                  CustomButton(
                    label: 'Publier',
                    compact: true,
                    variant: ButtonVariant.secondary,
                    onPressed: (selected == null || selected.published || store.busy)
                        ? null
                        : () => _publish(context, selected),
                  ),
                  CustomButton(
                    label: 'Dépublier',
                    compact: true,
                    variant: ButtonVariant.secondary,
                    onPressed: (selected == null || !selected.published || store.busy)
                        ? null
                        : () => _unpublish(context, selected),
                  ),
                ],
              ),
              if (selected == null) ...[
                const SizedBox(height: 14),
                const InfoNote(
                    'Ces actions seront disponibles après la sélection d’un test.'),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TestDetails extends StatelessWidget {
  const _TestDetails({required this.test, required this.questionCount});

  final TestModel test;
  final int questionCount;

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  test.title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                test.published ? 'Publié' : 'Brouillon',
                tone: test.published ? BadgeTone.success : BadgeTone.neutral,
              ),
            ],
          ),
          if (test.description.isNotEmpty) _row('Description', test.description),
          _row('Durée', '${test.durationMinutes} min'),
          _row('Catégorie', test.category),
          _row('Score minimum', '${test.minScore} %'),
          _row('Questions', '$questionCount'),
          _row('Score visible',
              test.showScore ? 'Oui, par le candidat' : 'Non'),
        ],
      ),
    );
  }
}
