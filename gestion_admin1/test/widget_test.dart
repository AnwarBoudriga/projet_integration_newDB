import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_admin/core/api.dart';

void main() {
  test('URL de l’API par défaut', () {
    expect(Api.baseUrl, isNotEmpty);
  });
}
