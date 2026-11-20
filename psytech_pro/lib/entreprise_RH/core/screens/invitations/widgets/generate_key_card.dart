import 'package:flutter/material.dart';

import '../../../utils/validators.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/info_note.dart';
import '../../../widgets/responsive_row.dart';
import '../../../services/data_store.dart';
import 'expiry_options.dart';
import 'key_dialog.dart';

class GenerateKeyCard extends StatefulWidget {
  const GenerateKeyCard({
    super.key,
    required this.testId,
    required this.days,
    required this.onTestChanged,
    required this.onDaysChanged,
  });

  final String? testId;
  final int? days;
  final ValueChanged<String> onTestChanged;
  final ValueChanged<int> onDaysChanged;

  @override
  State<GenerateKeyCard> createState() => _GenerateKeyCardState();
}

class _GenerateKeyCardState extends State<GenerateKeyCard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _testError;
  String? _daysError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    final store = DataStore.instance;
    final test = store.testById(widget.testId);
    setState(() {
      _testError = test == null ? 'Choisissez un test.' : null;
      _daysError = widget.days == null ? 'Choisissez une expiration.' : null;
    });
    if (!valid || test == null || widget.days == null) return;

    final name = _name.text.trim();
    CreatedInvitation? created;
    setState(() => _saving = true);
    final ok = await runGuarded(context, () async {
      created = await store.createInvitation(
        name: name,
        email: _email.text.trim(),
        test: test,
        days: widget.days!,
      );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok || created == null) return;

    _name.clear();
    _email.clear();
    _formKey.currentState!.reset();
    showKeyDialog(context,
        name: name,
        keyValue: created!.key.key,
        emailSent: created!.emailSent);
  }

  @override
  Widget build(BuildContext context) {
    final store = DataStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final published = store.publishedTests;
        final hasTests = published.isNotEmpty;
        final testValue =
            published.any((t) => t.id == widget.testId) ? widget.testId : null;
        const gap = SizedBox(height: 16);

        return CustomCard(
          title: 'Générer une clé candidat',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveRow(
                  breakpoint: 420,
                  gap: 16,
                  children: [
                    CustomTextField(
                      label: 'Nom',
                      hint: 'Nom du candidat',
                      controller: _name,
                      validator: (v) =>
                          Validators.required(v, 'Le nom est obligatoire.'),
                    ),
                    CustomTextField(
                      label: 'Email',
                      hint: 'Adresse email du candidat',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                  ],
                ),
                gap,
                ResponsiveRow(
                  breakpoint: 420,
                  gap: 16,
                  children: [
                    CustomDropdown<String>(
                      label: 'Test',
                      hint: hasTests ? 'Choisir un test' : 'Aucun test disponible',
                      enabled: hasTests,
                      value: testValue,
                      errorText: _testError,
                      items: [for (final t in published) DropdownItem(t.id, t.title)],
                      onChanged: (id) {
                        setState(() => _testError = null);
                        widget.onTestChanged(id);
                      },
                    ),
                    CustomDropdown<int>(
                      label: 'Expiration',
                      hint: 'Choisir une expiration',
                      value: widget.days,
                      errorText: _daysError,
                      items: expiryOptions,
                      onChanged: (d) {
                        setState(() => _daysError = null);
                        widget.onDaysChanged(d);
                      },
                    ),
                  ],
                ),
                if (!hasTests) ...[
                  gap,
                  const InfoNote(
                      'Un test doit être disponible pour générer une clé candidat.'),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomButton(
                    label: 'Générer la clé',
                    icon: Icons.vpn_key_outlined,
                    compact: true,
                    isLoading: _saving,
                    onPressed: hasTests ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
