import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.dio.get('/api/admin/stats');
      _d = Map<String, dynamic>.from(r.data);
    } catch (e) {
      _error = Api.errorMessage(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _tile(String label, String value, String sub, IconData icon) => Container(
    width: 230,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: C.muted)),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: C.tealLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: C.teal),
        ),
      ]),
      const SizedBox(height: 14),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: C.navy)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(fontSize: 11.5, color: C.muted)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
    } else if (_d == null) {
      body = EmptyState(icon: Icons.info_outline, title: 'Statistiques indisponibles', subtitle: _error ?? '');
    } else {
      final e = _d!['entreprises'], t = _d!['tests'], c = _d!['candidats'], r = _d!['resultats'];
      body = Wrap(spacing: 16, runSpacing: 16, children: [
        _tile('Entreprises', '${e['total']}', '${e['actives']} actives · ${e['inactives']} inactives', Icons.apartment),
        _tile('Tests', '${t['total']}', '${t['publies']} publiés', Icons.assignment_outlined),
        _tile('Candidats invités', '${c['invites']}', '${c['termines']} tests terminés', Icons.people_outline),
        _tile('Banque de questions', '${_d!['banqueQuestions']}', 'questions disponibles', Icons.checklist),
        _tile('Taux de réussite', '${r['tauxReussite']} %', '${r['total']} résultats', Icons.check_circle_outline),
        _tile('Score moyen', '${r['scoreMoyenPourcent']} %', 'sur tous les tests', Icons.bar_chart),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('Statistiques globales', 'Consultez les statistiques globales de la plateforme.'),
      AppCard(title: 'Consultation des statistiques', child: body),
    ]);
  }
}
