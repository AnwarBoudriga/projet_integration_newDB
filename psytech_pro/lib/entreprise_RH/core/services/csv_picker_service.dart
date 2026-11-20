
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class PickedCsv {
  const PickedCsv(this.name, this.content);

  final String name;
  final String content;
}

class CsvPickerService {
  Future<PickedCsv?> pickCsv() async {
    // Sélection d'un seul fichier CSV
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (file == null) return null;

    // Lecture du contenu du fichier
    final bytes = await file.readAsBytes();

    return PickedCsv(
      file.name,
      utf8.decode(bytes, allowMalformed: true),
    );
  }
}
