import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/dialog_pointer_events_observer.dart';
import 'providers/simulator_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulatorProvider(),
      child: const HuliotSimulatorsApp(),
    ),
  );
}

class HuliotSimulatorsApp extends StatelessWidget {
  const HuliotSimulatorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SimulatorProvider provider = Provider.of<SimulatorProvider>(context);

    return MaterialApp(
      title: 'Huliot Simulators — Engineering FlowLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      navigatorObservers: [DialogPointerEventsObserver()],
      home: const DashboardScreen(),
    );
  }
}
