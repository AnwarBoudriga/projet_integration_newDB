import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _page = 1, _total = 0;
  static const _limit = 20;
  String _acteur = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _pages => (_total / _limit).ceil().clamp(1, 100000);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.dio.get('/api/admin/logs', queryParameters: {
        'page': _page,
        'limit': _limit,
        if (_acteur.isNotEmpty) 'acteurType': _acteur,
      });
      _items = List<Map<String, dynamic>>.from(r.data['data']);
      _total = r.data['pagination']['total'] as int;
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _row(List<String> c, {bool head = false}) => Container(
    color: head ? const Color(0xFFF7F9FC) : null,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    child: Row(children: [
      for (final e in c.indexed)
        Expanded(
          flex: const [3, 2, 4, 2, 2][e.$1],
          child: Text(e.$2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: head ? 11.5 : 12.5, color: head ? C.muted : C.navy)),
        ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('Journal d’activité', 'Consultez les activités enregistrées sur la plateforme.'),
      AppCard(
        title: 'Journal d’activité',
        subtitle: 'Consultation des journaux d’audit.',
        padding: EdgeInsets.zero,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: LabeledDropdown(
                  label: 'Acteur',
                  value: _acteur,
                  items: const {
                    '': 'Tous',
                    'super_admin': 'Super Admin',
                    'entreprise': 'Entreprise',
                    'candidat': 'Candidat',
                    'systeme': 'Système',
                  },
                  onChanged: (v) {
                    _acteur = v ?? '';
                    _page = 1;
                    _load();
                  },
                ),
              ),
            ),
          ),
          _row(['Date', 'Acteur', 'Action', 'Entité', 'IP'], head: true),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Aucune activité à afficher',
                subtitle: 'Aucun événement n’est disponible dans le journal d’activité.')
          else
            for (final l in _items)
              _row([
                fmtDate(l['createdAt']),
                '${l['acteurType']}',
                '${l['action']}',
                l['entite'] == null ? '—' : '${l['entite']} #${l['entiteId'] ?? ''}',
                '${l['ip'] ?? '—'}',
              ]),
          const Divider(height: 1, color: C.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Page $_page / $_pages', style: const TextStyle(fontSize: 12, color: C.muted)),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 && !_loading ? () { _page--; _load(); } : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < _pages && !_loading ? () { _page++; _load(); } : null,
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
