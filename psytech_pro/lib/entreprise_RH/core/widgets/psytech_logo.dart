import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Logo PsyTech Pro (glyphe Ψ + texte).
/// [light] = version blanche pour fond marine.
class PsyTechLogo extends StatelessWidget {
  const PsyTechLogo({super.key, this.light = false, this.showTagline = true});

  final bool light;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final mainColor = light ? AppColors.white : AppColors.navy;

    final glyph = light
        ? Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text('Ψ',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          )
        : Text('Ψ',
            style: GoogleFonts.inter(
                fontSize: 34, fontWeight: FontWeight.w300, color: mainColor));

    final name = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'PsyTech ',
            style: GoogleFonts.inter(
                fontSize: light ? 15 : 18,
                fontWeight: FontWeight.w700,
                color: mainColor),
          ),
          TextSpan(
            text: 'Pro',
            style: GoogleFonts.inter(
                fontSize: light ? 15 : 18,
                fontWeight: light ? FontWeight.w700 : FontWeight.w400,
                color: light ? AppColors.white : AppColors.turquoise),
          ),
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            name,
            if (showTagline && !light)
              Text(
                'GESTION DES TESTS PSYCHOTECHNIQUES',
                style: GoogleFonts.inter(
                    fontSize: 5.5,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary),
              ),
          ],
        ),
      ],
    );
  }
}
