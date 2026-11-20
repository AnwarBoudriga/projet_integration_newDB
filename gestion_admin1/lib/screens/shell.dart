import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'entreprises_screen.dart';
import 'logs_screen.dart';
import 'questions_screen.dart';
import 'stats_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.onLogout});
  final Future<void> Function() onLogout;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _nav = [
    ('Entreprises', Icons.apartment_outlined),
    ('Statistiques globales', Icons.insights_outlined),
    ('Journal d’activité', Icons.receipt_long_outlined),
    ('Banque de questions', Icons.checklist_outlined),
  ];

  Widget _page() {
    switch (_i) {
      case 0:
        return const EntreprisesScreen();
      case 1:
        return const StatsScreen();
      case 2:
        return const LogsScreen();
      default:
        return const QuestionsScreen();
    }
  }

  Widget _sidebar({bool drawer = false}) => Container(
    width: 250,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
    child: SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(left: 6), child: Logo()),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Text('Super Administrateur',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: C.navy)),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 6, top: 2),
          child: Text('Gestion de tests psychotechniques', style: TextStyle(fontSize: 11, color: C.muted)),
        ),
        const SizedBox(height: 20),
        for (var k = 0; k < _nav.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: k == _i ? C.tealLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _i = k);
                  if (drawer) Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(children: [
                    Icon(_nav[k].$2, size: 18, color: k == _i ? C.teal : C.muted),
                    const SizedBox(width: 10),
                    Text(_nav[k].$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: k == _i ? FontWeight.w600 : FontWeight.w400,
                          color: k == _i ? C.teal : C.muted,
                        )),
                  ]),
                ),
              ),
            ),
          ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onLogout,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(Icons.logout, size: 18, color: C.muted),
              SizedBox(width: 10),
              Text('Se déconnecter', style: TextStyle(fontSize: 13, color: C.muted)),
            ]),
          ),
        ),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 900;
      final content = Column(children: [
        Container(
          color: Colors.white,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(children: [
            const Text('Super Administrateur', style: TextStyle(fontSize: 12.5, color: C.muted)),
            const Text('   /   ', style: TextStyle(fontSize: 12.5, color: C.muted)),
            Text(_nav[_i].$1,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.navy)),
          ]),
        ),
        const Divider(height: 1, color: C.border),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 32 : 16),
            child: KeyedSubtree(key: ValueKey(_i), child: _page()),
          ),
        ),
      ]);

      if (wide) {
        return Scaffold(
          body: Row(children: [
            _sidebar(),
            const VerticalDivider(width: 1, color: C.border),
            Expanded(child: content),
          ]),
        );
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: C.navy,
          elevation: 0,
          title: const Logo(),
        ),
        drawer: Drawer(child: _sidebar(drawer: true)),
        body: content,
      );
    });
  }
}
