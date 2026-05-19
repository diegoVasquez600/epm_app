import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epm_app/main.dart';

Future<void> waitForFinder(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('No se encontro el widget esperado.');
}

Future<void> tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text, skipOffstage: false).first;
  await waitForFinder(tester, finder);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

void tapBottomTabByLabel(WidgetTester tester, String label) {
  final labelFinder = find.descendant(
    of: find.byType(BottomTabs),
    matching: find.text(label, skipOffstage: false),
  );
  expect(labelFinder, findsOneWidget);

  final tapTarget = find.ancestor(of: labelFinder, matching: find.byType(InkWell)).first;
  final inkWell = tester.widget<InkWell>(tapTarget);
  inkWell.onTap?.call();
}

void main() {
  testWidgets('Dashboard principal renderiza correctamente', (tester) async {
    await tester.pumpWidget(const EpmPrototypeApp());
    await waitForFinder(tester, find.text('Hola, Ana!'));

    expect(find.text('Hola, Ana!'), findsOneWidget);
    expect(find.text('Consumo actual\nMayo 2026'), findsOneWidget);
    expect(find.text('Pagar ahora'), findsOneWidget);
  });

  testWidgets('Historial permite ver 2025 y 2026', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    tapBottomTabByLabel(tester, 'Consumos');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Historial de consumo'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('Servicios abre modulo de alertas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    tapBottomTabByLabel(tester, 'Servicios');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Todo lo que necesitas para gestionar\ntus servicios de forma facil y inteligente'), findsOneWidget);
    final alertFinder = find.text('Alertas de consumo', skipOffstage: false).first;
    final alertTapTarget = find.ancestor(of: alertFinder, matching: find.byType(InkWell)).first;
    final alertInkWell = tester.widget<InkWell>(alertTapTarget);
    alertInkWell.onTap?.call();
    await tester.pumpAndSettle();

    expect(find.text('Modulo EPM'), findsOneWidget);
    expect(find.text('Alertas de consumo'), findsOneWidget);
  });

  testWidgets('Pago simulado muestra confirmacion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    final payButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Pagar ahora').first,
    );
    payButton.onPressed?.call();
    await tester.pump();
    expect(find.text('Procesando pago...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pago exitoso'), findsOneWidget);
    expect(find.textContaining('Comprobante:'), findsOneWidget);
  });
}
