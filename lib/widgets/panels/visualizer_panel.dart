import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/simulator_provider.dart';
import '../visualizer/web_cad_view.dart';
import '../visualizer/drainage_stack_painter.dart';

class VisualizerPanel extends StatefulWidget {
  final SimulatorProvider provider;
  final bool isDarkMode;
  final bool isFullScreen;
  final VoidCallback? onToggleFullScreen;

  const VisualizerPanel({
    super.key,
    required this.provider,
    required this.isDarkMode,
    this.isFullScreen = false,
    this.onToggleFullScreen,
  });

  @override
  State<VisualizerPanel> createState() => _VisualizerPanelState();
}

class _VisualizerPanelState extends State<VisualizerPanel> with AutomaticKeepAliveClientMixin {
  static const String _activeRenderer = 'exact-html';
  bool _useFullHtmlPage = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final SimulatorProvider prov = widget.provider;
    final String srcUrl = _useFullHtmlPage
        ? 'sims/sunken-swept-tee.html'
        : 'sims/visualizer-embedded.html';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Visualizer Top Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: widget.isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.architecture_rounded, size: 17, color: AppColors.accent),
                const SizedBox(width: 6),
                const Text(
                  '3-System CAD Visualizer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '100% Identical to CAD Sheet',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
                const Spacer(),

                // Toggle Full HTML vs Embedded
                Tooltip(
                  message: _useFullHtmlPage ? 'Switch to Embedded CAD Sheet' : 'Switch to Full Original HTML Studio',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: widget.isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    icon: Icon(_useFullHtmlPage ? Icons.view_compact_rounded : Icons.auto_stories_rounded, size: 14),
                    label: Text(
                      _useFullHtmlPage ? 'CAD Sheet' : 'Full HTML Studio',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      setState(() {
                        _useFullHtmlPage = !_useFullHtmlPage;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Full Screen Toggle Button
                if (widget.onToggleFullScreen != null) ...[
                  Tooltip(
                    message: widget.isFullScreen ? 'Exit Full Screen (Restore Controls)' : 'Full Screen Visualizer',
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: widget.isFullScreen
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : (widget.isDarkMode ? AppColors.darkCard : AppColors.lightCard),
                      ),
                      icon: Icon(
                        widget.isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        size: 16,
                        color: widget.isFullScreen ? AppColors.accent : (widget.isDarkMode ? AppColors.darkText : AppColors.lightText),
                      ),
                      label: Text(
                        widget.isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.isFullScreen ? AppColors.accent : (widget.isDarkMode ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                      onPressed: widget.onToggleFullScreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),

          // Main Visualizer Body (Full Height)
          Expanded(
            child: Container(
              color: const Color(0xFF000000), // Black CAD background
              child: _activeRenderer == 'exact-html' && kIsWeb
                  ? buildCadPlatformView(
                      src: srcUrl,
                      viewId: _useFullHtmlPage ? 'full-cad-studio-view' : 'embedded-cad-view',
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: DrainageStackPainter(
                            params: prov.params,
                            dynamicState: prov.currentDynamicState,
                            staticResult: prov.currentResult,
                            activeFloors: prov.activeFloors,
                            waterParticles: prov.waterParticles,
                            airParticles: prov.airParticles,
                            viewMode: 'fit',
                            isDarkMode: widget.isDarkMode,
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
