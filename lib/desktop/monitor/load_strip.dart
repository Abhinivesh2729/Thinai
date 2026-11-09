/// A compact live load readout: a tiny CPU trace, CPU % and Thinai's memory.
/// Sits in the chat header while a reply streams and in the Lab header.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/desk_theme.dart';
import 'load_monitor.dart';

String formatBytes(int bytes) {
  final gb = bytes / (1024 * 1024 * 1024);
  if (gb >= 1) return '${gb.toStringAsFixed(gb >= 10 ? 0 : 1)} GB';
  return '${(bytes / (1024 * 1024)).round()} MB';
}

class LoadStrip extends ConsumerWidget {
  const LoadStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadMonitorProvider);
    final latest = state.latest;
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (latest == null) return const SizedBox.shrink();
    final style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 16,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MiniTracePainter(
                  values: [
                    for (final s in state.history.skip(
                      math.max(0, state.history.length - 30),
                    ))
                      s.cpu,
                  ],
                  color: DeskColors.mint,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('CPU ${(latest.cpu * 100).round()}%', style: style),
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: palette.hairline,
          ),
          Icon(Icons.memory_rounded, size: 13, color: palette.textMuted),
          const SizedBox(width: 4),
          Text(formatBytes(latest.appRss), style: style),
        ],
      ),
    );
  }
}

/// A small filled line of 0..1 values.
class MiniTracePainter extends CustomPainter {
  MiniTracePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i].clamp(0.0, 1.0));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(MiniTracePainter old) => true;
}
