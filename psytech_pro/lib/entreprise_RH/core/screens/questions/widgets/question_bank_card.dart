import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../services/data_store.dart';

class QuestionBankCard extends StatefulWidget {
  const QuestionBankCard({super.key});

  @override
  State<QuestionBankCard> createState() => _QuestionBankCardState();
}

class _QuestionBankCardState extends State<QuestionBankCard> {
  final Set<String> _checked = {};

  Future<void> _use() async {
    final store = DataStore.instance;
    final test = store.selectedTest;
    if (test == null) {
      AppSnackbar.error(context,
          'Créez ou sélectionnez d’abord un test dans la page « Tests ».');
      return;
    }
    final before = store.selectedQuestions.length;
    final ok = await runGuarded(
        context, () => store.addFromBank(test.id, _checked.toList()));
    if (!mounted || !ok) return;
    final n = store.selectedQuestions.length - before;
    setState(_checked.clear);
    AppSnackbar.success(
        context,
        n > 0
            ? '$n question${n > 1 ? 's' : ''} ajoutée${n > 1 ? 's' : ''} au test « ${test.title} ».'
            : 'Ces questions sont déjà dans le test « ${test.title} ».');
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final bank = store.bank;
        return CustomCard(
          title: 'Banque de questions',
          subtitle: 'Questions créées par le Super Administrateur.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bank.isEmpty)
                const EmptyState(
                  icon: Icons.library_books_outlined,
                  title: 'Aucune question disponible',
                  message: 'Les questions de la banque seront affichées ici.',
                )
              else
                for (final q in bank)
                  InkWell(
                    onTap: () => setState(() {
                      _checked.contains(q.id)
                          ? _checked.remove(q.id)
                          : _checked.add(q.id);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _checked.contains(q.id),
                              activeColor: AppColors.turquoise,
                              onChanged: (v) => setState(() {
                                v == true
                                    ? _checked.add(q.id)
                                    : _checked.remove(q.id);
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              q.text,
                              style: GoogleFonts.inter(
                                  fontSize: 12.5, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Utiliser la sélection',
                compact: true,
                variant: ButtonVariant.secondary,
                onPressed: (_checked.isEmpty || store.busy) ? null : _use,
              ),
            ],
          ),
        );
      },
    );
  }
}
