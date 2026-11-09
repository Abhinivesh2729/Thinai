/// Small building blocks for the desktop Models page: chips, buttons, the
/// logo tile, live progress bars and the first-appearance entrance gate.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models_repo/catalog.dart';
import '../../../models_repo/downloader.dart';
import '../../../models_repo/model_store.dart';
import '../../../ui/widgets/model_brand_logo.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import 'models_common.dart';

// ─── entrance ───────────────────────────────────────────────────────────────

/// Decides which items get an entrance animation.
///
/// Only items that appear while the page is being revealed (first open, or a
/// filter change) animate, staggered in the order they are built. A card that
/// scrolls back into view was already seen and appears instantly, so
/// scrolling never replays the entrance.
class EntranceGate {
  final _seen = <String>{};
  DateTime _openUntil = DateTime.now().add(_window);
  int _batch = 0;

  static const _window = Duration(milliseconds: 650);
  static const _step = Duration(milliseconds: 32);

  void reveal() {
    _seen.clear();
    _openUntil = DateTime.now().add(_window);
    _batch = 0;
  }

  /// Delay before [key] animates in, or null to show it at once.
  Duration? claim(String key) {
    if (!_seen.add(key)) return null;
    if (DateTime.now().isAfter(_openUntil)) return null;
    return _step * math.min(_batch++, 10);
  }
}

/// Wraps [child] in an [EnterAnimation] when [gate] says so. The decision is
/// made once, in initState, so a rebuild never swaps the subtree mid-flight.
class GatedEntrance extends StatefulWidget {
  const GatedEntrance({
    super.key,
    required this.gate,
    required this.id,
    required this.child,
  });

  final EntranceGate gate;
  final String id;
  final Widget child;

  @override
  State<GatedEntrance> createState() => _GatedEntranceState();
}

class _GatedEntranceState extends State<GatedEntrance> {
  late final Duration? _delay = widget.gate.claim(widget.id);

  @override
  Widget build(BuildContext context) {
    final delay = _delay;
    if (delay == null) return widget.child;
    return EnterAnimation(
      delay: delay,
      duration: DeskMotion.page,
      offset: const Offset(0, 0.06),
      child: widget.child,
    );
  }
}

// ─── chips ──────────────────────────────────────────────────────────────────

class SpecChip extends StatelessWidget {
  const SpecChip({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;

  /// Tints the chip; neutral when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final tint = color;
    final fg = tint ?? palette.textMuted;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tint == null
            ? palette.hairline.withValues(alpha: palette.isDark ? 0.55 : 0.6)
            : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DeskSize.radiusS - 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The few facts a card shows; everything else is in the details dialog.
List<Widget> cardChips(
  CatalogModel model,
  AppLocalizations l, {
  required bool tightFit,
}) {
  final tag = capabilityTag(model, l);
  final showTag =
      tag.$2 == l.modelsCapVisionReady || tag.$2 == l.modelsCapMultilingual;
  return [
    SpecChip(label: model.parameters, icon: Icons.bolt_rounded),
    if (model.dimensions != null)
      SpecChip(
        label: l.modelsDimensions('${model.dimensions}'),
        icon: Icons.scatter_plot_rounded,
      )
    else
      SpecChip(
        label: '${model.contextLabel} ctx',
        icon: Icons.receipt_long_outlined,
      ),
    if (showTag) SpecChip(label: tag.$2, icon: tag.$1),
    if (tightFit)
      SpecChip(
        label: l.modelsFitTightShort,
        icon: Icons.warning_amber_rounded,
        color: DeskColors.amber,
      ),
  ];
}

// ─── buttons ────────────────────────────────────────────────────────────────

enum DeskButtonStyle { filled, outlined, quiet, danger }

/// A compact pill button with a hover lift in colour, sized for cards.
class DeskButton extends StatelessWidget {
  const DeskButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = DeskButtonStyle.filled,
    this.height = 34,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DeskButtonStyle style;
  final double height;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;
    final green = palette.isDark ? DeskColors.green : DeskColors.greenDeep;

    return Hoverable(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      builder: (context, hovered) {
        final (bg, fg, border) = switch (style) {
          DeskButtonStyle.filled => (
            hovered && enabled ? DeskColors.greenDeep : DeskColors.green,
            Colors.white,
            Colors.transparent,
          ),
          DeskButtonStyle.outlined => (
            hovered && enabled
                ? green.withValues(alpha: 0.10)
                : Colors.transparent,
            green,
            green.withValues(alpha: 0.55),
          ),
          DeskButtonStyle.quiet => (
            hovered && enabled
                ? scheme.onSurface.withValues(alpha: 0.08)
                : scheme.onSurface.withValues(alpha: 0.04),
            scheme.onSurface,
            palette.hairline,
          ),
          DeskButtonStyle.danger => (
            hovered && enabled
                ? DeskColors.danger.withValues(alpha: 0.12)
                : Colors.transparent,
            DeskColors.danger,
            DeskColors.danger.withValues(alpha: 0.45),
          ),
        };
        return GestureDetector(
          onTap: enabled ? onPressed : null,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            curve: DeskMotion.ease,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: border),
              boxShadow: style == DeskButtonStyle.filled && hovered && enabled
                  ? [
                      BoxShadow(
                        color: DeskColors.green.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Opacity(
              opacity: onPressed == null ? 0.5 : 1,
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 16, color: fg),
                  if (busy || icon != null) const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A non-interactive status pill ("Installed", "Needs RAM", "In use").
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final c = color ?? palette.textMuted;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: c.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── logo ───────────────────────────────────────────────────────────────────

/// The model's brand mark on a soft tile tinted by its vendor.
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.model, this.local, this.size = 44});

  final CatalogModel? model;
  final LocalModel? local;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final catalog = model ?? (local == null ? null : catalogFor(local!));
    final tint = catalog == null ? DeskColors.green : vendorColor(catalog);
    final logoSize = size * 0.58;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: palette.isDark ? 0.10 : 0.07),
          palette.panelRaised,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: catalog != null
          ? ModelBrandLogo.catalog(model: catalog, size: logoSize)
          : ModelBrandLogo.local(model: local!, size: logoSize),
    );
  }
}

// ─── progress ───────────────────────────────────────────────────────────────

/// Last progress seen per download. The handle's stream is broadcast, so a
/// bar built mid-download (a card scrolled into view, the manager opened)
/// would otherwise read "Starting…" until the next tick.
final _lastProgress = Expando<DownloadProgress>();

/// A thin bar whose fill glides between progress ticks instead of jumping.
class SmoothBar extends StatelessWidget {
  const SmoothBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  /// Null for indeterminate.
  final double? value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final c = color ?? DeskColors.green;
    final track = palette.hairline;
    final v = value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: v == null
            ? LinearProgressIndicator(
                minHeight: height,
                color: c,
                backgroundColor: track,
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(end: v.clamp(0.0, 1.0)),
                duration: DeskMotion.medium,
                curve: DeskMotion.ease,
                builder: (context, t, _) => CustomPaint(
                  painter: _BarPainter(t, c, track),
                  size: Size.infinite,
                ),
              ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.t, this.color, this.track);
  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = track,
    );
    if (t <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * t, size.height),
        r,
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [color, Color.lerp(color, DeskColors.mint, 0.45)!],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.t != t || old.color != color || old.track != track;
}

/// "42% · 310 MB / 740 MB" over a smooth bar, fed straight from the
/// download's stream so only this widget rebuilds per tick.
class LiveProgress extends StatelessWidget {
  const LiveProgress({super.key, required this.handle, this.title});

  final DownloadHandle handle;

  /// Shown on the left instead of the percentage (the manager uses names).
  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final l = context.l10n;
    return RepaintBoundary(
      child: StreamBuilder<DownloadProgress>(
        initialData: _lastProgress[handle],
        stream: handle.progress,
        builder: (context, snap) {
          final p = snap.data;
          if (p != null) _lastProgress[handle] = p;
          final fraction = p?.fraction;
          final failed = p?.done == true && p?.error != null;
          final percent = fraction == null
              ? l.modelsStatusStarting
              : '${(fraction * 100).toStringAsFixed(0)}%';
          final size = p == null
              ? ''
              : (p.total ?? 0) > 0
              ? '${fmtSize(p.received)} / ${fmtSize(p.total!)}'
              : p.received > 0
              ? fmtSize(p.received)
              : '';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (title != null) ...[
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    failed ? l.modelsStatusFailed : percent,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: failed ? DeskColors.danger : DeskColors.green,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (title == null) const Spacer(),
                  if (size.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      size,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              SmoothBar(
                value: fraction,
                color: failed ? DeskColors.danger : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What a paused download left on disk: a dimmed bar and how much is saved.
class PausedProgress extends StatelessWidget {
  const PausedProgress({super.key, required this.partial, this.title});

  final PartialDownload partial;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final l = context.l10n;
    final f = partial.fraction;
    final total = partial.total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 14,
              color: palette.textMuted,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title ??
                    (f == null
                        ? l.modelsPaused
                        : l.modelsPausedPercent((f * 100).toStringAsFixed(0))),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: title == null ? palette.textMuted : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total != null
                  ? '${fmtSize(partial.bytes)} / ${fmtSize(total)}'
                  : fmtSize(partial.bytes),
              style: TextStyle(fontSize: 11.5, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SmoothBar(
          value: f ?? 0,
          color: DeskColors.green.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

// ─── section header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: DeskColors.green),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: palette.hairline)),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
