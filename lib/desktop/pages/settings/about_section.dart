/// About & help: version, support links, licenses, diagnostics and common
/// questions. No app-update row: Play's in-app update has no desktop
/// counterpart.
library;

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../../llm/generation_settings.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets/made_in_erode.dart';
import '../../diagnostics.dart';
import '../../l10n/settings_strings.dart';
import '../../theme/desk_theme.dart';
import '../../widgets/hover.dart';
import '../../widgets/toast.dart';
import 'settings_widgets.dart';

const _instagramHandle = '@27_ai_27';
final _instagramUrl = Uri.parse('https://www.instagram.com/27_ai_27/');
final _githubUrl = Uri.parse('https://github.com/Abhinivesh2729/Thinai');

/// How many recent log lines go into "Copy diagnostics". Enough to cover a
/// model load and the error after it, short enough to paste into a DM.
const _kDiagnosticLines = 150;

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final failed = SettingsStrings.of(context).linkOpenFailed;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        showDeskToast(failed, tone: DeskTone.error);
      }
    } catch (_) {
      showDeskToast(failed, tone: DeskTone.error);
    }
  }

  Future<void> _openLogFolder(BuildContext context) async {
    final s = SettingsStrings.of(context);
    final path = Diagnostics.logPath;
    if (path == null) {
      showDeskToast(s.logUnavailable, tone: DeskTone.warning);
      return;
    }
    await Diagnostics.flush();
    try {
      if (!await launchUrl(Uri.file(File(path).parent.path))) {
        showDeskToast(s.folderOpenFailed, tone: DeskTone.error);
      }
    } catch (_) {
      showDeskToast(s.folderOpenFailed, tone: DeskTone.error);
    }
  }

  /// English on purpose, like the phone's device info: it is read by us, not
  /// by the user.
  String _diagnostics(WidgetRef ref) {
    final version = ref.read(appVersionProvider).valueOrNull ?? 'unknown';
    final profile = ref.read(deviceProfileProvider).valueOrNull;
    final ram = profile?.totalRamBytes;
    final status = ref.read(serverControllerProvider);
    final recent = Diagnostics.recent;
    final tail = recent.length > _kDiagnosticLines
        ? recent.sublist(recent.length - _kDiagnosticLines)
        : recent;
    return [
      'Thinai $version (desktop)',
      'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'CPU: ${Platform.numberOfProcessors} cores, ${Abi.current()}',
      'RAM: ${ram == null ? 'unknown' : '${(ram / (1 << 30)).toStringAsFixed(1)} GB'}',
      'GPU setting: ${GenerationSettingsStore.instance.settings.gpu.storageKey}',
      'Model: ${ref.read(activeModelIdProvider) ?? 'none'}',
      'Server: ${status.running ? 'running on :${status.port}${status.lan ? ' (LAN)' : ''}' : 'stopped'}',
      'Web search: ${ref.read(webSearchEnabledProvider) ? 'on' : 'off'}',
      'Language: ${ref.read(appLanguageProvider).name}',
      'Log: ${Diagnostics.logPath ?? 'not open'}',
      '',
      'Recent log (${tail.length} lines):',
      ...tail,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final version = ref.watch(appVersionProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(version: version),
        const SizedBox(height: 14),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.support_agent_rounded,
              title: l10n.supportTitle,
              subtitle: '${s.supportHint}  $_instagramHandle',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeskIconButton(
                    icon: Icons.copy_rounded,
                    tooltip: l10n.supportCopyHandle,
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: _instagramHandle),
                      );
                      showDeskToast(
                        l10n.supportHandleCopied,
                        tone: DeskTone.success,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  DeskButton(
                    label: l10n.supportOpenInstagram,
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => _open(context, _instagramUrl),
                  ),
                ],
              ),
            ),
            SettingsRow(
              icon: Icons.code_rounded,
              title: s.sourceCode,
              subtitle: s.sourceCodeHint,
              trailing: DeskButton(
                label: s.openGithub,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _open(context, _githubUrl),
              ),
            ),
            SettingsRow(
              icon: Icons.gavel_rounded,
              title: l10n.aboutLicenses,
              subtitle: s.licensesHint,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Thinai',
                applicationVersion: version,
              ),
              trailing: DeskButton(
                label: s.view,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Thinai',
                  applicationVersion: version,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsCard(
          children: [
            SettingsRow(
              icon: Icons.receipt_long_rounded,
              title: s.diagnostics,
              subtitle: s.diagnosticsHint,
              below: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  DeskButton(
                    label: s.copyDiagnostics,
                    icon: Icons.content_copy_rounded,
                    kind: DeskButtonKind.primary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _diagnostics(ref)));
                      showDeskToast(
                        s.diagnosticsCopied,
                        tone: DeskTone.success,
                      );
                    },
                  ),
                  DeskButton(
                    label: s.openLogFolder,
                    icon: Icons.folder_open_rounded,
                    onPressed: () => _openLogFolder(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _Faq(),
        const SizedBox(height: 28),
        const MadeInErode(compact: true),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.version});
  final String? version;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final s = SettingsStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(DeskSize.radiusL),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Image.asset(
            palette.isDark
                ? 'assets/images/logo_dark.png'
                : 'assets/images/logo_transparent.png',
            width: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              s.tagline,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                s.version,
                style: TextStyle(fontSize: 11.5, color: palette.textFaint),
              ),
              const SizedBox(height: 4),
              Pill(
                label: version == null ? '…' : 'v$version',
                color: DeskColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The phone's common questions, reworded for a PC.
class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final palette = DeskPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.supportTroubleshooting,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
        ),
        SettingsCard(
          children: [
            _FaqItem(
              question: s.faqPrivacyQuestion,
              answer: s.faqPrivacyAnswer,
            ),
            _FaqItem(
              question: l10n.supportFaqLoadQuestion,
              answer: s.faqLoadAnswer,
            ),
            _FaqItem(
              question: l10n.supportFaqGpuQuestion,
              answer: s.faqGpuAnswer,
            ),
          ],
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = DeskPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Hoverable(
      cursor: SystemMouseCursors.click,
      builder: (context, hovered) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: DeskMotion.fast,
          color: hovered
              ? scheme.onSurface.withValues(alpha: 0.035)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: DeskMotion.medium,
                    curve: DeskMotion.ease,
                    turns: _open ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: DeskMotion.medium,
                curve: DeskMotion.ease,
                alignment: Alignment.topLeft,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.answer,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: palette.textMuted,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
