/// Desktop Settings: a section list on the left, one scrolling pane on the
/// right. The list follows the scroll, and clicking it glides to the section.
///
/// Everything sits on one page (rather than the phone's sub-pages) because a
/// desktop window has room, and scrolling past a setting is cheaper than
/// opening and closing a page to find it.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../l10n/settings_strings.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import 'settings/about_section.dart';
import 'settings/appearance_section.dart';
import 'settings/hardware_section.dart';
import 'settings/models_section.dart';
import 'settings/server_section.dart';
import 'settings/system_prompt_section.dart';

enum _Sec { appearance, chat, systemPrompt, hardware, models, server, about }

class _SecInfo {
  const _SecInfo(this.icon, this.title, this.blurb, this.child);
  final IconData icon;
  final String title;
  final String blurb;
  final Widget child;
}

_SecInfo _info(BuildContext context, _Sec sec) {
  final s = SettingsStrings.of(context);
  return switch (sec) {
    _Sec.appearance => _SecInfo(
      Icons.palette_outlined,
      s.secAppearance,
      s.blurbAppearance,
      const AppearanceSection(),
    ),
    _Sec.chat => _SecInfo(
      Icons.chat_bubble_outline_rounded,
      s.secChat,
      s.blurbChat,
      const ChatSection(),
    ),
    _Sec.systemPrompt => _SecInfo(
      Icons.edit_note_rounded,
      s.secSystemPrompt,
      context.l10n.systemPromptDescription,
      const SystemPromptSection(),
    ),
    _Sec.hardware => _SecInfo(
      Icons.memory_rounded,
      s.secHardware,
      s.blurbHardware,
      const HardwareSection(),
    ),
    _Sec.models => _SecInfo(
      Icons.view_in_ar_outlined,
      s.secModels,
      s.blurbModels,
      const ModelsSection(),
    ),
    _Sec.server => _SecInfo(
      Icons.dns_outlined,
      s.secServer,
      s.blurbServer,
      const ServerSection(),
    ),
    _Sec.about => _SecInfo(
      Icons.info_outline_rounded,
      s.secAbout,
      s.blurbAbout,
      const AboutSection(),
    ),
  };
}

class DeskSettingsPage extends ConsumerStatefulWidget {
  const DeskSettingsPage({super.key});

  @override
  ConsumerState<DeskSettingsPage> createState() => _DeskSettingsPageState();
}

class _DeskSettingsPageState extends ConsumerState<DeskSettingsPage> {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _keys = {for (final s in _Sec.values) s: GlobalKey()};
  var _active = _Sec.appearance;

  /// Set while (and after) gliding to a clicked section, so the highlight
  /// stays on what was clicked instead of flicking through every section
  /// passed on the way, or snapping to the last one when a short section
  /// near the bottom cannot reach the top. Cleared by the user's own scroll.
  _Sec? _jumpTarget;

  /// How far below the top of the pane a section's top must have scrolled to
  /// count as the one being read.
  static const _spyLine = 120.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_spy);
  }

  @override
  void dispose() {
    _scroll.removeListener(_spy);
    _scroll.dispose();
    super.dispose();
  }

  void _spy() {
    if (_jumpTarget != null || !_scroll.hasClients) return;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;
    final top = viewport.localToGlobal(Offset.zero).dy;

    var next = _Sec.values.first;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 2 && pos.maxScrollExtent > 0) {
      next = _Sec.values.last;
    } else {
      for (final sec in _Sec.values) {
        final box =
            _keys[sec]!.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;
        if (box.localToGlobal(Offset.zero).dy - top <= _spyLine) next = sec;
      }
    }
    if (next != _active) setState(() => _active = next);
  }

  Future<void> _jump(_Sec sec) async {
    final ctx = _keys[sec]!.currentContext;
    if (ctx == null) return;
    setState(() {
      _active = sec;
      _jumpTarget = sec;
    });
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: DeskMotion.ease,
    );
  }

  void _userScrolled() {
    if (_jumpTarget == null) return;
    _jumpTarget = null;
    _spy();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return ColoredBox(
          color: palette.canvas,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: DeskMotion.medium,
                curve: DeskMotion.ease,
                width: compact ? 72 : 248,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: palette.hairline)),
                ),
                child: _SectionNav(
                  active: _active,
                  compact: compact,
                  onTap: _jump,
                ),
              ),
              Expanded(child: _content(context, compact)),
            ],
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, bool compact) {
    return Listener(
      key: _viewportKey,
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) _userScrolled();
      },
      onPointerPanZoomStart: (_) => _userScrolled(),
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (n) {
          // A drag (touchpad, scrollbar thumb) is the user's; ensureVisible's
          // animation has no drag details.
          if (n.dragDetails != null) _userScrolled();
          return false;
        },
        child: Scrollbar(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              compact ? 24 : 44,
              8,
              compact ? 24 : 44,
              64,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, sec) in _Sec.values.indexed)
                      EnterAnimation(
                        delay: Duration(milliseconds: 40 * i),
                        child: _SectionBlock(
                          key: _keys[sec],
                          info: _info(context, sec),
                          active: sec == _active,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section's header and its content. The header's icon lights up while the
/// section is the one in view, echoing the list on the left.
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({super.key, required this.info, required this.active});
  final _SecInfo info;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: DeskMotion.medium,
                curve: DeskMotion.ease,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? DeskColors.green.withValues(alpha: 0.14)
                      : scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(DeskSize.radiusM - 2),
                ),
                child: TweenAnimationBuilder<Color?>(
                  duration: DeskMotion.medium,
                  tween: ColorTween(
                    end: active ? DeskColors.green : palette.textMuted,
                  ),
                  builder: (context, c, _) =>
                      Icon(info.icon, size: 18, color: c),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: context.tracking(-0.2),
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.blurb,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          info.child,
        ],
      ),
    );
  }
}

/// The left-hand list of sections, with a pill that glides to the active one.
class _SectionNav extends ConsumerWidget {
  const _SectionNav({
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final _Sec active;
  final bool compact;
  final ValueChanged<_Sec> onTap;

  static const _itemHeight = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SettingsStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final version = ref.watch(appVersionProvider).valueOrNull;
    final index = _Sec.values.indexOf(active);

    return ClipRect(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          24,
          compact ? 12 : 16,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: DeskMotion.fast,
              child: compact
                  ? const SizedBox(height: 52, key: ValueKey('c'))
                  : Padding(
                      key: const ValueKey('f'),
                      padding: const EdgeInsets.only(left: 8, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: context.tracking(-0.4),
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            SizedBox(
              height: _itemHeight * _Sec.values.length,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: DeskMotion.medium,
                    curve: DeskMotion.spring,
                    top: index * _itemHeight + 2,
                    left: 0,
                    right: 0,
                    height: _itemHeight - 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: DeskColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          DeskSize.radiusM - 2,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      for (final sec in _Sec.values)
                        _NavItem(
                          info: _info(context, sec),
                          selected: sec == active,
                          compact: compact,
                          onTap: () => onTap(sec),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!compact && version != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Thinai v$version',
                  style: TextStyle(fontSize: 11.5, color: palette.textFaint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.info,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _SecInfo info;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DeskPalette.of(context);

    final item = Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) {
        final fg = selected
            ? scheme.onSurface
            : hovered
            ? scheme.onSurface.withValues(alpha: 0.9)
            : palette.textMuted;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: DeskMotion.fast,
            height: _SectionNav._itemHeight - 4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 10),
            decoration: BoxDecoration(
              color: hovered && !selected
                  ? scheme.onSurface.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(DeskSize.radiusM - 2),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                TweenAnimationBuilder<Color?>(
                  duration: DeskMotion.fast,
                  tween: ColorTween(end: selected ? DeskColors.green : fg),
                  builder: (context, c, _) =>
                      Icon(info.icon, size: 18, color: c),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: DeskMotion.fast,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fg,
                      ),
                      child: Text(
                        info.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      button: true,
      selected: selected,
      label: info.title,
      excludeSemantics: true,
      child: compact
          ? Tooltip(message: info.title, preferBelow: false, child: item)
          : item,
    );
  }
}
