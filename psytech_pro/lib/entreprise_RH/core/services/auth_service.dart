import 'api_client.dart';
import 'data_store.dart';

/// Authentification Entreprise: POST /api/entreprise/auth/login { cle: "ENT-XXXXXXXX" }.
class AuthService {
  /// Retourne le nom de l'entreprise. Lève [ApiException] si la clé est refusée
  /// (invalide, entreprise désactivée, trop de tentatives, serveur injoignable).
  Future<String> loginWithCompanyKey(String key) async {
    final data = await ApiClient.instance
        .post('/entreprise/auth/login', body: {'cle': key.trim()});
    ApiClient.instance.setToken(data['token'] as String);
    DataStore.instance.reset();
    final entreprise = data['entreprise'] as Map<String, dynamic>;
    final nom = '${entreprise['nom']}';
    DataStore.instance.entrepriseNom = nom;
    return nom;
  }

  void logout() {
    ApiClient.instance.setToken(null);
    DataStore.instance.reset();
  }
}
