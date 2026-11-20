import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_card.dart';
import '../../../widgets/dashed_border_box.dart';
import '../../../widgets/info_note.dart';
import '../../../services/csv_parser.dart';
import '../../../services/csv_picker_service.dart';
import '../../../services/data_store.dart';
import 'key_dialog.dart';

class ImportCsvCard extends StatefulWidget {
  const ImportCsvCard({super.key, required this.testId, required this.days});

  final String? testId;
  final int? days;

  @override
  State<ImportCsvCard> createState() => _ImportCsvCardState();
}

class _ImportCsvCardState extends State<ImportCsvCard> {
  final _picker = CsvPickerService();
  PickedCsv? _file;
  CsvParseResult? _parsed;
  bool _saving = false;

  Future<void> _pick() async {
    try {
      final file = await _picker.pickCsv();
      if (!mounted || file == null) return;
      setState(() {
        _file = file;
        _parsed = CsvParser.parse(file.content);
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Impossible de lire le fichier CSV.');
      }
    }
  }

  Future<void> _generate() async {
    final parsed = _parsed;
    final file = _file;
    if (parsed == null || file == null) return;
    final store = DataStore.instance;
    final test = store.testById(widget.testId);
    final days = widget.days;

    if (test == null || days == null) {
      AppSnackbar.error(context,
          'Choisissez d’abord un test et une expiration dans « Générer une clé candidat ».');
      return;
    }
    if (parsed.rows.isEmpty) {
      AppSnackbar.error(
          context, 'Aucune ligne valide dans le fichier (format : nom,email).');
      return;
    }

    ImportSummary? summary;
    setState(() => _saving = true);
    final ok = await runGuarded(context, () async {
      summary = await store.importInvitations(
          csv: file.content, test: test, days: days);
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok || summary == null) return;

    setState(() {
      _file = null;
      _parsed = null;
    });
    // Les clés ne sont renvoyées qu'une seule fois: on les affiche toutes.
    await showImportDialog(context, summary!);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    return CustomCard(
      title: 'Importer un fichier CSV',
      subtitle: 'Générez des clés candidat en masse.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: DashedBorderBox(
              color: AppColors.border,
              fill: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.turquoiseLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file_outlined,
                        size: 18, color: AppColors.turquoise),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Choisir un fichier CSV',
                    compact: true,
                    variant: ButtonVariant.secondary,
                    onPressed: _pick,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _file?.name ?? 'Aucun fichier sélectionné',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (parsed != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${parsed.rows.length} ligne${parsed.rows.length > 1 ? 's' : ''} valide${parsed.rows.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.turquoise),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_file == null) ...[
            const SizedBox(height: 14),
            const InfoNote(
                'Importez un fichier CSV pour activer la génération des clés.'),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              label: 'Générer les clés',
              icon: Icons.vpn_key_outlined,
              compact: true,
              isLoading: _saving,
              onPressed: _file == null ? null : _generate,
            ),
          ),
        ],
      ),
    );
  }
}
