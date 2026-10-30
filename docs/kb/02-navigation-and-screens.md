# 2. Navigation and screens

## Launch flow

```
App start
  └─ Splash (≥ 0.5 s: logo, "PRIVATE ON-DEVICE AI", "Crafted in Erode, Tamil Nadu")
       ├─ First launch → Onboarding (5 slides) → main shell
       └─ Later launches → main shell, on the saved Start page (default: Chat)
```

While the splash shows, the app restores state in the background: settings, the last active model, and the server if it was running when the app closed. It never downloads a model by itself.

## Navigation map

```
Main shell (bottom bar: Chat · Models · Server · Settings)
│
├─ Drawer (☰ on Chat, or swipe from the left edge on any tab)
│    New chat · Search chats · chat list (Today / Yesterday / ...) · chat options
│    Manage chats · Model Settings · App Settings · About Thinai
│
├─ Chat
│    ├─ Model chip (top right) → Switch Model sheet → Model settings sheet
│    ├─ "+" menu → Web search toggle · Camera · Image · Document
│    └─ Sources pill on a web answer → Sources sheet
│
├─ Models
│    ├─ த → Tamil eval page
│    ├─ ⏱ → Benchmark page
│    ├─ Layers icon (badge = count) → Model Manager sheet
│    ├─ Search → "Search Hugging Face" → HF search page → HF repo page
│    ├─ All ▾ (category filter) · Goal ▾ (Choose a goal sheet)
│    └─ ⋯ on a card → Model details sheet
│
├─ Server
│    ├─ Port chip → Port dialog (only while stopped)
│    ├─ Tune → Model settings sheet
│    └─ Share on LAN → token row → Regenerate dialog
│
└─ Settings
     ├─ Appearance (start page, language, glossary, theme, web search)
     ├─ System Prompt
     ├─ Hardware (GPU, Benchmark, GPU speed test, device info)
     ├─ Model & Storage (active model, import .gguf, download from URL, clear downloads)
     ├─ Local Server (share on Wi-Fi, port, status)
     └─ About & Help (app tour, check for updates, help & support, about)
```

Android Back on any main tab closes the app. There is no "back to Chat" step.

## Screen gallery (seen on device)

| Screen | Screenshot | What it is for |
|---|---|---|
| Chat, empty | [chat-empty](screens/chat-empty.png) | Logo, "Ready · Web search on" pill, 4 starter chips, composer |
| Chat "+" menu | [chat-attach-menu](screens/chat-attach-menu.png) | Web search toggle, Camera, Image, Document |
| Chat reply | [chat-reply](screens/chat-reply.png) | User bubble, assistant reply with Copy / Share |
| Web answer | [chat-web-answer](screens/chat-web-answer.png) | Reply with the Sources pill (letter badges) |
| Sources sheet | [chat-sources-sheet](screens/chat-sources-sheet.png) | Searched query, numbered sources, tap to open |
| Switch Model sheet | [chat-switch-model](screens/chat-switch-model.png) | Installed models as a radio list, tune icon, "Download More Models" |
| Model settings sheet | [model-settings-sheet](screens/model-settings-sheet.png) | Context window, temperature, Top-K, Top-P, thinking |
| Drawer, empty | [drawer-empty](screens/drawer-empty.png) | New chat, "No chats yet", footer links |
| Drawer with chats | [drawer](screens/drawer.png) | Grouped chat list |
| Chat options | [drawer-chat-options](screens/drawer-chat-options.png) | Select / Rename / Delete chat |
| Models | [models](screens/models.png) | Search, filters, Featured card, catalog cards |
| Category filter | [models-filter](screens/models-filter.png) | All / Chat / Vision / Embedding / Installed (n) |
| Goal picker | [models-goal-picker](screens/models-goal-picker.png) | 9 goals (Fast chat, Reasoning, Coding, Tamil, ...) |
| Top picks | [models-top-picks](screens/models-top-picks.png) | Recommended models for the chosen goal |
| Model details | [model-details](screens/model-details.png) | Description, parameters, context, size, capability, Download |
| Model Manager | [model-manager](screens/model-manager.png) | Installed files, Load, Delete, active model, downloads |
| Hugging Face search | [hf-search](screens/hf-search.png) | Public GGUF repos, most downloaded first |
| Benchmark | [benchmark](screens/benchmark.png) | Speed gauge, speed graph, first token / tokens / total, "Best for this phone" |
| Tamil eval | [tamil-eval](screens/tamil-eval.png), [skills](screens/tamil-eval-skills.png) | Tamil score dial, per-skill scores, models compared |
| Server, stopped | [server-stopped](screens/server-stopped.png) | Status, URL, Start, serving model, LAN, Quick start |
| Server, running | [server-running](screens/server-running.png) | Same, running |
| API endpoints | [server-endpoints](screens/server-endpoints.png) | 4 endpoints with copy-cURL and samples |
| Settings | [settings](screens/settings.png) | 6 sections |
| Appearance | [settings-appearance](screens/settings-appearance.png) | Start page, language, glossary, theme, web search |
| System Prompt | [settings-system-prompt](screens/settings-system-prompt.png) | Edit the chat system prompt |
| Hardware | [settings-hardware](screens/settings-hardware.png) | GPU, Benchmark, GPU speed test, device |
| GPU speed test | [settings-gpu-test](screens/settings-gpu-test.png) | "Find GPU" result on the test phone: "No usable GPU. Using the CPU." |
| Model & Storage | [settings-model-storage](screens/settings-model-storage.png) | Active model, import, download from URL, clear |
| Local Server | [settings-local-server](screens/settings-local-server.png) | Share on Wi-Fi, port, status |
| About & Help | [settings-about-help](screens/settings-about-help.png) | App tour, updates, support, about |
| Help & Support | [support](screens/support.png) | Instagram, device info, FAQ |
| About | [about](screens/about.png) | Version, features, engine specs, licenses |

Not captured: splash, onboarding (shown only on first run or via App tour), Hugging Face repo page, and the LAN token row. They are described in the feature docs.

## Sheets, dialogs and toasts

The mobile app uses **bottom sheets** for most secondary UI (model switch, model settings, sources, goal picker, model manager, chat options) and **snackbars** ("toasts") for short feedback. On desktop these map to popovers, side panels, dialogs and non-blocking notifications; see [10-desktop-prd.md](10-desktop-prd.md).
