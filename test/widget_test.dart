import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epm_app/main.dart';

void main() {
  testWidgets('Dashboard principal renderiza correctamente', (tester) async {
    await tester.pumpWidget(const EpmPrototypeApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Hola, Ana!'), findsOneWidget);
    expect(find.text('Consumo actual\nMayo 2026'), findsOneWidget);
    expect(find.text('Pagar ahora'), findsOneWidget);
  });

  testWidgets('Historial permite ver 2025 y 2026', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    await tester.tap(find.text('Consumos'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Historial de consumo'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('Servicios abre modulo de alertas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    await tester.tap(find.text('Servicios'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Modulos principales'), findsOneWidget);
    await tester.tap(find.text('Alertas de consumo').first);
    await tester.pumpAndSettle();

    expect(find.text('Modulo EPM'), findsOneWidget);
    expect(find.text('Alertas de consumo'), findsOneWidget);
  });

  testWidgets('Pago simulado muestra confirmacion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EpmMainShell(data: AppData.prototypeFallback())),
    );

    await tester.tap(find.text('Pagar ahora'));
    await tester.pump();
    expect(find.text('Procesando pago...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pago exitoso'), findsOneWidget);
    expect(find.textContaining('Comprobante:'), findsOneWidget);
  });
}
