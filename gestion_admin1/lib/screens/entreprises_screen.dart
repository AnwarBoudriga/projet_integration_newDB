import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class EntreprisesScreen extends StatefulWidget {
  const EntreprisesScreen({super.key});
  @override
  State<EntreprisesScreen> createState() => _EntreprisesScreenState();
}

class _EntreprisesScreenState extends State<EntreprisesScreen> {
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _secteur = TextEditingController();
  final _search = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _saving = false, _busy = false;
  int? _selectedId;
  String _statut = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nom, _email, _secteur, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? get _sel {
    for (final e in _items) {
      if (e['id'] == _selectedId) return e;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.dio.get('/api/admin/entreprises', queryParameters: {
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        if (_statut.isNotEmpty) 'statut': _statut,
        'limit': 100,
      });
      _items = List<Map<String, dynamic>>.from(r.data['data']);
      if (_sel == null) _selectedId = null;
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    if (_nom.text.trim().isEmpty || _email.text.trim().isEmpty) {
      toast(context, 'Nom et email requis.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.dio.post('/api/admin/entreprises', data: {
        'nom': _nom.text.trim(),
        'email': _email.text.trim(),
        'secteur': _secteur.text.trim(),
      });
      _nom.clear();
      _email.clear();
      _secteur.clear();
      if (mounted) toast(context, 'Entreprise créée.');
      await _load();
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      await _load();
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _setStatut(String path) => _run(() async {
    await Api.dio.patch('/api/admin/entreprises/$_selectedId/$path');
    if (mounted) toast(context, path == 'activer' ? 'Entreprise activée.' : 'Entreprise désactivée.');
  });

  Future<void> _issueKey(bool regenerate) async {
    if (regenerate &&
        !await confirm(context, 'Régénérer la clé ?', 'L’ancienne clé deviendra immédiatement invalide.')) {
      return;
    }
    await _run(() async {
      final r = await Api.dio
          .post('/api/admin/entreprises/$_selectedId/cle${regenerate ? '/regenerer' : ''}');
      if (mounted) await _showKey(r.data['cle'], r.data['message']);
    });
  }

  Future<void> _showKey(String key, String msg) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clé entreprise'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.tealLight, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(key,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2, color: C.teal)),
          ),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontSize: 12.5, color: C.muted)),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: key));
            if (ctx.mounted) toast(ctx, 'Clé copiée.');
          },
          child: const Text('Copier'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
      ],
    ),
  );

  Widget _row(List<Widget> cells, {Color? color, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: cells[0]),
        Expanded(flex: 3, child: cells[1]),
        Expanded(flex: 2, child: cells[2]),
        SizedBox(width: 70, child: cells[3]),
      ]),
    ),
  );

  Text _t(String s, {bool bold = false, bool head = false}) => Text(s,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: head ? 11.5 : 12.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: head ? C.muted : C.navy));

  @override
  Widget build(BuildContext context) {
    final sel = _sel;
    final hasKey = sel?['aUneCle'] == true;
    final actif = sel?['statut'] == 'actif';

    final form = AppCard(
      title: 'Créer une entreprise',
      subtitle: 'Renseignez les informations de l’entreprise.',
      child: Column(children: [
        LabeledField(label: 'Nom', controller: _nom, hint: 'Saisir le nom de l’entreprise'),
        const SizedBox(height: 14),
        LabeledField(
            label: 'Email',
            controller: _email,
            hint: 'Saisir l’email de l’entreprise',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        LabeledField(label: 'Secteur', controller: _secteur, hint: 'Saisir le secteur de l’entreprise'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(label: 'Créer l’entreprise', icon: Icons.add, loading: _saving, onPressed: _create),
        ),
      ]),
    );

    final list = AppCard(
      title: 'Liste des entreprises',
      subtitle: 'Recherchez une entreprise pour accéder à ses actions de gestion.',
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: LabeledField(
                label: 'Rechercher',
                controller: _search,
                hint: 'Rechercher une entreprise',
                prefixIcon: Icons.search,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), _load);
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: LabeledDropdown(
                label: 'Statut',
                value: _statut,
                items: const {'': 'Tous les statuts', 'actif': 'Actif', 'inactif': 'Inactif'},
                onChanged: (v) {
                  setState(() => _statut = v ?? '');
                  _load();
                },
              ),
            ),
          ]),
        ),
        _row([_t('Nom', head: true), _t('Email', head: true), _t('Secteur', head: true), _t('Statut', head: true)],
            color: const Color(0xFFF7F9FC)),
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          const EmptyState(
              icon: Icons.apartment_outlined,
              title: 'Aucune entreprise disponible',
              subtitle: 'Les entreprises créées apparaîtront dans cette liste.')
        else
          for (final e in _items)
            _row(
              [_t(e['nom'], bold: true), _t(e['email']), _t(e['secteur'] ?? ''), StatusBadge(e['statut'] == 'actif')],
              color: e['id'] == _selectedId ? C.tealLight : null,
              onTap: () => setState(() => _selectedId = e['id']),
            ),
        const Divider(height: 1, color: C.border),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Actions sur l’entreprise',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: C.navy)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              PrimaryButton(
                  label: 'Activer',
                  icon: Icons.check,
                  outlined: true,
                  onPressed: sel != null && !actif && !_busy ? () => _setStatut('activer') : null),
              PrimaryButton(
                  label: 'Désactiver',
                  icon: Icons.block,
                  outlined: true,
                  onPressed: sel != null && actif && !_busy ? () => _setStatut('desactiver') : null),
              PrimaryButton(
                  label: 'Générer une clé',
                  icon: Icons.vpn_key_outlined,
                  outlined: true,
                  onPressed: sel != null && !hasKey && !_busy ? () => _issueKey(false) : null),
              PrimaryButton(
                  label: 'Régénérer une clé perdue',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: sel != null && hasKey && !_busy ? () => _issueKey(true) : null),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: C.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sel == null
                      ? 'Actions désactivées : aucune entreprise n’est sélectionnée.'
                      : 'Entreprise sélectionnée : ${sel['nom']}',
                  style: const TextStyle(fontSize: 12, color: C.muted),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('Gestion des entreprises',
          'Créez les entreprises et gérez leur activation ainsi que leur clé d’accès.'),
      TwoCols(left: form, right: list),
    ]);
  }
}
