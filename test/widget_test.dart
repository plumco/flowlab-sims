import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:huliot_sims/main.dart';
import 'package:huliot_sims/providers/simulator_provider.dart';

void main() {
  testWidgets('Huliot Simulators loads dashboard successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SimulatorProvider(),
        child: const HuliotSimulatorsApp(),
      ),
    );

    // Verify brand header and active simulator button are rendered
    expect(find.text('HULIOT FLOWLAB'), findsOneWidget);
    expect(find.text('Flush'), findsOneWidget);
  });
}
