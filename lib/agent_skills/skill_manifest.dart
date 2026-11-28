/// Schema for an agent skill manifest.
///
/// Skills are stored as folders containing a manifest and instructions (SKILL.md).
/// The manifest defines metadata and configuration, while SKILL.md contains the
/// actual skill instructions that get injected into the chat prompt.
library;

import 'dart:convert';

/// A skill that has been loaded from disk.
class LoadedSkill {
  final SkillManifest manifest;
  final String instructions;
  final String skillPath;

  const LoadedSkill({
    required this.manifest,
    required this.instructions,
    required this.skillPath,
  });

  /// Create a copy with updated fields.
  LoadedSkill copyWith({
    SkillManifest? manifest,
    String? instructions,
    String? skillPath,
  }) => LoadedSkill(
    manifest: manifest ?? this.manifest,
    instructions: instructions ?? this.instructions,
    skillPath: skillPath ?? this.skillPath,
  );
}

/// Manifest file content for an agent skill.
///
/// The manifest is a YAML/JSON-like structure that defines skill metadata
/// and configuration options.
class SkillManifest {
  /// Unique identifier for the skill (snake_case, lowercase).
  final String name;

  /// Human-readable title for the skill.
  final String title;

  /// Brief description of what the skill does.
  final String description;

  /// Optional longer documentation about the skill.
  final String? documentation;

  /// List of tags to help users discover the skill.
  final List<String> tags;

  /// Whether the skill is enabled by default for new users.
  final bool enabledByDefault;

  /// Context window budget in tokens for this skill's instructions.
  final int contextBudget;

  /// Whether the skill should be loaded only when explicitly requested.
  final bool onDemand;

  const SkillManifest({
    required this.name,
    required this.title,
    required this.description,
    this.documentation,
    this.tags = const [],
    this.enabledByDefault = false,
    this.contextBudget = 2048,
    this.onDemand = false,
  });

  /// Load a manifest from a JSON string.
  static SkillManifest fromJson(Map<String, dynamic> json) => SkillManifest(
    name: json['name'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    documentation: json['documentation'] as String?,
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    enabledByDefault: json['enabledByDefault'] as bool? ?? false,
    contextBudget: json['contextBudget'] as int? ?? 2048,
    onDemand: json['onDemand'] as bool? ?? false,
  );

  /// Convert the manifest to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'description': description,
    if (documentation != null) 'documentation': documentation,
    'tags': tags,
    'enabledByDefault': enabledByDefault,
    'contextBudget': contextBudget,
    'onDemand': onDemand,
  };

  /// Parse JSON content into a SkillManifest.
  static SkillManifest parse(String content) {
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    return fromJson(parsed);
  }
}

/// Error types for skill loading and management.
class SkillError implements Exception {
  final String message;
  final String? skillId;

  const SkillError(this.message, [this.skillId]);

  @override
  String toString() {
    if (skillId != null) {
      return 'SkillError[$skillId]: $message';
    }
    return 'SkillError: $message';
  }
}

/// Errors that can occur during skill operations.
class SkillErrors {
  static const SkillError notFound = SkillError('Skill not found');
  static const SkillError invalidManifest = SkillError('Invalid manifest format');
  static const SkillError missingInstructions = SkillError('SKILL.md file missing');
  static const SkillError readFailed = SkillError('Failed to read skill files');
  static const SkillError parseFailed = SkillError('Failed to parse manifest');
  static const SkillError validationFailed = SkillError('Manifest validation failed');
}