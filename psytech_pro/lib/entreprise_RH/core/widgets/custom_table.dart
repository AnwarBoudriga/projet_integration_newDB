import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Tableau avec en-tête grisé. Défilement horizontal si l'écran est étroit.
/// Si [rows] est vide, [emptyState] est affiché sous l'en-tête.
class CustomTable extends StatelessWidget {
  const CustomTable({
    super.key,
    required this.headers,
    required this.rows,
    this.emptyState,
    this.flexes,
    this.minWidth = 720,
  });

  final List<String> headers;
  final List<List<Widget>> rows;
  final Widget? emptyState;
  final List<int>? flexes;
  final double minWidth;

  /// Cellule texte standard.
  static Widget cell(String text, {bool muted = false}) => Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: GoogleFonts.inter(
            fontSize: 13,
            color: muted ? AppColors.textSecondary : AppColors.textPrimary),
      );

  Widget _line(List<Widget> cells, {required bool header}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: header ? 12 : 14),
      decoration: BoxDecoration(
        color: header ? AppColors.background : AppColors.white,
        border: header
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes != null && i < flexes!.length ? flexes![i] : 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Align(alignment: Alignment.centerLeft, child: cells[i]),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _line([
                      for (final h in headers)
                        Text(
                          h,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary),
                        ),
                    ], header: true),
                    for (final r in rows) _line(r, header: false),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty && emptyState != null) emptyState!,
          ],
        );
      },
    );
  }
}
