# 0.18.0-beta5 — Changes since 0.17.5

## New: a five-language lore encyclopedia

- Add **2,163 encyclopedia entities and 10,815 articles** covering characters, places, organizations, objects, peoples, events and concepts, including Forever-specific content.
- Highlight recognized names in yellow, without underlines, in active quest summaries, story history and race/class introductions. Click a name to read its independent reference article.
- Follow related names inside articles without changing the active quest or adding entries to story history.
- Add a movable, resizable, scrollable encyclopedia reader. It opens from the name you click, without an entry index or a separate settings launcher.
- Open articles in the narrative language while keeping reader controls in the independently selected interface language.
- Provide source-based English and Latin American Spanish articles. French, German and Brazilian Portuguese articles are **provisional translations from English**, retaining English proper names, article titles and aliases.
- Use reviewed identity restrictions and longer-name matching to distinguish shared names and protect spoiler-sensitive identities. Unknown or uncertain names remain plain text.
- Support French apostrophe elisions and German genitive endings around linked names.

## Focused quests take priority

- Give an active quest selected in the journal or focused in the native tracker priority over Polestar and RestedXP.
- Preserve that selection when guide targets change. Return to guide following when the focus is cleared or the quest leaves the log.
- Avoid unnecessary Polestar redraws while another quest has focus, and update the settings description to explain the selection priority.

## Redesigned story history

- Replace mission selection buttons with a **continuous, newest-first feed**, showing each quest title and complete narrative, separated by a line.
- Include encyclopedia links throughout the history feed.
- Offer **Read full quest text** from history while the corresponding quest remains active, without replacing the current focused summary.
- Keep original quest text session-only; completed and abandoned quests retain their summaries rather than permanent copies of the originals.
- Reflow history for font and panel-size changes and render interactive name links as entries enter the viewport.

## Performance, language support and validation

- Update the language-support notice in all five interfaces to include the encyclopedia and explain English-derived translations.
- Build name indexes once at load and share the English-name index across the three additional languages. The encyclopedia adds no online requests or polling timers.
- Add source, translation and regression checks covering all article IDs, English-source hashes, protected names, language-aware navigation, ambiguous identities and layout behavior.
- Apply source-based terminology corrections and sampled editorial review to the additional translations. These remain provisional rather than fully reviewed native-language text.
- Preserve existing quest narratives and the original English and Latin American Spanish encyclopedia prose.
