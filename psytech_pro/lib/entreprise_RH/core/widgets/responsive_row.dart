import 'package:flutter/material.dart';

/// Colonnes côte à côte au-dessus de [breakpoint], empilées en dessous.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.flexes,
    this.breakpoint = 900,
    this.gap = 20,
  });

  final List<Widget> children;
  final List<int>? flexes;
  final double breakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(flex: flexes?[i] ?? 1, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
