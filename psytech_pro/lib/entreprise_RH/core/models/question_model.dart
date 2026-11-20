class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.testId,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.points,
    this.fromBank = false,
  });

  static const List<String> letters = ['A', 'B', 'C', 'D'];

  /// API: question d'un test ou de la banque
  /// { id, enonce, optionA..D, reponseCorrecte, points, source }.
  factory QuestionModel.fromJson(Map<String, dynamic> j, {String testId = ''}) {
    final index = letters.indexOf('${j['reponseCorrecte']}');
    return QuestionModel(
      id: '${j['id']}',
      testId: testId,
      text: '${j['enonce'] ?? ''}',
      options: [
        '${j['optionA'] ?? ''}',
        '${j['optionB'] ?? ''}',
        '${j['optionC'] ?? ''}',
        '${j['optionD'] ?? ''}',
      ],
      correctIndex: index < 0 ? 0 : index,
      points: (j['points'] as num?)?.toInt() ?? 1,
      fromBank: j['source'] == 'banque',
    );
  }

  final String id;

  /// Vide pour une question de la banque.
  final String testId;
  final String text;
  final List<String> options;
  final int correctIndex;
  final int points;

  /// Question du Super Administrateur (non modifiable par l'entreprise).
  final bool fromBank;

  String get correctLabel => letters[correctIndex];

  String optionLabel(int index) => '${letters[index]}. ${options[index]}';

  /// Corps attendu par POST / PUT .../questions.
  Map<String, dynamic> toPayload() => {
        'enonce': text,
        'optionA': options[0],
        'optionB': options[1],
        'optionC': options[2],
        'optionD': options[3],
        'reponseCorrecte': correctLabel,
        'points': points,
      };

  QuestionModel copyWith({
    String? id,
    String? testId,
    String? text,
    List<String>? options,
    int? correctIndex,
    int? points,
    bool? fromBank,
  }) =>
      QuestionModel(
        id: id ?? this.id,
        testId: testId ?? this.testId,
        text: text ?? this.text,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
        points: points ?? this.points,
        fromBank: fromBank ?? this.fromBank,
      );
}
