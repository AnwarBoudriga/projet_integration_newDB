import 'dart:io';
import 'dart:typed_data';

/// Écrit [bytes] dans « Téléchargements » (sinon dossier temporaire). Retourne le chemin complet.
Future<String> saveFile(String fileName, Uint8List bytes, String mimeType) async {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  Directory dir = Directory.systemTemp;
  if (home != null) {
    final downloads = Directory('$home${Platform.pathSeparator}Downloads');
    if (await downloads.exists()) dir = downloads;
  }
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
