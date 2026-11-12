/// Storage and management for agent skills.
///
/// Handles discovery, loading, enabling/disabling, and persistence of skill state.
library;

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'skill_manifest.dart';

/// Manages agent skills: loading from disk, tracking enabled state, and
/// providing skills to the chat engine.
class SkillStore {
  SkillStore._internal();

  static final SkillStore _instance = SkillStore._internal();

  static SkillStore get instance => _instance;

  /// Directory where skills are stored.
  static const String kSkillsDirectory = 'assets/skills';

  /// Preference key for storing enabled skill IDs.
  static const String _kEnabledSkillsKey = 'enabled_skills';

  /// Cache of loaded skills by ID.
  final Map<String, LoadedSkill> _loadedSkills = {};

  /// IDs of enabled skills.
  Set<String> _enabledSkillIds = {};

  /// Load all skills from disk.
  Future<List<LoadedSkill>> loadSkills() async {
    final skills = <LoadedSkill>[];
    
    // Check if skills directory exists
    final skillDir = Directory(kSkillsDirectory);
    if (!await skillDir.exists()) {
      return skills;
    }

    // Iterate through skill directories
    await for (final entity in skillDir.list()) {
      if (entity is! Directory) continue;

      try {
        final skill = await _loadSkill(entity.path);
        if (skill != null) {
          skills.add(skill);
          _loadedSkills[skill.manifest.name] = skill;
        }
      } catch (e) {
        // Skip skills that fail to load
        continue;
      }
    }

    // Load enabled skills from SharedPreferences
    await _loadEnabledSkills();

    return skills;
  }

  /// Load a single skill from its directory.
  Future<LoadedSkill?> _loadSkill(String path) async {
    final manifestPath = '$path/manifest.json';
    final skillManifestPath = '$path/SKILL.md';
    
    final manifestFile = File(manifestPath);
    final skillFile = File(skillManifestPath);

    if (!await manifestFile.exists() || !await skillFile.exists()) {
      return null;
    }

    try {
      final manifestContent = await manifestFile.readAsString();
      final skillContent = await skillFile.readAsString();

      final manifest = SkillManifest.parse(manifestContent);

      return LoadedSkill(
        manifest: manifest,
        instructions: skillContent,
        skillPath: path,
      );
    } catch (e) {
      return null;
    }
  }

  /// Load enabled skills from SharedPreferences.
  Future<void> _loadEnabledSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kEnabledSkillsKey);
    
    if (saved != null && saved.isNotEmpty) {
      _enabledSkillIds = Set<String>.from(
        (jsonDecode(saved) as List).map((e) => e.toString()),
      );
    } else {
      // Enable skills marked as enabledByDefault
      _enabledSkillIds = {
        for (final skill in _loadedSkills.values)
          if (skill.manifest.enabledByDefault) skill.manifest.name
      };
      await _saveEnabledSkills();
    }
  }

  /// Save enabled skills to SharedPreferences.
  Future<void> _saveEnabledSkills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kEnabledSkillsKey,
      jsonEncode(_enabledSkillIds.toList()),
    );
  }

  /// Get a loaded skill by name.
  LoadedSkill? getSkill(String name) => _loadedSkills[name];

  /// Get a skill manifest by name.
  SkillManifest? getSkillManifest(String name) => _loadedSkills[name]?.manifest;

  /// Get all loaded skills.
  List<LoadedSkill> getSkills() => _loadedSkills.values.toList();

  /// Check if a skill is enabled.
  bool isSkillEnabled(String name) => _enabledSkillIds.contains(name);

  /// Enable a skill.
  Future<void> enableSkill(String name) async {
    if (_enabledSkillIds.contains(name)) return;
    
    _enabledSkillIds.add(name);
    await _saveEnabledSkills();
  }

  /// Disable a skill.
  Future<void> disableSkill(String name) async {
    if (!_enabledSkillIds.contains(name)) return;
    
    _enabledSkillIds.remove(name);
    await _saveEnabledSkills();
  }

  /// Toggle skill enabled state.
  Future<void> toggleSkill(String name) async {
    if (isSkillEnabled(name)) {
      await disableSkill(name);
    } else {
      await enableSkill(name);
    }
  }

  /// Get enabled skills with their instructions for the current context budget.
  List<LoadedSkill> getEnabledSkillsWithContext({
    int totalBudget = 8192,
    int reservedTokens = 1024,
  }) {
    final remainingBudget = totalBudget - reservedTokens;
    final enabled = <LoadedSkill>[];
    
    for (final skill in getSkills()) {
      if (!isSkillEnabled(skill.manifest.name)) continue;
      if (skill.manifest.contextBudget > remainingBudget) continue;

      enabled.add(skill);
    }

    return enabled;
  }

  /// Get all enabled skill instructions joined together.
  String getEnabledInstructions({
    int totalBudget = 8192,
    int reservedTokens = 1024,
  }) {
    final skills = getEnabledSkillsWithContext(
      totalBudget: totalBudget,
      reservedTokens: reservedTokens,
    );

    return skills.map((s) => s.instructions).join('\n\n---\n\n');
  }

  /// Get enabled skill manifests for UI display.
  List<SkillManifest> getEnabledManifests() {
    return getSkills()
      .where((s) => isSkillEnabled(s.manifest.name))
      .map((s) => s.manifest)
      .toList();
  }

  /// Reload all skills from disk.
  Future<List<LoadedSkill>> reloadSkills() async {
    _loadedSkills.clear();
    return loadSkills();
  }
}