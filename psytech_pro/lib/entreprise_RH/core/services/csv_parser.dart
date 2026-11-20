import '../utils/validators.dart';

class CsvRow {
  const CsvRow(this.name, this.email);

  final String name;
  final String email;
}

class CsvParseResult {
  const CsvParseResult(this.rows, this.skipped);

  final List<CsvRow> rows;
  final int skipped;
}

/// Lit un CSV « nom,email » (séparateur , ou ;, en-tête facultatif).
class CsvParser {
  CsvParser._();

  static CsvParseResult parse(String content) {
    final lines = content
        .replaceAll('\uFEFF', '')
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final rows = <CsvRow>[];
    var skipped = 0;
    for (var i = 0; i < lines.length; i++) {
      final parts = lines[i]
          .split(RegExp(r'[;,]'))
          .map((p) => p.trim().replaceAll('"', ''))
          .toList();
      if (i == 0 && parts.any((p) => p.toLowerCase() == 'email')) continue;
      if (parts.length < 2 || parts[0].isEmpty || !Validators.isEmail(parts[1])) {
        skipped++;
        continue;
      }
      rows.add(CsvRow(parts[0], parts[1]));
    }
    return CsvParseResult(rows, skipped);
  }
}
