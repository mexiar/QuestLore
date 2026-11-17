# Changelog

## 0.17.0 — 2026-11-17

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

## 0.17.0-rc4 — 2026-11-17

- Add optional direct RestedXP following via its accepted arrow quest or an unambiguous current guide step, with a per-character switch.
- Observe guide messages through a private AceEvent listener and recover silent changes with one local timer; unchanged targets do not redraw.
- Keep Polestar priority when both guide integrations are enabled, and normal quest selection as the fallback.
- Update CurseForge description with full base-language coverage, partial translations, original quest reading and accurately scoped addon compatibility.

## 0.17.0-rc3 — 2026-11-17

- Remember the original quest-text reader's dimensions and position per character, including across reloads.
- Clamp restored reader geometry to the current screen and discard invalid saved dimensions.

## 0.17.0-rc2 — 2026-11-17

- Resize the original quest-text reader from its bottom-right corner, with live text and scroll reflow.
- Replace the bottom Back to summary button with WoW's standard top-right close button.
- Remove the original-text subtitle and align the full-text action with the summary's left margin.

## 0.17.0-rc1

- Add French, German and Brazilian Portuguese summaries translated from the existing English narratives, with English proper names retained. These translations are provisional; they are not original localized client text.
- Add explicit opt-in language choices for the new beta banks; preserve automatic Spanish/English defaults. Identify the Spanish base explicitly as Latin American Spanish.
- Explain language support and localization limitations in the addon options, including the pending original-name audit of the existing Spanish bank.
- Add **Read full text** for the current active quest. It opens the original client-language description and objectives in a separate scrollable reader.
- Keep original dialogue out of SavedVariables and the story archive. Remove older saved source caches and retain only in-session sources for active quests.
- Translate the options and reader controls, and place options in a measured scroll panel so longer labels do not overlap.
- Preserve native tracker attachment, detached banner, font-size controls and complete scrolling.


## 0.16.3

- Keep minimize/restore always visible when attached to the quest tracker. Detached windows retain hover-only controls.

## 0.16.2

- Show the minimize/restore control only while hovering Lore, including its collapsed title bar and attached tracker mode. Reuse existing mouse events without adding polling.

## 0.16.1

- Show the detached resize icon only while hovering the window, keeping it visible throughout an active resize drag. No hover polling timer is added.

## 0.16.0

- Add an automatic horizontal layout when detached Lore is wider than its expanded height.
- Replace the Lore header with the centered quest title using the native header font; remove the repeated content title in this mode.
- Fully justify narrative paragraphs with a reusable word pool, keeping final paragraph lines left aligned and preserving long tokens.
- Remove the addon-imposed maximum width and allow shallow windows, while leaving room for a readable line below wrapped headers.
- Preserve the banner layout through minimize/restore and saved per-character dimensions; reattachment always restores the native tracker layout.
- Add 312 horizontal layout cases alongside the 590 geometry cases and existing runtime suite.

## 0.15.6

- Move the Lore minimize/expand control six UI units right to align with the native quest header control.

## 0.15.5

- Match the quest title font size to the narrative text size while preserving its yellow color. Both follow the text-size option.

## 0.15.4

- Centralize complete text measurement and derive overflow from the current frame height and actual content geometry.
- Clamp scrolling against the measured content/viewport range instead of a possibly stale native range cache.
- Preserve reading position across font changes and the tracker's later height adjustment.
- Recheck layout once after geometry changes settle; prevent stable rechecks from repeatedly dirtying the host.
- Guard against the native template showing an unnecessary scrollbar, and allow unlimited wrapped title/body lines.
- Add 590 geometry cases covering all 12–24 font sizes, widths, available heights, ES/EN text, paragraphs, long tokens, minimized restore, detached resize, and delayed native scroll ranges.
- Replace the old fixed-range test assumption with independently derived viewport bounds, checking that the last line remains reachable.

## 0.15.3

- Fix narrative ellipsis/clipping without a scrollbar after the 0.15.2 text-height change.
- Clear previous title/body height constraints before measuring; leave narrative text naturally sized.
- Preserve complete text in the scroll child so a genuine viewport limit produces scrolling instead of ellipsis.
- Model bounded FontString measurements in the simulated client and test short-to-long, constrained-to-expanded, and stale-height transitions.

## 0.15.2

- Reflow attached Lore after sibling tracker sections move or collapse, reclaiming released space once their anchors settle.
- Measure desired section height from full-width text instead of the previous scrollbar-wrapped content.
- Round measured text heights up to whole UI units and size text regions explicitly to avoid clipping at fit boundaries.
- Keep the scrollbar only when the full narrative exceeds the space allocated by the host.
- Observe geometry with an addon-owned probe and coalesced deferred reflow; no additional layout polling timer.
- Test crowded-to-expanded tracker transitions, gutter recovery, stable repeated passes, detachment, and combat deferral.

## 0.15.1

- Keep Polestar's accepted quest authoritative while following is enabled, including when the game selects a newly accepted side quest.
- Remove the manual-selection latch that could leave Lore on another quest until a guide goal changed.
- Add a one-second local target check to recover missed or late waypoint events.
- Reread the target on ordinary quest updates, acceptance, turn-in, and removal.
- Avoid repeated redraws for unchanged targets; cancel the safety timer on disable.
- Test side-quest acceptance/completion, silent target changes, idle redraws, and ticker lifecycle.

## 0.15.0

- Follow Polestar's accepted navigation quest directly through its target-change events.
- Add a bilingual per-character toggle, enabled by default, without requiring Polestar.
- Support initial and late addon load, area/search objectives, and accepted turn-in targets.
- Respect explicit manual quest selection until the next changed quest/guide goal.
- Fall back for manual pins, acceptance recommendations, unaccepted or removed quests, missing targets, and unavailable APIs.
- Unsubscribe on disable without changing Polestar's navigation or native quest tracking.
- Test subscription lifecycle, duplicate events, fallback, errors, re-enabling, and saved preferences.

## 0.14.0

- Remove all pagination, Current/History labels, and counters from live Lore.
- Keep live Lore on the active quest while archived stories are read independently.
- Add a native AddOns history subcategory, scrollable story list, and full narrative reader.
- Preserve existing per-character history and replace history navigation key bindings with an Open history action.
- Reduce reserved bottom space in the live section.
- Publish source, English documentation, MIT license, tests, and a standalone packaging command.
- Add project artwork and ready-to-paste CurseForge copy.
- Document Polestar integration feasibility and limits without enabling an untested direct bridge.

## 0.13.1

- Reread 5,259 bilingual quest narratives and 90 bilingual race/class openings.
- Correct 400 quest rows and three opening combinations for language, narrative quality, supported context, and current-step chronology.

## 0.13.0

- Complete the audited quest corpus: 5,259 bilingual narratives across 5,413 classified records.
- Preserve 154 evidence-backed exclusions, with no pending narratives.
