import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../registry/simulator_hub_registry.dart';
import '../theme/app_colors.dart';
import '../../providers/simulator_provider.dart';
import '../../screens/dashboard_screen.dart';
import '../../widgets/app_drawer.dart';

/// Top-level shell that hosts the Huliot Engineering Simulator Suite.
///
/// Dispatches dynamically to whichever simulator module is selected,
/// while guaranteeing complete isolation and zero regression for existing simulators.
class SimulatorHubScreen extends StatelessWidget {
  const SimulatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SimulatorProvider provider = Provider.of<SimulatorProvider>(context);
    final String currentId = provider.currentSimulator.id;

    // Single Stack FlowLab maintains its dedicated full-featured dashboard & CAD visualizer
    if (currentId == 'sunken-swept-tee') {
      return const DashboardScreen();
    }

    final module = SimulatorHubRegistry.findModule(currentId) ??
        SimulatorHubRegistry.getModule('sunken-swept-tee');

    final bool isDark = provider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Browse All Simulators',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(module.meta.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.meta.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    module.meta.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Quick 1-click return to FlowLab Single Stack
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () => provider.selectSimulator('sunken-swept-tee'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.waves_rounded, size: 15, color: AppColors.accent),
              label: const Text(
                'Back to FlowLab',
                style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Toggle Theme',
            onPressed: provider.toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(provider: provider),
      body: module.buildView(context),
    );
  }
}
