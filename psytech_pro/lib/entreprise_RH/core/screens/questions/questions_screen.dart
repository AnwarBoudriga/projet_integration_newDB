import 'package:flutter/material.dart';

import '../../widgets/app_shell.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/page_header.dart';
import '../../widgets/responsive_row.dart';
import '../../models/question_model.dart';
import '../../navigation/app_router.dart';
import '../../services/data_store.dart';
import 'widgets/add_question_card.dart';
import 'widgets/question_bank_card.dart';
import 'widgets/test_questions_card.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  String? _selectedId;
  QuestionModel? _editing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final store = DataStore.instance;
      await runGuarded(context, () async {
        await store.loadTests();
        await store.loadQuestions(); // test sélectionné dans la page « Tests »
      });
      if (mounted) await runGuarded(context, store.loadBank);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.questions,
      pageLabel: 'Questions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Gestion des questions',
            subtitle:
                'Ajoutez vos questions ou utilisez celles de la banque du Super Administrateur.',
          ),
          ResponsiveRow(
            flexes: const [3, 2],
            children: [
              AddQuestionCard(
                editing: _editing,
                onFinished: () => setState(() => _editing = null),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TestQuestionsCard(
                    selectedId: _selectedId,
                    onSelect: (id) => setState(() => _selectedId = id),
                    onEdit: (q) => setState(() => _editing = q),
                    onDeleted: (id) => setState(() {
                      if (_selectedId == id) _selectedId = null;
                      if (_editing?.id == id) _editing = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  const QuestionBankCard(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
