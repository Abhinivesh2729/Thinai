# 3. Chat

Code: `lib/ui/pages/chat_page.dart`, `lib/ui/widgets/chat_drawer.dart`, `lib/chat/`, `lib/web/web_search.dart`, chat state in `lib/state/providers.dart` (`ChatSessionsController`).

## 3.1 Chat screen

### Top bar
| Element | What it does |
|---|---|
| ☰ "Menu & Chats" | Opens the drawer |
| Title | Conversation title, or "Thinai" for a new chat |
| Model chip (right) | Green dot when a model is loaded, red warning when none. Opens the **Switch Model** sheet |

### Empty chat
- **No model:** logo, "Private Offline AI", "Runs fully on your phone. Your data stays here.", button **Get a model** (goes to Models).
- **Model loaded (seen on device):** status pill "Ready · Web search on" (or "Ready · Offline"), and 4 starter chips. A chip fills the text box; it does **not** send.

| Chip | Text it inserts |
|---|---|
| Ideas | Give me 5 creative ideas to build an on-device AI app |
| Python code | Write a Python script to sort and deduplicate a list of items |
| Summarize | Summarize the key takeaways from the following: |
| Speed test | What is your generation speed on this phone? |

If no model is loaded, a banner says "No model loaded." (or "No model yet.") with a button to the Models tab.

### Messages
- **User message:** right-aligned bubble. Long-press → **Copy text**, **Share text**.
- **Assistant reply:** full width, rendered as Markdown, with a blinking cursor while streaming.
  - While waiting: typing dots, or "Searching the web…" during a search.
  - If stopped before any text: italic "Stopped".
  - Under a finished reply: **Copy**, **Share**, and a **Sources** pill if web results were used.
- **Markdown support:** headings, bold, italic, strikethrough, inline code, code blocks (dark card with a language label and a Copy button), quotes, bullet/numbered/task lists, horizontal rules. Links show as text and are **not clickable**. No tables, LaTeX or images.
- **Auto-scroll:** follows new text. Scrolling up stops following; a "jump to latest" button appears. Opening a chat jumps to the newest message.

### Composer
| Control | Behaviour |
|---|---|
| **+** button | Opens a menu: **Web search** (shows "When needed" + ON badge, or "Off"), **Camera**, **Image**, **Document**. Camera and Image say "Needs a vision model" when the active model cannot read images. The + has a green ring while web search is on |
| Attachment chips | Show the attached image (thumbnail, name, size) and/or document (name, "~5.0K tokens" or "trimmed"), each with ✕ |
| Text box | 1–5 lines, hint "Ask anything", "Generating…" while a reply streams. Disabled with no model |
| Send / Stop | Green ↑ to send; red ■ to stop while generating |

## 3.2 Sending a message

1. Ignore empty text, or if a reply is already running.
2. Check a model is active and its file exists. Otherwise toast "Load a model from the Models tab first." / "Active model is missing from disk."
3. Decide if this turn needs a web search (see 3.6).
4. Save the user message and an empty assistant placeholder immediately.
5. If searching, run the search and attach sources to the placeholder.
6. Build the prompt (3.4), trim it to the context window (3.5), send it to the engine.
7. Stream tokens into the placeholder. Engine errors are shown as a toast (6 s) and **not** saved as reply text.
8. When done (or stopped), save the conversation.

**Stop:** cancels the search or the generation. A partial reply is kept as is.

**Not available:** regenerate, edit a message, delete one message, continue, per-message speed stats (they are measured but not shown).

## 3.3 Conversations (drawer)

| Feature | Behaviour |
|---|---|
| New chat | Clears the screen. The conversation is only created and saved when the first message is sent |
| On app launch | Always opens a blank new chat (the last open chat is not restored) |
| List | Newest first, grouped **Today / Yesterday / Previous 7 Days / This Month / Older** |
| Title | Your custom name, else the first message cut to 48 chars + "…", else "New chat". No AI-generated titles |
| Search | Live filter on title and the last message preview (≤ 70 chars). Does not search full text |
| Options (⋯ or long-press) | **Select** (enter manage mode), **Rename** (dialog "Rename chat"), **Delete chat** ("Delete chat?" confirm) |
| Manage chats | Multi-select with checkboxes, Select all / Deselect all, **Delete (n)** with confirm, Done |
| Footer | Manage chats (n conversations), Model Settings, App Settings, About Thinai |

**Limits:** max 40 conversations; per conversation max 200 messages and 120,000 characters (oldest dropped first). No pinning, no export.

## 3.4 What the model receives (prompt assembly)

Messages are built in this order. Two messages in a row with the same role are merged, because some model templates (Gemma) reject that.

1. **System:** the system prompt (if not empty).
2. **System (added):** the document, if one is attached, wrapped in a fenced block with "answer using only what it contains".
3. **System (added):** web-search rules, if this turn searched or the previous reply had sources.
4. **All earlier messages** as plain text.
5. **User:** the question, with web results in front if searched (or the previous reply's sources for a follow-up), and the image as an inline `<img src="data:...;base64,...">` tag if attached.

**Prompt-injection guard:** text from documents and web pages is "neutralized" first: special model tokens (`<|`, `<think>`, `[INST]`, `<<SYS>>`, `<img`, etc.) are broken up and fake fences are removed, then the text is wrapped in `<<<LABEL>>> … <<<END LABEL>>>`. The system rules tell the model not to follow instructions inside fences. (`lib/chat/untrusted_text.dart`)

## 3.5 Fitting the context window

Code: `lib/chat/prompt_budget.dart`.
- Budget = context window − reply reserve (`max(context/4, 512)` tokens).
- Token estimate = characters ÷ 3.2 + 8 per message.
- If too long: drop the oldest turns first (keeping the system message), then shorten the system message, then the last user message by cutting the middle (`…[trimmed to fit the context window]…`).
- Known bugs here (crash and broken images): see [09-known-issues.md](09-known-issues.md#chat).

## 3.6 Web search

Code: `lib/web/web_search.dart`.

| Rule | Detail |
|---|---|
| Toggle | Global, saved, **on by default**. In the + menu and in Settings → Appearance |
| When it runs | Only if the toggle is on **and** no document or image is attached **and** the question looks like it needs fresh facts: words like news, latest, today, price, weather, score, "who is", or a year. Never for local tasks (write, translate, code, poem...). "Search the web" forces it; "don't search" blocks it |
| Query | The question with filler removed ("please search for..."). Follow-ups borrow key words from the previous question. Max 240 chars |
| Engines | No API keys. Tries DuckDuckGo Lite → DuckDuckGo HTML → Bing (HTML scraping). An engine that blocks or rate-limits is rested for 10 minutes |
| Results | Up to 5, filtered for relevance. The top result's page is also fetched (except social sites) and the best paragraphs (≤ 1,500 chars) are added |
| Answer style | The model is told today's date and to answer in 2–4 sentences, citing `[1]`, `[2]` |
| Sources | Saved on the reply. Shown as a pill with letter badges; tap → Sources sheet with the searched query and each source (domain, number, title, snippet). Tap a source to open it in the browser (seen on device) |
| Follow-ups | The next question (without a new search) includes up to 3 of the previous sources |
| Failure | The reply goes ahead without search, with a toast: "No web results. Answering without them.", "Web search is blocked right now...", or a network error |
| Privacy | Only the search query and a fetch of the top result page leave the device. The chat, model and attachments stay local |

## 3.7 Attachments

| | Document | Image | Camera |
|---|---|---|---|
| Types | ~45 text/code extensions (txt, md, csv, json, py, dart, ...). Unknown types are accepted if they are valid UTF-8 text | PNG, JPEG, WebP, BMP, GIF | System camera app, max 1600 px, JPEG quality 85 |
| Rejected | PDF ("not supported yet"), Word, PowerPoint, Excel, EPUB, binary, empty, non-UTF-8 | Unknown type, empty, > 8 MB | — |
| Size | Text over **20,000 characters** is cut; toast "Attached the first ...". | 8 MB max | — |
| Needs | Any chat model | A **vision** model with its projector downloaded. Otherwise toast "This model cannot read images..." before the picker opens | Same as Image |

- One image and one document at a time; picking again replaces.
- **Important:** attachments stay on the composer until you tap ✕. They are re-sent with every later message, and even carry over to another chat. They are not saved with the conversation. See [09-known-issues.md](09-known-issues.md#chat).

## 3.8 System prompt

Settings → **System Prompt** (code: `lib/chat/system_prompt.dart`, `lib/ui/pages/system_prompt_page.dart`).
- **Default (English UI):** "You are Thinai, a helpful AI assistant that runs privately on the user's phone. Answer clearly and concisely, and say so when you are not sure." (seen on device, 143 characters)
- **Default (Tamil UI):** the same, plus "Always reply in Tamil (தமிழ்) unless the user asks for another language."
- Editable text box with a character count, **Save**, **Reset to default**. Leaving the page also saves.
- Empty = no system message (the model's own default applies).
- Applies to Chat only. API clients send their own.

## 3.9 Model switching and model settings

- **Switch Model sheet** (seen on device): "Switch Model", "n installed", radio list of installed models (file name, size, id), a tune icon on the selected one ("Model Parameters"), and **Download More Models**.
- **Model settings sheet** (seen on device): "Applies to chat and the server." Saved per model, no Save button.

| Setting | Range | Default |
|---|---|---|
| Context window | 512 up to the model's cap, in powers of 2 | 8K (or the cap if smaller) |
| Temperature | 0 – 2.0, step 0.05 ("Precise" ↔ "Creative") | 0.70 |
| Top-K | 0 – 100 (0 = off) | 40 |
| Top-P | 0.05 – 1.00 (1.00 = off) | 0.95 |
| Thinking | On/Off. Only shown if the model's template supports `enable_thinking` | On |

A **Reset to defaults** button clears the model's saved values. Max tokens, repeat penalty, min-p and seed are not exposed.

Thinking text from reasoning models is **not** separated or hidden in Chat (not verified on device). See [09-known-issues.md](09-known-issues.md#chat).
