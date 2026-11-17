**QuestLore 0.17.0 — Languages, full quest text, and guide integration**

- Add French, German and Brazilian Portuguese beta banks: 5,259 quest summaries and 90 race/class introductions per language. These English-derived translations retain English proper names and quest titles; linguistic review remains partial.
- Preserve complete English and Latin American Spanish narrative coverage and automatic Spanish/English defaults; add manual beta-language choices and support information in options.
- Add **Read full quest text** for quests in the current log, displaying the original description and objectives in the game client's language.
- Add a movable, resizable full-text reader with complete scrolling, live font-size changes and a standard WoW close button. Save its size and position per character and clamp restored geometry to the screen.
- Add literal original-text previews for quests without a usable summary. Previews end in **…**; clicking opens the unabridged original. Preserve client-language wording independently of the summary language, including objective-only quests and UTF-8 text.
- Keep originals and previews out of saved story history; remove legacy saved source caches. Clear the full-text reader on close, quest removal or context changes.
- Align the full-text action with the summary's left margin, remove the reader subtitle and bottom back button, and prevent an empty reader reappearing after Alt+Z.
- Add optional direct **RestedXP integration**, saved per character, following its accepted arrow quest or an unambiguous current guide step. Use isolated guide-event subscriptions and one local recovery check; steady targets do not redraw.
- Preserve Polestar priority when both guide integrations are enabled, with ordinary quest selection as the fallback. Questie continues to work through normal quest selection and focus controls.
- Improve scrolling in the options panel for longer translated labels and expand automated coverage for guides, original-text previews, reader geometry, source cleanup and all translated entries.
- All narrative banks are bundled locally; no online AI or translation service runs during play.

Install **QuestLore-0.17.0.zip** from the assets below. Extract its QuestLore folder into `_forever_/Interface/AddOns/` and use `/reload` after updating.
