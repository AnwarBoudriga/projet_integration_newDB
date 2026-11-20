import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class DropdownItem<T> {
  const DropdownItem(this.value, this.label);

  final T value;
  final String label;
}

/// Liste déroulante avec libellé au-dessus (grisée si désactivée / vide).
class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final String hint;
  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final active = enabled && items.isNotEmpty && onChanged != null;
    String? selectedLabel;
    for (final item in items) {
      if (item.value == value) selectedLabel = item.label;
    }
    final hasError = errorText != null;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final field = Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.white : AppColors.disabledBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: hasError ? AppColors.error : AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel ?? hint,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: selectedLabel != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 18,
                      color: active
                          ? AppColors.textSecondary
                          : AppColors.disabledText),
                ],
              ),
            );
            if (!active) return field;
            return PopupMenuButton<T>(
              tooltip: '',
              color: AppColors.white,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 4),
              constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
              onSelected: onChanged,
              itemBuilder: (_) => [
                for (final item in items)
                  PopupMenuItem<T>(
                    value: item.value,
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
              ],
              child: field,
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
