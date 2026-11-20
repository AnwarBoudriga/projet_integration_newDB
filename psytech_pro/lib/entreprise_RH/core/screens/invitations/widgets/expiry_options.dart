import '../../../widgets/custom_dropdown.dart';

/// Valeur = nombre de jours de validité de la clé.
const List<DropdownItem<int>> expiryOptions = [
  DropdownItem<int>(1, '24 heures'),
  DropdownItem<int>(3, '3 jours'),
  DropdownItem<int>(7, '7 jours'),
  DropdownItem<int>(30, '30 jours'),
];
