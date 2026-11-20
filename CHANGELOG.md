# Changelog

[Latest release: all changes since 0.18.0-beta7](docs/RELEASE-0.18.0-beta11.md)

[Earlier cumulative notes: changes since 0.17.5](docs/CURSEFORGE_CHANGELOG_0.18.0-beta5.md)

## 0.18.0-beta11 — 2026-11-20

- Fix release-history separators displaying as missing-glyph boxes with the game font. Use standard hyphens supported by the existing UI font.
- Add **Bugs and news** to the addon options with **[@alejandrosena](https://x.com/alejandrosena)** for bug reports and QuestLore updates. Provide a selectable, copyable profile URL and instructions in all seven interface languages.
- Add saved-profile regression coverage for background transparency at **0%, 37% and 100%**, enabled and disabled backgrounds, and repeated reloads/upgrades. Verify language choices, text size, guide integrations, attachment, visibility, minimization, three-window geometry and existing history.
- Preserve existing preferences per character; no preference-reset defect was found in this review.
- Reuse the same independent, read-only URL field behavior for the X and CurseForge links.

## 0.18.0-beta10 — 2026-11-20

- Add Russian for all **5,259 quest narratives**, **90 race/class introductions**, **2,163 encyclopedia articles**, and the interface. These provisional English-based translations retain English proper names and encyclopedia titles. Quest titles and original full text still use the game client’s language.
- Keep the existing German summaries, encyclopedia and interface available.
- Shorten the post-update notice to **“Updated - See what’s new”**, translated into each interface language.
- Keep a notice pending until opened or dismissed, then remember that acknowledgement for that version per character, including after reloads or reinstalling a previously acknowledged version.
- Show the **last five releases**, newest first, in **Options → AddOns → QuestLore → What’s new**.
- Add a selectable link to copy to the complete changelog on CurseForge. WoW does not launch web pages directly.
- Preserve existing settings, saved window positions, narrative-language defaults and the Polish contributor credit.

## 0.18.0-beta9 — 2026-11-20

- Save encyclopedia window position and size per character, restoring them after login or a UI reload. Keep saved geometry when switching articles or languages, and fit it safely within the current screen.
- Reuse a shared pool of encyclopedia link controls for visible history entries instead of retaining a separate set for every story visited.
- Defer hidden history feed rebuilds until the panel is opened, and reuse entity matching results during font-size and width changes.
- Retain the existing limit of **200 unique stories per character**, newest first. Existing preferences and saved Lore/full-text window geometry are preserved.
- Add regression coverage for encyclopedia geometry, profile isolation, settings preservation and a complete 200-story history traversal.

## 0.18.0-beta8 — 2026-11-20

- Add a discreet, dismissible **what’s new** notice below Lore after installing a newer QuestLore release.
- Click the notice to open the installed version’s release notes, or dismiss it. Remember the acknowledgement per character so it does not return on every reload.
- Add **Options → AddOns → QuestLore → What’s new**, with scrollable notes available even after dismissing the notice.
- Add **Show update notices**, enabled by default. Keep the notice hidden while Lore is minimized and account for its height when text wraps or the window is resized.
- Translate notices and installed release notes into all six interface languages.
- Keep the update feature entirely local: it displays bundled notes after an installed update and adds no online version checks, addon-message exchange or polling timers.
- Add the creator credit linking to **[@alejandrosena](https://x.com/alejandrosena)** to the CurseForge description and retain it in the publication guidelines.

## 0.18.0-beta7 — 2026-11-20

- Add **Polish** as a selectable narrative and interface language, with **5,259 quest summaries and 90 race/class introductions** contributed by **[dawiss](https://github.com/dawiss)** in [issue #2](https://github.com/mexiar/QuestLore/issues/2). Thank you for helping bring QuestLore to Polish-speaking players!
- Adapt the community contribution to the current addon and complete Polish interface strings for the encyclopedia, background transparency, story history, quest-focus priority and full-text button setting.
- Add Polish translations for all **2,163 encyclopedia entities**, bringing the encyclopedia to **12,978 articles across six languages**. These provisional articles are translated from English and retain English proper names and titles.
- Open Polish encyclopedia articles from Polish summaries, history and character introductions. Recognize reviewed inflected character names while preserving shared-name and spoiler-sensitive restrictions.
- Preserve existing language choices and the automatic Spanish/English narrative defaults. Select **Polski** in addon settings; the interface language remains independently configurable.
- Review a sample of the contributed narratives and introductions, apply source-checked editorial corrections, and validate the complete Polish catalog, source hashes, names, links and layout behavior.

## 0.18.0-beta6 — 2026-11-19

- Add a per-character **Show full quest text button** option, enabled by default for new and existing characters.
- Hide or restore the action immediately in live Lore and story history, reclaiming its space without changing the selected quest.
- Preserve the preference through reloads, minimization, font changes and language changes.
- Localize the new option in all five interface languages. Keep literal fallback previews clickable independently of the button preference.

## 0.18.0-beta5 — 2026-11-18

- Add French, German and Brazilian Portuguese translations for all 2,163 encyclopedia entities: 6,489 new articles, bringing the five-language catalog to 10,815 articles.
- Open encyclopedia articles in the narrative language from live summaries, history and character introductions. Keep contextual article links in that language and interface controls in the chosen interface language.
- Preserve English entity titles, aliases and proper names in the three additional banks, matching the existing provisional narrative translation policy.
- Reuse the reviewed English identity restrictions across translated links, including shared names and spoiler-sensitive aliases. Support French apostrophe elisions and German genitive endings around linked names.
- Update the language-support notice in all five interfaces to include encyclopedia translations.
- Validate complete language coverage, current English-source hashes, protected-name preservation and language-aware navigation during packaging.
- Keep English and Latin American Spanish encyclopedia articles and all existing quest narratives unchanged. Translations are prepared offline, with sampled editorial review and no online translation during play.

## 0.18.0-beta4 — 2026-11-18

- Expand the encyclopedia from the four-entry Spanish pilot to **2,163 entities and 4,326 articles** in English and Latin American Spanish, covering characters, places, organizations, objects, peoples, events and concepts, including Forever-specific entities.
- Open English articles from English narratives and Latin American Spanish articles from Spanish narratives. Keep reader controls in the independently selected interface language.
- Link recognized names in active quest summaries, story history and race/class introductions, with contextual links inside articles. Preserve the active quest while reading.
- Keep names yellow without underlines and retain the focused reader without an entry index or settings launcher.
- Improve identity matching with localized aliases, reviewed quest scopes and longest-name priority. Leave uncertain shared names unlinked and avoid revealing hidden identities or later quest outcomes.
- Index aliases once at load to avoid scanning the whole encyclopedia for each displayed name. Add no online requests or polling timers.
- Add source-provenance checks and bilingual regression tests for matching, navigation, language separation, punctuation and spoiler-sensitive names.
- Preserve existing narratives, the original Spanish pilot articles and the active-quest-only policy for full quest text.

## 0.18.0-beta3 — 2026-11-18

- Display story history as a continuous, newest-first feed with titles, narratives and separators instead of mission selection buttons.
- Open full quest text from history while that quest remains active, without changing the current focused quest. Keep original text session-only; do not archive it.
- Include encyclopedia links in history narratives and contextual cross-references inside encyclopedia articles.
- Keep linked names yellow without underlines. Remove the encyclopedia entry index, settings launcher and language-availability subtitle; open the reader from the clicked name.
- Reflow the history feed for font and panel size changes, and defer interactive link rendering until entries enter the viewport.

## 0.18.0-beta2 — 2026-11-18

- Give the active quest selected in the journal or focused in the native tracker priority over Polestar and RestedXP.
- Preserve explicit selection when guide targets change. Fall back to guides when the selected/focused quest is cleared or no longer active.
- Avoid repeated Polestar redraws while another quest has focus. Update the localized settings description to reflect the new priority.
- Retain the Spanish encyclopedia pilot from beta1.

## 0.18.0-beta1 — 2026-11-18

- Add a Spanish encyclopedia pilot with four canonical entries: Orgnil Escaralma, Filo Ardiente, Durotar and Libro del conciliábulo.
- Highlight recognized names in Spanish quest narratives in yellow with underlines. Click a name to open its independent reference article without changing the active quest or story history.
- Add a movable, resizable, scrollable encyclopedia reader and an entry index, also accessible from addon settings.
- Preserve linked text through font changes, wrapping, scrolling and the wide detached layout. Keep unknown names, other narrative languages and original quest text unchanged.
- Restrict the Filo Ardiente cult link to reviewed quest contexts to avoid confusing similarly named groups. This pilot does not provide a complete entity catalog.

## 0.17.5 — 2026-11-18

- Add an optional black background for the Lore window, both attached to the quest tracker and detached.
- Add a live background transparency slider: 0% is opaque and 100% is transparent. Text and controls retain their own opacity.
- Save the background toggle and transparency per character. Keep the background disabled by default and preserve its preferred value when toggled off.
- Let the background follow resizing and minimization. Localize the new settings in all five interface languages.

## 0.17.4 — 2026-11-17

- Complete interface localization in English, Latin American Spanish, French, German and Brazilian Portuguese, including tracker headings, key bindings, tooltips, loading states, settings and history.
- Add a separate per-character interface-language selector. Automatic UI language follows supported game locales and falls back to English; narrative language remains independent.
- Preserve existing explicit language choices when upgrading. Update interface text immediately when its language changes, including the registered history category.
- Allow long translated settings labels and buttons to wrap, and reserve the full height of a wrapped original-text action so it does not overlap the narrative.
- Localize AddOns list descriptions and categories. Keep quest names and original quest text in the game client's language.

## 0.17.3 — 2026-11-17

- Update 404 Latin American Spanish narratives using recovered original esMX quest records: rewrite 35 stories and correct source-attested names in another 369.
- Use current client names such as Corma Villardo, Velarok Espada del Viento, Picoflojo, Garracha and Cromi. Resolve ambiguous references to families, wells and ships in context rather than blindly replacing NPC names.
- Add or correct 4,055 Spanish fallback titles from validated client records. The active quest's localized game title continues to take priority.
- Preserve differences between localized originals, including Galgar's esMX offer, and keep summaries limited to the current quest step.
- Keep English, French, German and Portuguese narrative text unchanged. Missing, unvalidated or placeholder original descriptions do not trigger narrative rewrites.

## 0.17.2 — 2026-11-17

- Revise 34 English quest narratives against recovered, validated Forever client descriptions and objectives, including newly available original descriptions.
- Update the corresponding 102 French, German and Brazilian Portuguese narratives, preserving English proper names. Keep Latin American Spanish narratives and titles unchanged.
- Correct current-step context for sayaad training, Corma Villard, the Gnarlpine bounty, Kerlonian's missing belongings, Othmar and other changed assignments. Use Velarok Windblade's current English name throughout the relevant Searing Gorge stories.
- Correct six English fallback quest titles to match the client. Localized titles returned by the player's client continue to take priority.
- Leave narratives with missing, unvalidated or placeholder originals unchanged. Original client dialogue remains outside the addon package; these revisions do not imply complete original-text collection.

## 0.17.1 — 2026-11-17

- Prefer the localized quest title returned by the game client in every summary language, including French, German and Portuguese and English-body fallbacks.
- Keep English proper names inside English-derived narratives; use catalog titles only when the client has no title available.
- Preserve known localized quest titles when switching archived narratives between languages, and update language-support documentation.

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
