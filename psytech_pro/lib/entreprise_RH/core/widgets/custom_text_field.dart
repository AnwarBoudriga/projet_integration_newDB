import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Champ avec libellé au-dessus, comme dans les maquettes.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.validator,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
