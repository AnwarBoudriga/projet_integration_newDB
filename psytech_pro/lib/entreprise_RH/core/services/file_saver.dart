// Enregistrement d'un fichier téléchargé (export CSV / PDF):
// - Web (Chrome): déclenche le téléchargement du navigateur.
// - Windows / macOS / Linux / mobile: écrit dans le dossier « Téléchargements » (ou le dossier temporaire).
export 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart';
