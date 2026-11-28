# Agent Skills Feature

## Overview

This implementation adds agent skills support to Thinai, allowing users to enable reusable, task-specific capabilities (instructions + tools + resources) that the model can load on demand.

## Architecture

### Core Components

1. **skill_manifest.dart** - Defines the manifest schema and loaded skill structure
2. **skill_store.dart** - Handles skill discovery, loading, and state management
3. **skill_provider.dart** - Riverpod providers for React state management
4. **agent_skills_page.dart** - UI page to manage skills

### Skill Format

Skills are stored as folders containing:
- `manifest.json` - Metadata (name, title, description, context budget, tags)
- `SKILL.md` - Actual skill instructions injected into chat prompts

### Built-in Skills

Three skills included:
- **notes** - Helps create and manage personal notes with structured format
- **summarize** - Assists with creating concise summaries
- **web_search** - Guides effective use of web search results

## Integration Points

### Chat Page

Skills are loaded and injected into the system prompt before sending to the model:

```dart
final skillStore = ref.read(skillStoreProvider);
final skillInstructions = skillStore.getEnabledInstructions(
  totalBudget: options.contextSize,
  reservedTokens: options.contextSize ~/ 4,
).split('\n\n---\n\n');

final prompt = _promptFrom(
  priorTurns,
  text,
  systemPrompt: systemPrompt,
  document: _document,
  image: _image,
  search: search,
  skillInstructions: skillInstructions,
);
```

### State Management

Skills are managed via Riverpod providers:

```dart
final skillStoreProvider = Provider<SkillStore>((ref) => SkillStore.instance);
final enabledSkillsProvider = Provider<List<LoadedSkill>>((ref) {
  final store = ref.read(skillStoreProvider);
  return store.getEnabledManifests();
});
```

## Usage

### Enabling/Disabling Skills

Users can toggle skills on the Agent Skills page (Settings → Agent Skills):

- **Enabled skills** appear at the top of the list
- **Available skills** can be installed by enabling them
- Skills are persisted across app launches

### Skill Context Budget

Each skill specifies a `contextBudget` in tokens. Skills are loaded only if they fit within the available context window, respecting the user's model context size settings.

## Adding New Skills

To add a new skill:

1. Create a folder in `assets/skills/` (e.g., `assets/skills/code_review/`)
2. Add `manifest.json` with skill metadata
3. Add `SKILL.md` with skill instructions

Example manifest.json:

```json
{
  "name": "code_review",
  "title": "Code Review",
  "description": "Guides thorough code reviews with best practices",
  "tags": ["development", "quality"],
  "enabledByDefault": false,
  "contextBudget": 2048,
  "onDemand": true
}
```

## Testing

Run Flutter analyze to verify:

```bash
flutter analyze
```

## Future Enhancements

- Skill search and filtering
- Skill ratings and reviews
- Custom skill creation from chat
- Skill categories and groups
- On-demand skill loading (triggered by specific user requests)