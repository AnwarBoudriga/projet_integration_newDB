import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../services/data_store.dart';
import '../../../widgets/app_snackbar.dart';

/// Affiche la clé générée (avec bouton Copier).
Future<void> showKeyDialog(
  BuildContext context, {
  required String name,
  required String keyValue,
  bool emailSent = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.white,
      title: Text('Clé candidat générée',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clé pour $name :', style: GoogleFonts.inter(fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              keyValue,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emailSent
                ? 'Un email contenant la clé a été envoyé au candidat. '
                    'Cette clé ne sera plus affichée ensuite.'
                : 'Aucun email n’a été envoyé : transmettez cette clé au candidat. '
                    'Elle ne sera plus affichée ensuite.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: keyValue));
            AppSnackbar.success(ctx, 'Clé copiée.');
          },
          child: const Text('Copier'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

/// Résultat d'un import CSV: clés générées (affichées une seule fois) + lignes refusées.
Future<void> showImportDialog(BuildContext context, ImportSummary summary) {
  final lines = [
    'nom;email;cle',
    for (final k in summary.created) '${k.name};${k.email};${k.key}',
  ].join('\n');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
          '${summary.created.length} clé${summary.created.length > 1 ? 's' : ''} candidat générée${summary.created.length > 1 ? 's' : ''}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ces clés ne seront plus affichées : copiez-les maintenant (un email est aussi envoyé à chaque candidat si le serveur d’emails est configuré).',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final k in summary.created)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${k.name} — ${k.email}',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                      SelectableText(k.key,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy)),
                    ],
                  ),
                ),
              if (summary.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Lignes ignorées (${summary.errors.length})',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error)),
                const SizedBox(height: 4),
                for (final e in summary.errors)
                  Text(e,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (summary.created.isNotEmpty)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: lines));
              AppSnackbar.success(ctx, 'Clés copiées.');
            },
            child: const Text('Tout copier'),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
