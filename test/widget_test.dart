import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:huliot_sims/main.dart';
import 'package:huliot_sims/providers/simulator_provider.dart';

void main() {
  testWidgets('Huliot Simulators loads dashboard successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SimulatorProvider(),
        child: const HuliotSimulatorsApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify brand header and active simulator are rendered
    expect(find.text('HULIOT FLOWLAB'), findsOneWidget);
    expect(find.text('Run Test'), findsOneWidget);
  });
}
