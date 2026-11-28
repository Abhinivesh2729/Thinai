/// Riverpod provider for agent skills.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'skill_manifest.dart' show LoadedSkill;
export 'skill_store.dart' show SkillStore;
import 'skill_manifest.dart';
import 'skill_store.dart';

/// Provider for the skill store instance.
final skillStoreProvider = Provider<SkillStore>((ref) => SkillStore.instance);

/// Provider that loads and exposes all skills.
final loadedSkillsProvider = FutureProvider<List<LoadedSkill>>((ref) async {
  final store = ref.watch(skillStoreProvider);
  return store.loadSkills();
});

/// Provider for enabled skills only.
final enabledSkillsProvider = FutureProvider<List<LoadedSkill>>((ref) async {
  final store = ref.watch(skillStoreProvider);
  final allSkills = await store.loadSkills();
  return allSkills.where((s) => store.isSkillEnabled(s.manifest.name)).toList();
});

/// Provider that returns instructions from all enabled skills.
final enabledSkillsInstructionsProvider = Provider<String>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.getEnabledInstructions();
});

/// Provider for checking if any skills are enabled.
final hasEnabledSkillsProvider = Provider<bool>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.getEnabledManifests().isNotEmpty;
});

/// Provider to reload skills from disk.
final reloadSkillsProvider = Provider<Future<void> Function()>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.reloadSkills;
});

/// Provider to toggle a specific skill.
final toggleSkillProvider = Provider<Future<void> Function(String)>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.toggleSkill;
});

/// Provider to enable a specific skill.
final enableSkillProvider = Provider<Future<void> Function(String)>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.enableSkill;
});

/// Provider to disable a specific skill.
final disableSkillProvider = Provider<Future<void> Function(String)>((ref) {
  final store = ref.watch(skillStoreProvider);
  return store.disableSkill;
});

/// Provider to get a specific skill by name.
final skillByNameProvider = Provider.family<LoadedSkill?, String>((ref, name) {
  final store = ref.watch(skillStoreProvider);
  return store.getSkill(name);
});

/// Provider to check if a specific skill is enabled.
final isSkillEnabledProvider = Provider.family<bool, String>((ref, name) {
  final store = ref.watch(skillStoreProvider);
  return store.isSkillEnabled(name);
});