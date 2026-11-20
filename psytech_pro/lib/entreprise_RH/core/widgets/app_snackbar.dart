import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_client.dart';

/// Messages de confirmation (turquoise) et d'erreur (rouge).
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.turquoise);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error);

  static void _show(BuildContext context, String message, Color color) {
    final wide = MediaQuery.of(context).size.width > 520;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        width: wide ? 440 : null,
        margin: wide ? null : const EdgeInsets.all(16),
        content: Text(message),
      ),
    );
  }
}

/// Exécute [action]; si elle échoue, affiche le message d'erreur de l'API dans un snackbar rouge.
/// Retourne true si l'action a réussi.
Future<bool> runGuarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) AppSnackbar.error(context, e.message);
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.error(context, 'Une erreur inattendue est survenue.');
    }
  }
  return false;
}
