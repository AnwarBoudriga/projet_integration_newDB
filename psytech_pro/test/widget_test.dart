import 'package:flutter_test/flutter_test.dart';

import 'package:psytech_pro/entreprise_RH/core/models/invitation_model.dart';

void main() {
  test('statuts d’invitation API -> libellés', () {
    expect(InvitationModel.statusLabel('en_cours'), 'En cours');
    expect(InvitationModel.statusLabel('termine'), 'Terminé');
    expect(InvitationModel.statusLabel('expire'), 'Expiré');
    expect(InvitationModel.statusLabel('invite'), 'Invité');
  });
}
