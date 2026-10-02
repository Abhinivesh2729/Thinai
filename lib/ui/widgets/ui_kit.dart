/// Shared building blocks for every screen.
///
/// Each page used to draw its own cards, headers, chips and snack bars, each
/// with slightly different radii, greys and type sizes. These are the one
/// version of each, built on the tokens in `theme/app_theme.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

// ─── feedback ──────────────────────────────────────────────────────────────

/// Shows a short message at the bottom of the screen.
///
/// Replaces whatever message is already showing rather than queueing behind
/// it: a stale "Web search off." still on screen four seconds after it was
/// turned back on is worse than no message at all.
void showToast(BuildContext context, String text, {Duration? duration}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
}

/// Copies [text] and confirms it with [message].
Future<void> copyWithToast(
  BuildContext context,
  String text, {
  String message = 'Copied',
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, message);
}

/// Asks before doing something. Destructive actions get a red confirm button,
/// so the colour itself says the action cannot be taken back.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) {
      final scheme = Theme.of(c).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// An [InputDecoration] with every border and fill turned off, for fields that
/// sit inside a container drawing its own. The theme's outlined style would
/// otherwise apply its borders on top, since unset fields fall back to it.
InputDecoration bareInputDecoration({
  String? hintText,
  String? labelText,
  TextStyle? hintStyle,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: hintStyle,
    filled: false,
    isDense: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: contentPadding ?? const EdgeInsets.symmetric(vertical: 12),
  );
}

// ─── surfaces ──────────────────────────────────────────────────────────────

/// The one card: a flat surface a step off the page, with a hairline edge.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? scheme.outlineVariant),
    );
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? AppColors.of(context).card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A rounded square holding an icon: the leading mark on rows and headers.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 36,
    this.color,
    this.background,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.52, color: color ?? scheme.onSurface),
    );
  }
}

/// Thinai's app mark: the gold spark on brand navy. The same object on the
/// splash, the empty chat and About, so the brand is one thing.
class ThinaiMark extends StatelessWidget {
  const ThinaiMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15608F), kBrandNavy, kBrandInk],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: kBrandNavy.withValues(alpha: 0.28),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.46,
        color: kBrandGold,
      ),
    );
  }
}

// ─── text ──────────────────────────────────────────────────────────────────

/// Small uppercase label above a group: "ON THIS DEVICE", "API".
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      Space.xs,
      Space.xxl,
      Space.xs,
      Space.sm,
    ),
  });

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A section title with a supporting line, for the larger groups on a page.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      Space.xs,
      Space.xxl,
      Space.xs,
      Space.md,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xxs),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─── tags and status ───────────────────────────────────────────────────────

enum TagTone { neutral, accent, success, warning, danger }

/// A small pill carrying one fact: "Active", "2.4 GB", "POST".
class Tag extends StatelessWidget {
  const Tag(
    this.label, {
    super.key,
    this.icon,
    this.tone = TagTone.neutral,
    this.dense = false,
    this.monospace = false,
  });

  final String label;
  final IconData? icon;
  final TagTone tone;
  final bool dense;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final (bg, fg) = switch (tone) {
      TagTone.neutral => (scheme.surfaceContainerLow, scheme.onSurfaceVariant),
      TagTone.accent => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TagTone.success => (app.successContainer, app.success),
      TagTone.warning => (app.warningContainer, app.warning),
      TagTone.danger => (scheme.errorContainer, scheme.error),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : Space.sm,
        vertical: dense ? 2 : Space.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: dense ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
                fontFamily: monospace ? 'monospace' : null,
                letterSpacing: monospace ? 0 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A coloured dot, optionally breathing to say "this is live".
class StatusDot extends StatefulWidget {
  const StatusDot({
    super.key,
    required this.color,
    this.pulsing = false,
    this.size = 8,
  });

  final Color color;
  final bool pulsing;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  // Created on first use: an idle repeating controller would drive frames
  // forever for a dot that is not pulsing.
  AnimationController? _controller;

  AnimationController get _c => _controller ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    // Never through the getter: creating a ticker here would reach for an
    // element that is already being torn down.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulsing) {
      return SizedBox.square(
        dimension: widget.size * 2,
        child: Center(child: dot),
      );
    }
    return SizedBox.square(
      dimension: widget.size * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * (1 + t),
                height: widget.size * (1 + t),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                  shape: BoxShape.circle,
                ),
              ),
              child!,
            ],
          );
        },
        child: dot,
      ),
    );
  }
}

// ─── empty states ──────────────────────────────────────────────────────────

/// Centred icon, title, message, and an optional way forward.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Space.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Space.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}

/// A one-line note with an icon, tinted by what kind of note it is.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.tone = TagTone.neutral,
  });

  final String text;
  final IconData icon;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final app = AppColors.of(context);
    final (bg, fg) = switch (tone) {
      TagTone.neutral => (scheme.surfaceContainerLow, scheme.onSurfaceVariant),
      TagTone.accent => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TagTone.success => (app.successContainer, app.success),
      TagTone.warning => (app.warningContainer, app.warning),
      TagTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.md, 10, Space.md, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: Space.sm + 2),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── grouped lists ─────────────────────────────────────────────────────────

/// Rows inside one card, divided by inset hairlines: the settings pattern
/// every well-made app converges on.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.label});

  final List<Widget> children;

  /// Optional uppercase label above the card.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, indent: 64, color: scheme.outlineVariant));
      }
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) SectionLabel(label!),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

/// One row of a [SettingsGroup].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = danger ? scheme.error : scheme.onSurface;
    final disabled = onTap == null && trailing == null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.md,
            Space.md,
          ),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                size: 34,
                color: danger ? scheme.error : scheme.onSurface,
                background: danger
                    ? scheme.errorContainer
                    : scheme.surfaceContainerLow,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: fg,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              if (trailing != null)
                trailing!
              else if (onTap != null && showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [SettingsRow] whose whole row flips a switch.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

// ─── code ──────────────────────────────────────────────────────────────────

/// Monospace text on the code surface, with a copy button when [onCopy] is
/// given. Curl examples and tokens.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.text,
    this.onCopy,
    this.copyTooltip = 'Copy',
    this.selectable = false,
    this.fontSize = 12,
  });

  final String text;
  final VoidCallback? onCopy;
  final String copyTooltip;
  final bool selectable;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final app = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.5,
      color: app.onCodeSurface,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: app.codeSurface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: EdgeInsets.fromLTRB(
        Space.md,
        10,
        onCopy == null ? Space.md : Space.xs,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: onCopy == null ? 0 : 6),
              child: selectable
                  ? SelectableText(text, style: style)
                  : Text(text, style: style),
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: copyTooltip,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: scheme.onSurfaceVariant,
              icon: const Icon(Icons.content_copy_rounded),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
