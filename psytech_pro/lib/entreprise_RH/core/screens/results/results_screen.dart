import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/page_header.dart';
import '../../navigation/app_router.dart';
import '../../services/data_store.dart';
import 'widgets/candidate_selection_card.dart';
import 'widgets/result_details_card.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _store = DataStore.instance;
  String? _invitationId;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runGuarded(context, _store.loadResults);
    });
  }

  Future<void> _select(String id) async {
    setState(() {
      _invitationId = id;
      _loadingDetail = true;
    });
    await runGuarded(context, () => _store.loadResultDetail(id));
    if (mounted) setState(() => _loadingDetail = false);
  }

  Future<void> _export(String format) async {
    final id = _invitationId;
    if (id == null) return;
    String? saved;
    final ok = await runGuarded(context, () async {
      saved = await _store.exportResult(id, format);
    });
    if (ok && mounted) {
      AppSnackbar.success(
          context, 'Export ${format.toUpperCase()} enregistré : $saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.results,
      pageLabel: 'Résultats',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Résultats des candidats',
            subtitle:
                'Consultez les résultats détaillés par candidat et exportez-les au format CSV ou PDF.',
          ),
          ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final selected =
                  _invitationId == null ? null : _store.resultFor(_invitationId!);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CandidateSelectionCard(
                    results: _store.results,
                    selected: selected,
                    onChanged: _select,
                    onExport: _export,
                  ),
                  const SizedBox(height: 20),
                  ResultDetailsCard(result: selected, loading: _loadingDetail),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
