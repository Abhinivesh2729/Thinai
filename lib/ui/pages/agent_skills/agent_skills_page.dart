/// Agent skills management page.
///
/// Lets users enable, disable, and view available skills for the chat engine.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agent_skills/skill_manifest.dart';
import '../../../agent_skills/skill_store.dart';
import '../../../l10n/l10n.dart';
import '../../../state/providers.dart';

/// Page to manage agent skills.
class AgentSkillsPage extends ConsumerStatefulWidget {
  const AgentSkillsPage({super.key});

  @override
  ConsumerState<AgentSkillsPage> createState() => _AgentSkillsPageState();
}

class _AgentSkillsPageState extends ConsumerState<AgentSkillsPage> {
  List<LoadedSkill> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final store = ref.read(skillStoreProvider);
    final skills = await store.loadSkills();
    if (!mounted) return;
    setState(() => _skills = skills);
  }

  Future<void> _toggleSkill(LoadedSkill skill) async {
    final store = ref.read(skillStoreProvider);
    await store.toggleSkill(skill.manifest.name);
    if (!mounted) return;
    setState(() {
      // Refresh to update enabled state
      _skills = _skills.map((s) => s.manifest.name == skill.manifest.name
        ? LoadedSkill(
            manifest: s.manifest,
            instructions: s.instructions,
            skillPath: s.skillPath,
          )
        : s).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final enabledSkills = _skills.where((s) {
      final store = ref.read(skillStoreProvider);
      return store.isSkillEnabled(s.manifest.name);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agentSkillsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _skills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.agentSkillsLoading,
                    style: theme.textTheme.bodyMedium,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSkills,
              child: ListView(
                children: [
                  // Enabled skills section
                  if (enabledSkills.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.agentSkillsEnabled,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.agentSkillsEnabledDescription,
                            style: theme.textTheme.bodySmall,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    for (final skill in enabledSkills) _SkillCard(
                      skill: skill,
                      enabled: true,
                      onToggle: _toggleSkill,
                    ),
                  ],

                  // All skills section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.agentSkillsAvailable,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.agentSkillsAvailableDescription,
                          style: theme.textTheme.bodySmall,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  for (final skill in _skills) ...[
                    if (!ref.read(skillStoreProvider).isSkillEnabled(skill.manifest.name))
                      _SkillCard(
                        skill: skill,
                        enabled: false,
                        onToggle: _toggleSkill,
                      ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

/// Card for a single skill with toggle.
class _SkillCard extends StatelessWidget {
  final LoadedSkill skill;
  final bool enabled;
  final void Function(LoadedSkill) onToggle;

  const _SkillCard({
    required this.skill,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onToggle(skill),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                    ? scheme.primaryContainer
                    : scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enabled ? Icons.check_rounded : Icons.star_outline_rounded,
                  color: enabled
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.manifest.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (enabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.agentSkillsEnabledLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.manifest.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}