/// Lab > Load: live CPU, memory, power and battery, what each model costs,
/// and Thinai's energy and carbon footprint this session.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/load_strings.dart';
import '../../monitor/load_monitor.dart';
import '../../monitor/load_strip.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'lab_common.dart';

class LabLoadTab extends ConsumerWidget {
  const LabLoadTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = LoadStrings.of(context);
    final state = ref.watch(loadMonitorProvider);
    final latest = state.latest;
    const gap = SizedBox(width: 16, height: 16);

    final tiles = LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 4 : 2;
        final w = (c.maxWidth - 16 * (columns - 1)) / columns;
        final battery = latest?.batteryPercent;
        final drained = battery != null && state.batteryAtStart != null
            ? state.batteryAtStart! - battery
            : null;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _Tile(
              width: w,
              icon: Icons.developer_board_rounded,
              label: s.cpu,
              value: latest == null ? 0 : latest.cpu * 100,
              unit: '%',
              fraction: latest?.cpu ?? 0,
              secondaryFraction: latest?.appCpu ?? 0,
              detail: latest == null
                  ? ''
                  : '${s.cpuThinai} ${(latest.appCpu * 100).round()}%',
            ),
            _Tile(
              width: w,
              icon: Icons.memory_rounded,
              label: s.memory,
              value: latest == null || latest.ramTotal == 0
                  ? 0
                  : latest.ramUsed / (1024 * 1024 * 1024),
              unit: latest == null || latest.ramTotal == 0
                  ? 'GB'
                  : '/ ${formatBytes(latest.ramTotal)}',
              decimals: 1,
              fraction: latest == null || latest.ramTotal == 0
                  ? 0
                  : latest.ramUsed / latest.ramTotal,
              secondaryFraction: latest == null || latest.ramTotal == 0
                  ? 0
                  : latest.appRss / latest.ramTotal,
              detail: latest == null
                  ? ''
                  : '${s.memoryThinai} ${formatBytes(latest.appRss)}',
            ),
            _Tile(
              width: w,
              icon: Icons.bolt_rounded,
              label: s.power,
              value: latest?.watts ?? 0,
              unit: 'W',
              decimals: 1,
              fraction: ((latest?.watts ?? 0) / 60).clamp(0.0, 1.0),
              secondaryFraction: ((latest?.appWatts ?? 0) / 60).clamp(0.0, 1.0),
              detail: latest == null
                  ? ''
                  : '${latest.wattsMeasured ? s.measured : s.estimated} · '
                        '${s.cpuThinai} ${latest.appWatts.toStringAsFixed(1)} W',
            ),
            _Tile(
              width: w,
              icon: latest?.onBattery == false
                  ? Icons.battery_charging_full_rounded
                  : Icons.battery_std_rounded,
              label: s.battery,
              value: (battery ?? 0).toDouble(),
              unit: battery == null ? '' : '%',
              missing: battery == null,
              fraction: (battery ?? 0) / 100,
              detail: battery == null
                  ? s.noBattery
                  : latest?.onBattery == false
                  ? s.pluggedIn
                  : drained == null || drained <= 0
                  ? s.sinceOpened
                  : '−$drained% ${s.sinceOpened}',
            ),
          ],
        );
      },
    );

    final live = LabCard(
      title: s.liveTitle,
      icon: Icons.monitor_heart_outlined,
      height: 250,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Legend(
            color: DeskPalette.of(context).textFaint,
            label: s.liveLegendSystem,
          ),
          const SizedBox(width: 12),
          _Legend(color: DeskColors.green, label: s.liveLegendThinai),
          const SizedBox(width: 12),
          _Legend(color: DeskColors.amber, label: s.liveLegendRam),
        ],
      ),
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          // Re-runs on every sample so the chart slides rather than jumps.
          key: ValueKey(
            state.history.length + (latest?.at.millisecondsSinceEpoch ?? 0),
          ),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.linear,
          builder: (context, t, _) => CustomPaint(
            size: Size.infinite,
            painter: _LiveChart(
              history: state.history,
              shift: t,
              grid: DeskPalette.of(context).hairline,
              system: DeskPalette.of(context).textFaint,
            ),
          ),
        ),
      ),
    );

    final models = state.models.values.toList()
      ..sort((a, b) => b.energyJ.compareTo(a.energyJ));
    final maxEnergy = models.isEmpty
        ? 1.0
        : math.max(1e-6, models.map((m) => m.energyJ).reduce(math.max));

    final table = LabCard(
      title: s.modelsTitle,
      icon: Icons.leaderboard_rounded,
      child: models.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                s.modelsEmpty,
                style: TextStyle(
                  fontSize: 13,
                  color: DeskPalette.of(context).textMuted,
                ),
              ),
            )
          : Column(
              children: [
                _Row(
                  header: true,
                  cells: [
                    s.colModel,
                    s.colTime,
                    s.colTokens,
                    s.colCpu,
                    s.colRam,
                    s.colEnergy,
                    s.colCo2,
                  ],
                ),
                for (var i = 0; i < models.length; i++)
                  EnterAnimation(
                    delay: Duration(milliseconds: 50 * i),
                    child: _Row(
                      cells: [
                        models[i].model.replaceAll('.gguf', ''),
                        _duration(models[i].active),
                        '${models[i].tokens}${models[i].tokensPerSecond == null ? '' : ' · ${models[i].tokensPerSecond!.toStringAsFixed(1)}/s'}',
                        '${(models[i].avgCpu * 100).round()}%',
                        formatBytes(models[i].peakRss),
                        '${(models[i].wh * 1000).toStringAsFixed(models[i].wh < 0.1 ? 1 : 0)} mWh',
                        '${models[i].co2g.toStringAsFixed(2)} g',
                      ],
                      bar: models[i].energyJ / maxEnergy,
                    ),
                  ),
              ],
            ),
    );

    final wh = state.sessionEnergyJ / 3600;
    // A phone battery holds about 12 Wh.
    final phonePct = wh / 12 * 100;
    final footprint = LabCard(
      title: s.footprintTitle,
      icon: Icons.eco_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _BigNumber(
                  label: s.footprintEnergy,
                  value: wh * 1000,
                  unit: 'mWh',
                  decimals: wh < 0.1 ? 1 : 0,
                ),
              ),
              Expanded(
                child: _BigNumber(
                  label: s.footprintCo2,
                  value: state.sessionCo2g,
                  unit: 'g CO₂',
                  decimals: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.phoneCharge(
              phonePct < 1
                  ? phonePct.toStringAsFixed(2)
                  : phonePct.toStringAsFixed(1),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DeskColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.method,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: DeskPalette.of(context).textFaint,
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      children: [
        EnterAnimation(child: tiles),
        gap,
        EnterAnimation(delay: const Duration(milliseconds: 60), child: live),
        gap,
        EnterAnimation(
          delay: const Duration(milliseconds: 120),
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: table),
                      gap,
                      Expanded(flex: 3, child: footprint),
                    ],
                  )
                : Column(children: [table, gap, footprint]),
          ),
        ),
      ],
    );
  }

  static String _duration(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.detail,
    this.secondaryFraction = 0,
    this.decimals = 0,
    this.missing = false,
  });

  /// No reading (e.g. a desktop without a battery): shows a dash.

  final double width;
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final double fraction;
  final double secondaryFraction;
  final String detail;
  final int decimals;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: LabCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: fraction.clamp(0.0, 1.0)),
                duration: DeskMotion.slow,
                curve: DeskMotion.ease,
                builder: (context, f, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: secondaryFraction.clamp(0.0, 1.0)),
                  duration: DeskMotion.slow,
                  curve: DeskMotion.ease,
                  builder: (context, f2, _) => CustomPaint(
                    painter: _Ring(
                      fraction: f,
                      inner: f2,
                      track: palette.hairline,
                    ),
                    child: Center(
                      child: Icon(icon, size: 20, color: DeskColors.green),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: value),
                    duration: DeskMotion.slow,
                    curve: DeskMotion.ease,
                    builder: (context, v, _) => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: missing ? '–' : v.toStringAsFixed(decimals),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: palette.textFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outer ring: the whole machine. Inner ring: Thinai's share.
class _Ring extends CustomPainter {
  _Ring({required this.fraction, required this.inner, required this.track});
  final double fraction;
  final double inner;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    const start = -math.pi / 2;
    void arc(double radius, double f, Color color, double width) {
      final rect = Rect.fromCircle(center: c, radius: radius);
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
      if (f <= 0.001) return;
      canvas.drawArc(
        rect,
        start,
        math.pi * 2 * f,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    arc(r, fraction, DeskColors.mint.withValues(alpha: 0.55), 5);
    arc(r - 8, inner, DeskColors.green, 4);
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.fraction != fraction || old.inner != inner || old.track != track;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          color: DeskPalette.of(context).textMuted,
        ),
      ),
    ],
  );
}

/// Two minutes of CPU (all apps, Thinai) and memory, sliding left smoothly
/// between samples.
class _LiveChart extends CustomPainter {
  _LiveChart({
    required this.history,
    required this.shift,
    required this.grid,
    required this.system,
  });

  final List<LoadSample> history;
  final double shift;
  final Color grid;
  final Color system;

  static const _window = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final points = history.length > _window
        ? history.sublist(history.length - _window)
        : history;
    if (points.length < 2) return;
    final step = size.width / (_window - 1);
    // Newest sample at the right edge; the curve slides one step per sample.
    double xAt(int i) =>
        size.width - (points.length - 1 - i) * step - step * (1 - shift) + step;

    Path line(double Function(LoadSample) v) {
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = xAt(i);
        final y = size.height * (1 - v(points[i]).clamp(0.0, 1.0));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final px = xAt(i - 1);
          final py = size.height * (1 - v(points[i - 1]).clamp(0.0, 1.0));
          final mx = (px + x) / 2;
          path.cubicTo(mx, py, mx, y, x, y);
        }
      }
      return path;
    }

    void area(Path p, Color color, double alpha) {
      final fill = Path.from(p)
        ..lineTo(xAt(points.length - 1), size.height)
        ..lineTo(xAt(0), size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    area(line((s) => s.cpu), system, 0.18);
    area(line((s) => s.appCpu), DeskColors.green, 0.35);
    final ram = line((s) => s.ramTotal == 0 ? 0 : s.ramUsed / s.ramTotal);
    canvas.drawPath(
      ram,
      Paint()
        ..color = DeskColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveChart old) => true;
}

class _Row extends StatelessWidget {
  const _Row({required this.cells, this.header = false, this.bar = 0});
  final List<String> cells;
  final bool header;
  final double bar;

  static const _flex = [5, 2, 3, 2, 2, 3, 2];

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: header ? 11.5 : 13,
      fontWeight: header ? FontWeight.w600 : FontWeight.w500,
      color: header ? palette.textFaint : scheme.onSurface,
      fontFeatures: tabularFigures,
    );
    return Hoverable(
      builder: (context, hovered) => AnimatedContainer(
        duration: DeskMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: hovered && !header
              ? scheme.onSurface.withValues(alpha: 0.04)
              : null,
          borderRadius: BorderRadius.circular(DeskSize.radiusS),
          border: header
              ? Border(bottom: BorderSide(color: palette.hairline))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < cells.length; i++)
                  Expanded(
                    flex: _flex[i],
                    child: Text(
                      cells[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                      style: style,
                    ),
                  ),
              ],
            ),
            if (!header) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: bar.clamp(0.0, 1.0)),
                  duration: DeskMotion.slow,
                  curve: DeskMotion.ease,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: palette.hairline,
                    valueColor: const AlwaysStoppedAnimation(DeskColors.green),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.label,
    required this.value,
    required this.unit,
    required this.decimals,
  });
  final String label;
  final double value;
  final String unit;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: palette.textMuted)),
        TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: DeskMotion.slow,
          builder: (context, v, _) => Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: v.toStringAsFixed(decimals),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFeatures: tabularFigures,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
