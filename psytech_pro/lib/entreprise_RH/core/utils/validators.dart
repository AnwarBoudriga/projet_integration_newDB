class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value,
      [String message = 'Ce champ est obligatoire.']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? positiveInt(String? value, String emptyMessage) {
    final r = required(value, emptyMessage);
    if (r != null) return r;
    final n = int.tryParse(value!.trim());
    if (n == null || n <= 0) return 'Saisissez un nombre entier supérieur à 0.';
    return null;
  }

  static String? percent(String? value, String emptyMessage) {
    final r = required(value, emptyMessage);
    if (r != null) return r;
    final n = int.tryParse(value!.trim());
    if (n == null || n < 0 || n > 100) {
      return 'Saisissez un nombre entre 0 et 100.';
    }
    return null;
  }

  static bool isEmail(String value) => _emailRegex.hasMatch(value.trim());

  static String? email(String? value) {
    final r = required(value, "L'email est obligatoire.");
    if (r != null) return r;
    return isEmail(value!) ? null : "Adresse email invalide.";
  }
}
