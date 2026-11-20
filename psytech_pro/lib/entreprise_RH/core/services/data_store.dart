import 'package:flutter/foundation.dart';

import '../models/candidate_result.dart';
import '../models/invitation_model.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import 'api_client.dart';
import 'file_saver.dart';

/// Clé candidat générée (affichée une seule fois: le serveur n'en garde qu'un hash).
class IssuedKey {
  const IssuedKey({required this.name, required this.email, required this.key});

  final String name;
  final String email;
  final String key;
}

class CreatedInvitation {
  const CreatedInvitation({required this.key, required this.emailSent});

  final IssuedKey key;
  final bool emailSent;
}

class ImportSummary {
  const ImportSummary({required this.created, required this.errors});

  final List<IssuedKey> created;

  /// Lignes refusées par le serveur (ex.: « Ligne 4 (x@y): Email invalide. »).
  final List<String> errors;
}

class DashboardStats {
  const DashboardStats({this.tests = 0, this.candidats = 0, this.tauxReussite});

  final int tests;
  final int candidats;

  /// Pourcentage (0-100), null tant qu'aucun résultat n'existe.
  final double? tauxReussite;
}

/// Données du module Entreprise, chargées depuis l'API et partagées par tous les écrans.
/// Toutes les méthodes `load*` / actions lèvent [ApiException] en cas d'erreur.
class DataStore extends ChangeNotifier {
  DataStore._();

  static final DataStore instance = DataStore._();
  static final ApiClient _api = ApiClient.instance;

  String entrepriseNom = '';

  List<TestModel> _tests = [];
  List<QuestionModel> _questions = [];
  List<QuestionModel> _bank = [];
  List<InvitationModel> _invitations = [];
  List<CandidateResult> _results = [];
  DashboardStats _stats = const DashboardStats();
  String? _selectedTestId;
  bool _busy = false;
  bool _testsLoaded = false;

  /// Vide toutes les données (connexion / déconnexion).
  void reset() {
    entrepriseNom = '';
    _tests = [];
    _questions = [];
    _bank = [];
    _invitations = [];
    _results = [];
    _stats = const DashboardStats();
    _selectedTestId = null;
    _busy = false;
    _testsLoaded = false;
    notifyListeners();
  }

  // ---------------- Lecture ----------------
  bool get busy => _busy;
  bool get testsLoaded => _testsLoaded;
  DashboardStats get stats => _stats;
  List<TestModel> get tests => List.unmodifiable(_tests);
  List<TestModel> get publishedTests =>
      _tests.where((t) => t.published).toList();
  TestModel? get selectedTest => testById(_selectedTestId);

  TestModel? testById(String? id) {
    if (id == null) return null;
    for (final t in _tests) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Questions du test sélectionné (dans l'ordre).
  List<QuestionModel> get selectedQuestions => List.unmodifiable(_questions);
  List<QuestionModel> get bank => List.unmodifiable(_bank);
  List<InvitationModel> get invitations => List.unmodifiable(_invitations);
  List<CandidateResult> get results => List.unmodifiable(_results);

  CandidateResult? resultFor(String invitationId) {
    for (final r in _results) {
      if (r.invitationId == invitationId) return r;
    }
    return null;
  }

  /// Exécute une action serveur en bloquant les doubles clics (`busy`).
  Future<T> _mutate<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _list(dynamic data) => [
        for (final e in (data['data'] as List)) Map<String, dynamic>.from(e as Map),
      ];

  // ---------------- Tableau de bord ----------------
  Future<void> loadDashboard() async {
    final d = await _api.get('/entreprise/dashboard');
    _stats = DashboardStats(
      tests: (d['tests'] as num).toInt(),
      candidats: (d['candidats'] as num).toInt(),
      tauxReussite: (d['tauxReussite'] as num?)?.toDouble(),
    );
    notifyListeners();
  }

  // ---------------- Tests ----------------
  Future<void> loadTests() async {
    final d = await _api.get('/entreprise/tests');
    _tests = _list(d).map(TestModel.fromJson).toList();
    _testsLoaded = true;
    if (_selectedTestId != null && testById(_selectedTestId) == null) {
      _selectedTestId = null;
      _questions = [];
    }
    notifyListeners();
  }

  /// Sélectionne un test et charge ses questions.
  Future<void> selectTest(String? id) async {
    _selectedTestId = id;
    _questions = [];
    notifyListeners();
    if (id != null) await loadQuestions();
  }

  Future<TestModel> createTest({
    required String title,
    required String description,
    required int durationMinutes,
    required String category,
    required int minScore,
    required bool showScore,
  }) =>
      _mutate(() async {
        final d = await _api.post('/entreprise/tests', body: {
          'titre': title,
          'description': description,
          'dureeMinutes': durationMinutes,
          'categorie': category,
          'scoreMinimum': minScore,
          'afficherScore': showScore,
        });
        final t = TestModel.fromJson(Map<String, dynamic>.from(d as Map));
        await loadTests();
        if (_selectedTestId == null) await selectTest(t.id);
        return t;
      });

  Future<TestModel> duplicateTest(String id) => _mutate(() async {
        final d = await _api.post('/entreprise/tests/$id/dupliquer');
        final copy = TestModel.fromJson(Map<String, dynamic>.from(d as Map));
        await loadTests();
        await selectTest(copy.id);
        return copy;
      });

  Future<void> publishTest(String id) => _mutate(() async {
        await _api.patch('/entreprise/tests/$id/publier');
        await loadTests();
      });

  Future<void> unpublishTest(String id) => _mutate(() async {
        await _api.patch('/entreprise/tests/$id/depublier');
        await loadTests();
      });

  // ---------------- Questions ----------------
  void _setQuestions(dynamic d, String testId) {
    _questions = _list(d)
        .map((j) => QuestionModel.fromJson(j, testId: testId))
        .toList();
  }

  Future<void> loadQuestions() async {
    final testId = _selectedTestId;
    if (testId == null) return;
    final d = await _api.get('/entreprise/tests/$testId/questions');
    if (testId != _selectedTestId) return; // l'utilisateur a changé de test entre-temps
    _setQuestions(d, testId);
    notifyListeners();
  }

  Future<void> loadBank() async {
    final d = await _api.get('/entreprise/banque', query: {'limit': 100});
    _bank = _list(d).map(QuestionModel.fromJson).toList();
    notifyListeners();
  }

  /// Après chaque changement de questions, le serveur renvoie la liste complète du test.
  Future<void> _afterQuestionChange(dynamic d, String testId) async {
    if (testId == _selectedTestId) _setQuestions(d, testId);
    await loadTests(); // met à jour le nombre de questions
  }

  Future<void> addQuestion({
    required String testId,
    required String text,
    required List<String> options,
    required int correctIndex,
    required int points,
  }) =>
      _mutate(() async {
        final q = QuestionModel(
          id: '',
          testId: testId,
          text: text,
          options: options,
          correctIndex: correctIndex,
          points: points,
        );
        final d = await _api.post('/entreprise/tests/$testId/questions',
            body: q.toPayload());
        await _afterQuestionChange(d, testId);
      });

  Future<void> updateQuestion(QuestionModel q) => _mutate(() async {
        final d = await _api.put(
            '/entreprise/tests/${q.testId}/questions/${q.id}',
            body: q.toPayload());
        await _afterQuestionChange(d, q.testId);
      });

  /// Retire la question du test (et la supprime si elle appartient à l'entreprise).
  Future<void> deleteQuestion(QuestionModel q) => _mutate(() async {
        final d = await _api
            .delete('/entreprise/tests/${q.testId}/questions/${q.id}');
        await _afterQuestionChange(d, q.testId);
      });

  /// [delta] = -1 (monter) ou +1 (descendre).
  Future<void> moveQuestion(QuestionModel q, int delta) => _mutate(() async {
        final d = await _api.post(
            '/entreprise/tests/${q.testId}/questions/${q.id}/${delta < 0 ? 'monter' : 'descendre'}');
        if (q.testId == _selectedTestId) _setQuestions(d, q.testId);
      });

  Future<void> addFromBank(String testId, Iterable<String> bankIds) =>
      _mutate(() async {
        final d = await _api.post('/entreprise/tests/$testId/questions/banque',
            body: {
              'questionIds': [for (final id in bankIds) int.parse(id)],
            });
        await _afterQuestionChange(d, testId);
      });

  // ---------------- Invitations ----------------
  Future<void> loadInvitations() async {
    final d = await _api.get('/entreprise/invitations', query: {'limit': 200});
    _invitations = _list(d).map(InvitationModel.fromJson).toList();
    notifyListeners();
  }

  Future<CreatedInvitation> createInvitation({
    required String name,
    required String email,
    required TestModel test,
    required int days,
  }) =>
      _mutate(() async {
        final d = await _api.post('/entreprise/invitations', body: {
          'nom': name,
          'email': email,
          'testId': int.parse(test.id),
          'expirationJours': days,
        });
        await loadInvitations();
        return CreatedInvitation(
          key: IssuedKey(name: name, email: email, key: '${d['cle']}'),
          emailSent: d['emailEnvoye'] == true,
        );
      });

  /// Import CSV (« nom,email » ou « nom;email », en-tête facultatif): le serveur lit le fichier.
  Future<ImportSummary> importInvitations({
    required String csv,
    required TestModel test,
    required int days,
  }) =>
      _mutate(() async {
        final d = await _api.post('/entreprise/invitations/import', body: {
          'testId': int.parse(test.id),
          'expirationJours': days,
          'csv': csv,
        });
        await loadInvitations();
        return ImportSummary(
          created: [
            for (final c in (d['crees'] as List))
              IssuedKey(
                  name: '${c['nom']}', email: '${c['email']}', key: '${c['cle']}'),
          ],
          errors: [
            for (final e in (d['erreurs'] as List))
              'Ligne ${e['ligne']} (${e['email']}) : ${e['message']}',
          ],
        );
      });

  // ---------------- Résultats ----------------
  Future<void> loadResults() async {
    final d = await _api.get('/entreprise/resultats', query: {'limit': 200});
    _results = _list(d).map(CandidateResult.fromJson).toList();
    notifyListeners();
  }

  /// Charge le détail par question d'un résultat et le fusionne dans la liste.
  Future<CandidateResult> loadResultDetail(String invitationId) async {
    final d = await _api.get('/entreprise/resultats/$invitationId');
    final detail = CandidateResult.fromJson(Map<String, dynamic>.from(d as Map));
    final i = _results.indexWhere((r) => r.invitationId == invitationId);
    if (i >= 0) {
      _results = [..._results]..[i] = detail;
    } else {
      _results = [..._results, detail];
    }
    notifyListeners();
    return detail;
  }

  /// Télécharge l'export (format = 'csv' ou 'pdf'). Retourne le fichier enregistré.
  Future<String> exportResult(String invitationId, String format) async {
    final bytes =
        await _api.getBytes('/entreprise/resultats/$invitationId/export.$format');
    return saveFile(
      'resultat-$invitationId.$format',
      bytes,
      format == 'pdf' ? 'application/pdf' : 'text/csv;charset=utf-8',
    );
  }
}
