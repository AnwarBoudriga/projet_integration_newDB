import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary }

/// Bouton principal turquoise ou secondaire (blanc bordé).
/// Désactivé = gris, comme dans les maquettes.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
    this.variant = ButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final bool compact;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 42.0;
    final fontSize = compact ? 12.5 : 13.0;
    final padding = EdgeInsets.symmetric(horizontal: compact ? 14 : 18);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));
    final textStyle =
        GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w500);
    final callback = isLoading ? null : onPressed;

    final content = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 8),
              ],
              Text(label),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 16),
              ],
            ],
          );

    final Widget button = variant == ButtonVariant.primary
        ? ElevatedButton(
            onPressed: callback,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(0, height),
              padding: padding,
              textStyle: textStyle,
              shape: shape,
            ),
            child: content,
          )
        : OutlinedButton(
            onPressed: callback,
            style: OutlinedButton.styleFrom(
              elevation: 0,
              minimumSize: Size(0, height),
              padding: padding,
              textStyle: textStyle,
              shape: shape,
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.disabledBg,
              disabledForegroundColor: AppColors.disabledText,
              side: BorderSide(
                  color: callback == null ? AppColors.disabledBg : AppColors.border),
            ),
            child: content,
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}
