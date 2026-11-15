import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/url_navigation.dart';
import '../../models/simulator_meta.dart';
import '../../providers/simulator_provider.dart';

class AppDrawer extends StatelessWidget {
  final SimulatorProvider provider;

  const AppDrawer({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = provider.isDarkMode;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HULIOT SIMULATORS',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                          ),
                          Text(
                            'Engineering Hub v2.0',
                            style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a simulator module to test hydraulic loads, acoustic ratings, and pressure relief systems.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Simulators List Grouped by Category
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _categorySection(
                    title: 'Drainage & Stack Hydraulics',
                    category: SimulatorCategory.drainage,
                    context: context,
                  ),
                  _categorySection(
                    title: 'Water Supply & Booster Pumps',
                    category: SimulatorCategory.waterSupply,
                    context: context,
                  ),
                  _categorySection(
                    title: 'Building Acoustics & Noise',
                    category: SimulatorCategory.acoustics,
                    context: context,
                  ),
                  _categorySection(
                    title: 'Rainwater & Siphonic Systems',
                    category: SimulatorCategory.siphonicRainwater,
                    context: context,
                  ),
                ],
              ),
            ),

            // Drawer Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modular Flutter Web Architecture. Easily add new simulators.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection({
    required String title,
    required SimulatorCategory category,
    required BuildContext context,
  }) {
    final List<SimulatorMeta> list = SimulatorRegistry.getByCategory(category);
    final bool isDark = provider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          ...list.map((sim) {
            final bool isSelected = provider.currentSimulator.id == sim.id;
            final bool isLive = sim.status == SimulatorStatus.live;

            return ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
              leading: Icon(
                sim.icon,
                color: isSelected ? AppColors.accent : (isLive ? (isDark ? Colors.white70 : Colors.black87) : Colors.grey),
                size: 20,
              ),
              title: Text(
                sim.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.accent : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
              subtitle: Text(
                sim.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.success.withValues(alpha: 0.18) : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLive ? 'LIVE' : 'COMING SOON',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isLive ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
              onTap: isLive
                  ? () {
                      provider.selectSimulator(sim.id);
                      Navigator.pop(context);
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
