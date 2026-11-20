import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Titre de page + sous-titre optionnel.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
                fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
