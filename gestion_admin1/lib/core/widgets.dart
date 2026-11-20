import 'package:flutter/material.dart';
import 'theme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.dark = false});
  final bool dark;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: dark ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.psychology_alt, color: C.navy, size: 22),
    ),
    const SizedBox(width: 8),
    Text('PsyTech',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: dark ? Colors.white : C.navy)),
    const SizedBox(width: 4),
    const Text('Pro', style: TextStyle(fontSize: 18, color: C.teal)),
  ]);
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 26, color: C.navy)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: C.muted)),
    ]),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, this.title, this.subtitle, required this.child, this.padding = const EdgeInsets.all(20)});
  final String? title, subtitle;
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.navy)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: C.muted)),
              ),
          ]),
        ),
        const Divider(height: 1, color: C.border),
      ],
      Padding(padding: padding, child: child),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: C.muted, size: 22),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: C.muted)),
      ]),
    ),
  );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged, onSubmitted;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: C.navy)),
    const SizedBox(height: 6),
    TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18, color: C.muted),
      ),
    ),
  ]);
}

class LabeledDropdown extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });
  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: C.navy)),
    const SizedBox(height: 6),
    DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint!, style: const TextStyle(color: C.muted, fontSize: 13)),
      style: const TextStyle(fontSize: 13.5, color: C.navy),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: onChanged,
    ),
  ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading, outlined;
  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final cb = loading ? null : onPressed;
    if (outlined) {
      return OutlinedButton(
        onPressed: cb,
        style: OutlinedButton.styleFrom(
            foregroundColor: C.navy, side: const BorderSide(color: C.border), padding: pad, shape: shape),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: cb,
      style: ElevatedButton.styleFrom(
          backgroundColor: C.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: C.border,
          elevation: 0,
          padding: pad,
          shape: shape),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.actif, {super.key});
  final bool actif;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: actif ? C.tealLight : const Color(0xFFFDECEC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(actif ? 'Actif' : 'Inactif',
        style: TextStyle(fontSize: 11, color: actif ? C.teal : Colors.red.shade700)),
  );
}

/// 2 colonnes sur grand écran, empilées sur mobile.
class TwoCols extends StatelessWidget {
  const TwoCols({super.key, required this.left, required this.right, this.leftFlex = 2, this.rightFlex = 3});
  final Widget left, right;
  final int leftFlex, rightFlex;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
    if (box.maxWidth >= 820) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 20),
        Expanded(flex: rightFlex, child: right),
      ]);
    }
    return Column(children: [left, const SizedBox(height: 20), right]);
  });
}

void toast(BuildContext c, String m, {bool error = false}) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? Colors.red.shade700 : C.navy,
      behavior: SnackBarBehavior.floating,
    ));

Future<bool> confirm(BuildContext c, String title, String msg) async =>
    (await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    )) ??
        false;

String fmtDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '—';
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}';
}
