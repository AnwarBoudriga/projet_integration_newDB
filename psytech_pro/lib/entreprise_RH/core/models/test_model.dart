class TestModel {
  const TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    required this.minScore,
    required this.showScore,
    this.published = false,
    this.questionCount = 0,
    this.totalPoints = 0,
  });

  /// API: GET/POST /api/entreprise/tests
  factory TestModel.fromJson(Map<String, dynamic> j) => TestModel(
        id: '${j['id']}',
        title: '${j['titre'] ?? ''}',
        description: '${j['description'] ?? ''}',
        durationMinutes: (j['dureeMinutes'] as num?)?.toInt() ?? 0,
        category: '${j['categorie'] ?? ''}',
        minScore: (j['scoreMinimum'] as num?)?.toInt() ?? 0,
        showScore: j['afficherScore'] == true,
        published: j['statut'] == 'publie',
        questionCount: (j['nbQuestions'] as num?)?.toInt() ?? 0,
        totalPoints: (j['totalPoints'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String category;

  /// Score minimum de réussite, en pourcentage (0-100).
  final int minScore;
  final bool showScore;
  final bool published;
  final int questionCount;
  final int totalPoints;
}
