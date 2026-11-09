/// Appearance (theme, language, start page, glossary) and Chat (web search).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../state/providers.dart';
import '../../../ui/widgets/tamil_glossary_dialog.dart';
import '../../l10n/desk_l10n.dart';
import '../../l10n/settings_strings.dart';
import '../../shell/desk_nav.dart';
import 'desk_start_page.dart';
import 'settings_widgets.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  Future<void> _setLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    final wasTamil = ref.read(isTamilUiProvider);
    await ref.read(appLanguageProvider.notifier).set(language);
    // Same as the phone: introduce the Tamil words whenever the app turns
    // Tamil. Waits a frame so the dialog opens in the new locale.
    if (wasTamil || !ref.read(isTamilUiProvider)) return;
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) await showTamilGlossary(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = SettingsStrings.of(context);
    final nav = ShellStrings.of(context);
    final theme = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final start = ref.watch(deskStartPageProvider);

    return SettingsCard(
      children: [
        SettingsRow(
          icon: Icons.contrast_rounded,
          title: l10n.settingsThemeMode,
          trailing: DeskSegmented<ThemeMode>(
            value: theme,
            onChanged: (m) =>
                unawaited(ref.read(themeModeProvider.notifier).set(m)),
            segments: [
              Segment(
                ThemeMode.system,
                l10n.settingsThemeSystem,
                icon: Icons.desktop_windows_outlined,
              ),
              Segment(
                ThemeMode.dark,
                l10n.settingsThemeDark,
                icon: Icons.dark_mode_outlined,
              ),
              Segment(
                ThemeMode.light,
                l10n.settingsThemeLight,
                icon: Icons.light_mode_outlined,
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.translate_rounded,
          title: l10n.languageSetting,
          subtitle: s.languageHint,
          trailing: DeskSegmented<AppLanguage>(
            value: language,
            onChanged: (v) => unawaited(_setLanguage(context, ref, v)),
            segments: [
              Segment(AppLanguage.system, l10n.languageSystem),
              Segment(AppLanguage.english, l10n.languageEnglish),
              Segment(AppLanguage.tamil, l10n.languageTamil),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.start_rounded,
          title: l10n.settingsStartPage,
          subtitle: s.startPageHint,
          trailing: DeskSelect<DeskPage>(
            value: start,
            onChanged: (p) =>
                unawaited(ref.read(deskStartPageProvider.notifier).set(p)),
            options: [
              Segment(
                DeskPage.chat,
                nav.navChat,
                icon: Icons.chat_bubble_outline_rounded,
              ),
              Segment(
                DeskPage.models,
                nav.navModels,
                icon: Icons.view_in_ar_outlined,
              ),
              Segment(DeskPage.lab, nav.navLab, icon: Icons.speed_outlined),
              Segment(DeskPage.server, nav.navServer, icon: Icons.dns_outlined),
              Segment(
                DeskPage.settings,
                nav.navSettings,
                icon: Icons.settings_outlined,
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.menu_book_rounded,
          title: l10n.settingsGlossary,
          subtitle: s.glossaryHint,
          onTap: () => showTamilGlossary(context),
          trailing: DeskButton(
            label: s.open,
            icon: Icons.open_in_new_rounded,
            onPressed: () => showTamilGlossary(context),
          ),
        ),
      ],
    );
  }
}

class ChatSection extends ConsumerWidget {
  const ChatSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SettingsStrings.of(context);
    final on = ref.watch(webSearchEnabledProvider);
    void set(bool v) =>
        unawaited(ref.read(webSearchEnabledProvider.notifier).set(v));

    return SettingsCard(
      children: [
        SettingsRow(
          icon: Icons.travel_explore_rounded,
          title: context.l10n.settingsWebSearch,
          subtitle: s.webSearchHint,
          onTap: () => set(!on),
          trailing: DeskToggle(
            value: on,
            onChanged: set,
            semanticLabel: context.l10n.settingsWebSearch,
          ),
        ),
      ],
    );
  }
}
