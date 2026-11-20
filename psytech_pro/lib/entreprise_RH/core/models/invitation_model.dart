class InvitationModel {
  const InvitationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.testId,
    required this.testTitle,
    required this.expiresAt,
    this.key,
    this.status = 'Invité',
  });

  /// API: GET /api/entreprise/invitations
  /// { id, nom, email, testId, test, expiration, statut: invite|en_cours|termine|expire }.
  factory InvitationModel.fromJson(Map<String, dynamic> j) => InvitationModel(
        id: '${j['id']}',
        name: '${j['nom'] ?? ''}',
        email: '${j['email'] ?? ''}',
        testId: '${j['testId']}',
        testTitle: '${j['test'] ?? ''}',
        expiresAt:
            DateTime.tryParse('${j['expiration']}')?.toLocal() ?? DateTime.now(),
        status: statusLabel('${j['statut']}'),
      );

  static String statusLabel(String api) {
    switch (api) {
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminé';
      case 'expire':
        return 'Expiré';
      default:
        return 'Invité';
    }
  }

  final String id;
  final String name;
  final String email;
  final String testId;
  final String testTitle;
  final DateTime expiresAt;

  /// Clé en clair: connue uniquement juste après la création (le serveur ne stocke qu'un hash).
  final String? key;

  /// « Invité », « En cours », « Terminé » ou « Expiré » (calculé par le serveur).
  final String status;

  String get displayStatus => status;
}
