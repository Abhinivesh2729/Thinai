/// The conversation area.
///
/// Two states share one layout so the change between them can animate:
/// * Empty: the orb sits large in the middle with a greeting, the composer
///   below it, starter prompts underneath.
/// * Chatting: the orb glides up into the header and shrinks, the composer
///   slides to the bottom, and the transcript fades in behind it.
/// Every move is an implicit animation on the same widgets, so nothing is
/// rebuilt from scratch and there is no frame where the layout jumps.
library;

import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../l10n/desk_l10n.dart';
import '../monitor/load_strip.dart';
import '../shell/desk_nav.dart';
import '../theme/desk_theme.dart';
import '../widgets/hover.dart';
import '../widgets/measure_size.dart';
import '../widgets/orb.dart';
import 'composer.dart';
import 'desk_chat_controller.dart';
import 'message_view.dart';
import 'model_picker.dart';

class ChatPane extends ConsumerStatefulWidget {
  const ChatPane({super.key});

  @override
  ConsumerState<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends ConsumerState<ChatPane> {
  double _composerHeight = 120;
  bool _dragging = false;

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    final chat = ref.read(deskChatProvider.notifier);
    for (final file in details.files) {
      chat.attachAny(file.name, await file.readAsBytes());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final turns = ref.watch(chatSessionsProvider.select((x) => x.activeTurns));
    final title = ref.watch(
      chatSessionsProvider.select(
        (x) => x.active?.localizedTitle(context.l10n),
      ),
    );
    final hasModel = ref.watch(activeModelIdProvider) != null;
    final sidebarOpen = ref.watch(deskSidebarOpenProvider);
    final chatting = turns.isNotEmpty;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDrop,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          const header = 56.0;
          final column = math.min(DeskSize.chatColumn, w - 56);
          final side = (w - column) / 2;

          // Orb geometry for both states.
          final bigOrb = math.min(190.0, math.max(120.0, h * 0.24));
          const smallOrb = 30.0;
          final orbSize = chatting ? smallOrb : bigOrb;
          final orbLeft = chatting ? 50.0 : (w - bigOrb) / 2;
          final orbTop = chatting
              ? (header - smallOrb) / 2
              : math.max(header, h * 0.42 - bigOrb - 70);

          final greetingTop = orbTop + bigOrb + 6;
          final composerTop = chatting
              ? h - _composerHeight - 20
              : math.min(
                  h - _composerHeight - 20,
                  greetingTop + (hasModel ? 96 : 156),
                );

          return Stack(
            children: [
              // Transcript.
              Positioned.fill(
                top: header,
                child: AnimatedOpacity(
                  duration: DeskMotion.slow,
                  curve: DeskMotion.ease,
                  opacity: chatting ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !chatting,
                    child: _Transcript(
                      turns: turns,
                      padding: EdgeInsets.fromLTRB(
                        side,
                        8,
                        side,
                        _composerHeight + 40,
                      ),
                    ),
                  ),
                ),
              ),
              // Fade under the composer so text scrolls away softly.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _composerHeight + 48,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: DeskMotion.slow,
                    opacity: chatting ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.canvas.withValues(alpha: 0),
                            palette.canvas,
                          ],
                          stops: const [0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Header.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: header,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      DeskIconButton(
                        icon: sidebarOpen
                            ? Icons.view_sidebar_outlined
                            : Icons.view_sidebar_rounded,
                        tooltip: sidebarOpen
                            ? s.collapseSidebar
                            : s.expandSidebar,
                        onPressed: () => ref
                            .read(deskSidebarOpenProvider.notifier)
                            .update((v) => !v),
                      ),
                      AnimatedContainer(
                        duration: DeskMotion.slow,
                        curve: DeskMotion.spring,
                        width: chatting ? smallOrb + 14 : 6,
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: DeskMotion.medium,
                          child: Text(
                            chatting ? (title ?? '') : '',
                            key: ValueKey(chatting ? title : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      // Live load while a reply streams; out of the way
                      // otherwise.
                      AnimatedSwitcher(
                        duration: DeskMotion.medium,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SizeTransition(
                            sizeFactor: a,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        ),
                        child:
                            ref.watch(
                              deskChatProvider.select((c) => c.generating),
                            )
                            ? const Padding(
                                key: ValueKey('load'),
                                padding: EdgeInsets.only(right: 10),
                                child: LoadStrip(),
                              )
                            : const SizedBox.shrink(key: ValueKey('none')),
                      ),
                      const ModelPicker(),
                    ],
                  ),
                ),
              ),
              // Greeting (empty state only).
              Positioned(
                left: 24,
                right: 24,
                top: greetingTop,
                child: IgnorePointer(
                  ignoring: chatting,
                  child: AnimatedOpacity(
                    duration: chatting ? DeskMotion.fast : DeskMotion.slow,
                    opacity: chatting ? 0 : 1,
                    child: AnimatedSlide(
                      duration: DeskMotion.slow,
                      curve: DeskMotion.ease,
                      offset: chatting ? const Offset(0, -0.3) : Offset.zero,
                      child: _Greeting(hasModel: hasModel),
                    ),
                  ),
                ),
              ),
              // Composer.
              AnimatedPositioned(
                duration: DeskMotion.slow,
                curve: DeskMotion.spring,
                left: side,
                width: column,
                top: composerTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MeasureSize(
                      onChange: (size) {
                        if ((size.height - _composerHeight).abs() > 0.5) {
                          setState(() => _composerHeight = size.height);
                        }
                      },
                      child: const DeskComposer(),
                    ),
                  ],
                ),
              ),
              // Starters (empty state only).
              Positioned(
                left: side,
                width: column,
                top: composerTop + _composerHeight + 18,
                child: IgnorePointer(
                  ignoring: chatting || !hasModel,
                  child: AnimatedOpacity(
                    duration: chatting ? DeskMotion.fast : DeskMotion.slow,
                    opacity: chatting || !hasModel ? 0 : 1,
                    child: const _Starters(),
                  ),
                ),
              ),
              // The orb.
              AnimatedPositioned(
                duration: DeskMotion.slow,
                curve: DeskMotion.spring,
                left: orbLeft,
                top: orbTop,
                width: orbSize,
                height: orbSize,
                child: IgnorePointer(
                  child: Orb(
                    size: orbSize,
                    controller: ref.watch(deskOrbProvider),
                  ),
                ),
              ),
              // Drop overlay.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: DeskMotion.fast,
                    opacity: _dragging ? 1 : 0,
                    child: Container(
                      margin: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DeskColors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(DeskSize.radiusXL),
                        border: Border.all(
                          color: DeskColors.green.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.dropToAttach,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: DeskColors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.hasModel});
  final bool hasModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ShellStrings.of(context);
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          hasModel ? s.greeting : s.noModelTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: deskIsTamil(context) ? 0 : -0.4,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasModel ? s.greetingSub : s.noModelBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: palette.textMuted),
        ),
        if (!hasModel) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(deskPageProvider.notifier).state = DeskPage.models,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(s.getModel),
          ),
        ],
      ],
    );
  }
}

class _Starters extends ConsumerWidget {
  const _Starters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final starters = deskPick(
      context,
      const [
        (
          Icons.lightbulb_outline_rounded,
          'Brainstorm',
          'Give me 5 creative ideas for a weekend project with local AI',
        ),
        (
          Icons.code_rounded,
          'Write code',
          'Write a Python script that renames photos by the date they were taken',
        ),
        (
          Icons.summarize_outlined,
          'Summarize',
          'Summarize the key points of the following text:\n\n',
        ),
        (Icons.translate_rounded, 'Tamil', 'Translate into simple Tamil: '),
      ],
      const [
        (
          Icons.lightbulb_outline_rounded,
          'யோசனைகள்',
          'உள்ளூர் AI கொண்டு வார இறுதியில் செய்யக்கூடிய 5 படைப்பு யோசனைகளைச் சொல்லுங்கள்',
        ),
        (
          Icons.code_rounded,
          'நிரல்',
          'புகைப்படங்களை எடுத்த தேதிப்படி பெயர் மாற்றும் Python நிரலை எழுதுங்கள்',
        ),
        (
          Icons.summarize_outlined,
          'சுருக்கம்',
          'கீழே உள்ள உரையின் முக்கிய கருத்துகளைச் சுருக்கமாகச் சொல்லுங்கள்:\n\n',
        ),
        (
          Icons.translate_rounded,
          'ஆங்கிலம்',
          'இதை எளிய ஆங்கிலத்தில் மொழிபெயர்க்கவும்: ',
        ),
      ],
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < starters.length; i++)
          EnterAnimation(
            delay: Duration(milliseconds: 80 * i),
            child: Hoverable(
              cursor: SystemMouseCursors.click,
              builder: (context, hovered) => GestureDetector(
                onTap: () =>
                    ref.read(deskChatProvider.notifier).send(starters[i].$3),
                child: AnimatedContainer(
                  duration: DeskMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: hovered ? palette.panelRaised : palette.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hovered
                          ? DeskColors.green.withValues(alpha: 0.4)
                          : palette.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        starters[i].$1,
                        size: 16,
                        color: hovered ? DeskColors.green : palette.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        starters[i].$2,
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Transcript extends ConsumerWidget {
  const _Transcript({required this.turns, required this.padding});
  final List<ChatTurn> turns;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(deskChatProvider);
    final palette = DeskPalette.of(context);
    final s = ShellStrings.of(context);
    final stats = chat.lastStats;
    // Reversed: the newest message sits at offset 0, so a streaming reply
    // stays pinned to the bottom without any scroll bookkeeping.
    return SelectionArea(
      child: ListView.builder(
        reverse: true,
        padding: padding,
        itemCount: turns.length,
        itemBuilder: (context, r) {
          final i = turns.length - 1 - r;
          final last = i == turns.length - 1;
          final turn = turns[i];
          Widget? footer;
          if (last &&
              turn.role == 'assistant' &&
              !chat.generating &&
              stats != null) {
            final tps = stats.tokensPerSecond;
            final ttft = stats.timeToFirstToken;
            footer = Text(
              [
                if (tps != null) '${tps.toStringAsFixed(1)} ${s.tokPerSec}',
                if (ttft != null)
                  '${(ttft.inMilliseconds / 1000).toStringAsFixed(2)} s ${s.firstToken}',
              ].join('  ·  '),
              style: TextStyle(fontSize: 12, color: palette.textFaint),
            );
          }
          return DeskMessage(
            key: ValueKey(i),
            turn: turn,
            streaming: last && chat.generating,
            searching: last && chat.searching,
            footer: footer,
          );
        },
      ),
    );
  }
}
