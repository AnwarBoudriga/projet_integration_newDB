import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

enum BadgeTone { neutral, success, warning, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case BadgeTone.success:
        bg = AppColors.turquoiseLight;
        fg = AppColors.turquoise;
      case BadgeTone.warning:
        bg = const Color(0xFFFFF4E0);
        fg = const Color(0xFFB7791F);
      case BadgeTone.danger:
        bg = const Color(0xFFFDECEC);
        fg = AppColors.error;
      case BadgeTone.neutral:
        bg = const Color(0xFFEEF2F7);
        fg = const Color(0xFF52627A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11.5, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}
