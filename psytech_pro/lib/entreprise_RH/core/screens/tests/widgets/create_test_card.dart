import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/validators.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/responsive_row.dart';
import '../../../services/data_store.dart';

class CreateTestCard extends StatefulWidget {
  const CreateTestCard({super.key});

  @override
  State<CreateTestCard> createState() => _CreateTestCardState();
}

class _CreateTestCardState extends State<CreateTestCard> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController();
  final _category = TextEditingController();
  final _minScore = TextEditingController();
  bool _showScore = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _duration, _category, _minScore]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _title.text.trim();
    setState(() => _saving = true);
    final ok = await runGuarded(context, () async {
      await DataStore.instance.createTest(
        title: title,
        description: _description.text.trim(),
        durationMinutes: int.parse(_duration.text.trim()),
        category: _category.text.trim(),
        minScore: int.parse(_minScore.text.trim()),
        showScore: _showScore,
      );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;

    for (final c in [_title, _description, _duration, _category, _minScore]) {
      c.clear();
    }
    _formKey.currentState!.reset();
    setState(() => _showScore = false);
    AppSnackbar.success(context, 'Test « $title » créé avec succès.');
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return CustomCard(
      title: 'Créer un test',
      subtitle: 'Renseignez le contenu du test et ses conditions de réussite.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Titre',
              hint: 'Saisir le titre du test',
              controller: _title,
              validator: (v) =>
                  Validators.required(v, 'Le titre est obligatoire.'),
            ),
            gap,
            CustomTextField(
              label: 'Description',
              hint: 'Décrire le test',
              controller: _description,
              minLines: 4,
              maxLines: 4,
            ),
            gap,
            ResponsiveRow(
              breakpoint: 420,
              gap: 16,
              children: [
                CustomTextField(
                  label: 'Durée',
                  hint: 'Durée en minutes',
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      Validators.positiveInt(v, 'La durée est obligatoire.'),
                ),
                CustomTextField(
                  label: 'Catégorie',
                  hint: 'Saisir une catégorie',
                  controller: _category,
                  validator: (v) =>
                      Validators.required(v, 'La catégorie est obligatoire.'),
                ),
              ],
            ),
            gap,
            CustomTextField(
              label: 'Score minimum de réussite (%)',
              hint: 'Pourcentage entre 0 et 100',
              controller: _minScore,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => Validators.percent(
                  v, 'Le score minimum est obligatoire.'),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => setState(() => _showScore = !_showScore),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _showScore,
                      activeColor: AppColors.turquoise,
                      onChanged: (v) => setState(() => _showScore = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Autoriser le candidat à voir son score',
                      style: GoogleFonts.inter(
                          fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                label: 'Créer le test',
                icon: Icons.add,
                compact: true,
                isLoading: _saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
