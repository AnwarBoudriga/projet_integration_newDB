import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/validators.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/responsive_row.dart';
import '../../../models/question_model.dart';
import '../../../services/data_store.dart';

/// Formulaire d'ajout (ou de modification) d'une question.
class AddQuestionCard extends StatefulWidget {
  const AddQuestionCard({super.key, this.editing, required this.onFinished});

  final QuestionModel? editing;
  final VoidCallback onFinished;

  @override
  State<AddQuestionCard> createState() => _AddQuestionCardState();
}

class _AddQuestionCardState extends State<AddQuestionCard> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());
  final _points = TextEditingController();
  int? _correct;
  String? _correctError;
  bool _saving = false;

  static const _optionHints = [
    'Saisir la première option',
    'Saisir la deuxième option',
    'Saisir la troisième option',
    'Saisir la quatrième option',
  ];
  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) _fill(widget.editing!);
  }

  @override
  void didUpdateWidget(covariant AddQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing != null && widget.editing != oldWidget.editing) {
      _fill(widget.editing!);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _points.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(QuestionModel q) {
    _text.text = q.text;
    for (var i = 0; i < 4; i++) {
      _options[i].text = q.options[i];
    }
    _points.text = '${q.points}';
    _correct = q.correctIndex;
    _correctError = null;
  }

  void _clear() {
    _text.clear();
    _points.clear();
    for (final c in _options) {
      c.clear();
    }
    _formKey.currentState?.reset();
    setState(() {
      _correct = null;
      _correctError = null;
    });
  }

  void _cancelEdit() {
    _clear();
    widget.onFinished();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    final missingCorrect = _correct == null;
    setState(() => _correctError =
        missingCorrect ? 'Choisissez la réponse correcte.' : null);
    if (!valid || missingCorrect) return;

    final store = DataStore.instance;
    final options = [for (final c in _options) c.text.trim()];
    final points = int.parse(_points.text.trim());
    final editing = widget.editing;
    final text = _text.text.trim();

    if (editing == null && store.selectedTest == null) {
      AppSnackbar.error(context,
          'Créez ou sélectionnez d’abord un test dans la page « Tests ».');
      return;
    }

    setState(() => _saving = true);
    final test = store.selectedTest;
    final ok = await runGuarded(context, () async {
      if (editing != null) {
        await store.updateQuestion(editing.copyWith(
          text: text,
          options: options,
          correctIndex: _correct,
          points: points,
        ));
      } else {
        await store.addQuestion(
          testId: test!.id,
          text: text,
          options: options,
          correctIndex: _correct!,
          points: points,
        );
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;

    AppSnackbar.success(
        context,
        editing != null
            ? 'Question modifiée.'
            : 'Question ajoutée au test « ${test!.title} ».');
    _clear();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    const gap = SizedBox(height: 16);

    return CustomCard(
      title: isEditing ? 'Modifier la question' : 'Ajouter une question',
      subtitle: 'Saisissez l’énoncé, les quatre options et la réponse attendue.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Énoncé',
              hint: 'Saisir l’énoncé de la question',
              controller: _text,
              minLines: 3,
              maxLines: 4,
              validator: (v) =>
                  Validators.required(v, 'L’énoncé est obligatoire.'),
            ),
            for (var i = 0; i < 4; i++) ...[
              gap,
              CustomTextField(
                label: 'Option ${_letters[i]}',
                hint: _optionHints[i],
                controller: _options[i],
                validator: (v) => Validators.required(
                    v, 'L’option ${_letters[i]} est obligatoire.'),
              ),
            ],
            gap,
            ResponsiveRow(
              breakpoint: 420,
              gap: 16,
              children: [
                CustomDropdown<int>(
                  label: 'Réponse correcte',
                  hint: 'Choisir une option',
                  value: _correct,
                  errorText: _correctError,
                  items: [
                    for (var i = 0; i < 4; i++)
                      DropdownItem(i, 'Option ${_letters[i]}'),
                  ],
                  onChanged: (v) => setState(() {
                    _correct = v;
                    _correctError = null;
                  }),
                ),
                CustomTextField(
                  label: 'Points',
                  hint: 'Saisir les points',
                  controller: _points,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      Validators.positiveInt(v, 'Les points sont obligatoires.'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isEditing)
                    CustomButton(
                      label: 'Annuler',
                      compact: true,
                      variant: ButtonVariant.secondary,
                      onPressed: _cancelEdit,
                    ),
                  CustomButton(
                    label: isEditing
                        ? 'Enregistrer les modifications'
                        : 'Ajouter la question',
                    icon: isEditing ? Icons.check : Icons.add,
                    compact: true,
                    isLoading: _saving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
