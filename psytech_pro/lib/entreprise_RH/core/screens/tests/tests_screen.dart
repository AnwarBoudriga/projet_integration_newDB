import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/page_header.dart';
import '../../widgets/responsive_row.dart';
import '../../navigation/app_router.dart';
import '../../services/data_store.dart';
import 'widgets/create_test_card.dart';
import 'widgets/manage_test_card.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runGuarded(context, DataStore.instance.loadTests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentRoute: AppRoutes.tests,
      pageLabel: 'Tests',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Gestion des tests',
            subtitle: 'Créez vos tests et gérez leur publication.',
          ),
          ResponsiveRow(
            flexes: [6, 5],
            children: [CreateTestCard(), ManageTestCard()],
          ),
        ],
      ),
    );
  }
}
