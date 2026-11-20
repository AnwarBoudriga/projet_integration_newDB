import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/psytech_logo.dart';

class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PsyTechLogo(light: true),
          const Spacer(flex: 5),
          Container(
            width: 32,
            height: 2,
            color: AppColors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Plateforme de Gestion de Tests Psychotechniques',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                height: 1.3,
                color: AppColors.white,
              ),
            ),
          ),
          const Spacer(flex: 6),
          Row(
            children: [
              Icon(Icons.vpn_key_outlined,
                  size: 14, color: AppColors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Accès par clé entreprise',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
