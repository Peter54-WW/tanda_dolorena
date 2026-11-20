import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanda_dolorena/presentation/tanda_screen.dart';

Future<void> _completarRonda(WidgetTester tester) async {
  while (find.text('Aportar').evaluate().isNotEmpty) {
    await tester.tap(find.text('Aportar').first);
    await tester.pump();
  }
  await tester.tap(find.text('Cerrar ronda y entregar turno'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cerrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la ronda 1 y a los 4 vecinos', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TandaScreen()));
    expect(find.text('Ronda actual: 1 de 4'), findsOneWidget);
    expect(find.text('Aportar'), findsNWidgets(4));
  });

  testWidgets('cerrar sin que todos aporten muestra aviso', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TandaScreen()));
    await tester.tap(find.text('Cerrar ronda y entregar turno'));
    await tester.pump();
    expect(find.text('Todavia faltan vecinos por aportar.'), findsOneWidget);
  });

  testWidgets('al cerrar la ronda revela al beneficiario', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TandaScreen()));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Aportar').first);
      await tester.pump();
    }
    await tester.tap(find.text('Cerrar ronda y entregar turno'));
    await tester.pumpAndSettle();
    expect(find.text('Le toco a Ana esta ronda!'), findsOneWidget);
  });

  testWidgets('la pantalla no truena cuando la tanda termina', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TandaScreen()));
    for (var i = 0; i < 4; i++) {
      await _completarRonda(tester);
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Tanda terminada'), findsOneWidget);
  });
}
