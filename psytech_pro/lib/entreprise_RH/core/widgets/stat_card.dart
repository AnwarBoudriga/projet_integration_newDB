import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'custom_card.dart';

/// Carte statistique : libellé + icône dans un carré turquoise clair + valeur.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.turquoiseLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: AppColors.turquoise),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
