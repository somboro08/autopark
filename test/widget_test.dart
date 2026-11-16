import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autopark_mvp/main.dart';
import 'package:autopark_mvp/models/app_user.dart';
import 'package:autopark_mvp/models/parking_session.dart';

void main() {
  testWidgets('AutoPark démarre sur le splash puis la sélection de profil',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AutoParkApp());

    // L'écran de démarrage est affiché.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('AutoPark'), findsOneWidget);
    expect(find.text('Sécurisation des parkings motos'), findsOneWidget);

    // Après l'animation, l'app propose de choisir un profil.
    // (La base n'est pas disponible en test : l'écran affiche son état vide,
    // ce qui ne doit pas provoquer d'erreur.)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Qui utilise l\'application ?'), findsOneWidget);
  });

  test('Les rôles se convertissent correctement', () {
    expect(AppRole.fromStorage('agent'), AppRole.agent);
    expect(AppRole.fromStorage('owner'), AppRole.owner);
    expect(AppRole.fromStorage(null), AppRole.owner);
    expect(AppRole.agent.label, 'Agent de centre');
  });

  test('Le statut effectif bascule en « non récupéré » après le délai', () {
    final session = ParkingSession(
      vehicleId: 1,
      centerId: 1,
      entryTime: DateTime.now().subtract(const Duration(hours: 25)),
    );
    expect(session.effectiveStatus(24), SessionStatus.notRetrieved);
    expect(session.effectiveStatus(48), SessionStatus.active);

    final retrieved = session.copyWith(
      status: SessionStatus.retrieved,
      exitTime: DateTime.now(),
    );
    expect(retrieved.effectiveStatus(24), SessionStatus.retrieved);
  });
}
