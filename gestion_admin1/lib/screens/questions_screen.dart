import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});
  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final _enonce = TextEditingController();
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _c = TextEditingController();
  final _d = TextEditingController();
  final _points = TextEditingController();
  String? _rep;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _saving = false;
  int? _selId; // question sélectionnée dans la liste
  int? _editingId; // question chargée dans le formulaire

  List<TextEditingController> get _ctrls => [_enonce, _a, _b, _c, _d, _points];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? get _sel {
    for (final q in _items) {
      if (q['id'] == _selId) return q;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.dio.get('/api/admin/questions', queryParameters: {'limit': 100});
      _items = List<Map<String, dynamic>>.from(r.data['data']);
      if (_sel == null) _selId = null;
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clear() {
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() {
      _rep = null;
      _editingId = null;
    });
  }

  void _fill(Map<String, dynamic> q) {
    _enonce.text = q['enonce'];
    _a.text = q['optionA'];
    _b.text = q['optionB'];
    _c.text = q['optionC'];
    _d.text = q['optionD'];
    _points.text = '${q['points']}';
    setState(() {
      _rep = q['reponseCorrecte'];
      _editingId = q['id'];
    });
  }

  Map<String, dynamic>? _payload() {
    final pts = int.tryParse(_points.text.trim());
    if (_enonce.text.trim().isEmpty ||
        [_a, _b, _c, _d].any((c) => c.text.trim().isEmpty) ||
        _rep == null ||
        pts == null ||
        pts < 1) {
      toast(context, 'Renseignez tous les champs (points ≥ 1).', error: true);
      return null;
    }
    return {
      'enonce': _enonce.text.trim(),
      'optionA': _a.text.trim(),
      'optionB': _b.text.trim(),
      'optionC': _c.text.trim(),
      'optionD': _d.text.trim(),
      'reponseCorrecte': _rep,
      'points': pts,
    };
  }

  Future<void> _submit({required bool update}) async {
    final p = _payload();
    if (p == null) return;
    setState(() => _saving = true);
    try {
      if (update) {
        await Api.dio.put('/api/admin/questions/$_editingId', data: p);
      } else {
        await Api.dio.post('/api/admin/questions', data: p);
      }
      if (mounted) toast(context, update ? 'Question modifiée.' : 'Question créée.');
      _clear();
      await _load();
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Supprimer la question ?', 'Cette action est définitive.')) return;
    try {
      await Api.dio.delete('/api/admin/questions/$_selId');
      if (_editingId == _selId) _clear();
      _selId = null;
      if (mounted) toast(context, 'Question supprimée.');
      await _load();
    } catch (e) {
      if (mounted) toast(context, Api.errorMessage(e), error: true);
    }
  }

  Widget _info(String s) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, size: 14, color: C.muted),
      const SizedBox(width: 6),
      Expanded(child: Text(s, style: const TextStyle(fontSize: 12, color: C.muted))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final sel = _sel;

    final list = AppCard(
      title: 'Questions de la banque',
      subtitle: 'Sélectionnez une question pour la modifier ou la supprimer.',
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          const EmptyState(
              icon: Icons.checklist,
              title: 'Aucune question disponible',
              subtitle: 'Les questions créées apparaîtront ici.')
        else
          for (final q in _items)
            InkWell(
              onTap: () => setState(() => _selId = q['id']),
              child: Container(
                width: double.infinity,
                color: q['id'] == _selId ? C.tealLight : null,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q['enonce'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.navy)),
                  const SizedBox(height: 3),
                  Text('Réponse : ${q['reponseCorrecte']}  ·  ${q['points']} pt(s)',
                      style: const TextStyle(fontSize: 11.5, color: C.muted)),
                ]),
              ),
            ),
        const Divider(height: 1, color: C.border),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              PrimaryButton(
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                  outlined: true,
                  onPressed: sel == null ? null : () => _fill(sel)),
              PrimaryButton(
                  label: 'Supprimer',
                  icon: Icons.delete_outline,
                  outlined: true,
                  onPressed: sel == null ? null : _delete),
            ]),
            _info(sel == null
                ? 'Modification et suppression désactivées : aucune question sélectionnée.'
                : 'Cliquez sur « Modifier » pour charger la question dans le formulaire.'),
          ]),
        ),
      ]),
    );

    final form = AppCard(
      title: 'Créer ou modifier une question',
      subtitle: 'Renseignez l’énoncé, les quatre options, la réponse et les points.',
      child: Column(children: [
        LabeledField(label: 'Énoncé', controller: _enonce, hint: 'Saisir l’énoncé de la question', maxLines: 3),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: LabeledField(label: 'Option 1 (A)', controller: _a, hint: 'Première option')),
          const SizedBox(width: 14),
          Expanded(child: LabeledField(label: 'Option 2 (B)', controller: _b, hint: 'Deuxième option')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: LabeledField(label: 'Option 3 (C)', controller: _c, hint: 'Troisième option')),
          const SizedBox(width: 14),
          Expanded(child: LabeledField(label: 'Option 4 (D)', controller: _d, hint: 'Quatrième option')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: LabeledDropdown(
              label: 'Réponse',
              value: _rep,
              hint: 'Bonne option',
              items: const {'A': 'Option 1 (A)', 'B': 'Option 2 (B)', 'C': 'Option 3 (C)', 'D': 'Option 4 (D)'},
              onChanged: (v) => setState(() => _rep = v),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: LabeledField(
                label: 'Points',
                controller: _points,
                hint: 'Points attribués',
                keyboardType: TextInputType.number),
          ),
        ]),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            PrimaryButton(
                label: 'Créer la question',
                icon: Icons.add,
                loading: _saving,
                onPressed: _editingId == null ? () => _submit(update: false) : null),
            PrimaryButton(
                label: 'Enregistrer les modifications',
                outlined: true,
                onPressed: _editingId == null ? null : () => _submit(update: true)),
            if (_editingId != null) PrimaryButton(label: 'Annuler', outlined: true, onPressed: _clear),
          ]),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _info(_editingId == null
              ? 'Pour modifier une question, sélectionnez-la dans la banque puis cliquez sur « Modifier ».'
              : 'Modification de la question #$_editingId.'),
        ),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader('Banque de questions', 'Consultez la banque de questions et gérez leur contenu.'),
      TwoCols(left: list, right: form, leftFlex: 1, rightFlex: 1),
    ]);
  }
}
