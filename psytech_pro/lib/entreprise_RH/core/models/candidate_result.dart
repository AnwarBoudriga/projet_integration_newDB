class ResultLine {
  const ResultLine({
    required this.question,
    required this.chosen,
    required this.correct,
    required this.earned,
    required this.points,
  });

  /// API: élément de `questions` dans GET /api/entreprise/resultats/:invitationId.
  factory ResultLine.fromJson(Map<String, dynamic> j) {
    final options = (j['options'] as Map?) ?? const {};
    String label(dynamic letter) {
      if (letter == null) return 'Sans réponse';
      return '$letter. ${options[letter] ?? ''}';
    }

    return ResultLine(
      question: '${j['enonce'] ?? ''}',
      chosen: label(j['reponseCandidat']),
      correct: label(j['reponseCorrecte']),
      earned: (j['pointsObtenus'] as num?)?.toInt() ?? 0,
      points: (j['points'] as num?)?.toInt() ?? 0,
    );
  }

  final String question;
  final String chosen;
  final String correct;
  final int earned;
  final int points;
}

class CandidateResult {
  const CandidateResult({
    required this.invitationId,
    required this.candidate,
    required this.email,
    required this.testTitle,
    required this.score,
    required this.total,
    required this.percent,
    required this.passed,
    this.lines = const [],
  });

  /// API: GET /api/entreprise/resultats (liste) ou /resultats/:invitationId (détail + questions).
  factory CandidateResult.fromJson(Map<String, dynamic> j) => CandidateResult(
        invitationId: '${j['invitationId']}',
        candidate: '${j['candidat'] ?? ''}',
        email: '${j['email'] ?? ''}',
        testTitle: '${j['test'] ?? ''}',
        score: (j['score'] as num?)?.toInt() ?? 0,
        total: (j['scoreMax'] as num?)?.toInt() ?? 0,
        percent: (j['pourcentage'] as num?)?.toDouble() ?? 0,
        passed: j['reussi'] == true,
        lines: [
          for (final q in (j['questions'] as List? ?? const []))
            ResultLine.fromJson(Map<String, dynamic>.from(q as Map)),
        ],
      );

  final String invitationId;
  final String candidate;
  final String email;
  final String testTitle;
  final int score;
  final int total;
  final double percent;
  final bool passed;

  /// Vide dans la liste; rempli par le détail.
  final List<ResultLine> lines;
}
