# Encyclopedia languages

QuestLore bundles **2,163 entities and 15,141 reference articles** across seven languages. English and Latin American Spanish are source-based authored banks; French, German, Brazilian Portuguese and Russian are provisional English-based translations that retain English names. Polish articles are directly translated by AI authors from the complete English articles after two raw MT methods failed semantic review. They retain English names and do not claim native-human review. Each person, place, organization, object, people, event or concept has a stable canonical ID, localized names and aliases, and one article per language. The reference text describes the entity itself rather than repeating quest instructions.

## Reading and navigation

Recognized names appear in yellow, without underlines, in quest narratives, the newest-first history feed and race/class introductions. Clicking opens the corresponding article in the narrative language. Related names inside articles open articles in that same language. Interface labels follow the independently selected interface language.

The reader is movable, resizable and scrollable. There is no entry index, settings launcher or availability subtitle. Opening an article does not change the focused quest or create a history record. French, German, Portuguese and Polish narratives open their corresponding translated article, with English names retained. Original quest text and literal previews remain unchanged.

## Identity and chronology

Matching uses explicit localized aliases, word boundaries and a prefix index built once at load. Longer overlapping names take precedence. Shared names and ambiguous short aliases require reviewed quest context or explicit article references; unresolved identities remain plain text. This prevents a surname, a common word or a shorter adjacent name from opening an unrelated article.

Articles avoid later quest-chain outcomes, hidden identities and unsupported biographies. The database is substantial coverage of the quest catalog, not an exhaustive encyclopedia of every Warcraft entity. A few names remain unlinked where original localized evidence is unavailable or identity is uncertain. Generic fragments in the research candidate inventory do not constitute missing-entity counts.

## Sources and validation

The private source banks under `research/encyclopedia/entries-*.json` record evidence separately from distributable prose. Evidence includes the collected English and esMX client quest records, archived quest dialogue, localized NPC/item metadata and documented historical references. Current client records take priority over conflicting archived text. Source snapshots and provenance hashes remain outside the addon ZIP.

`tools/audit_encyclopedia_translations.py` verifies completeness, source hashes and protected English names for the additional languages. `tools/build_encyclopedia.py` validates all seven languages, canonical identities, explicit aliases, source references and cross-references, then generates `QuestLore/Encyclopedia_Data.lua`. `tools/audit_encyclopedia.py` checks name attestation and snapshot integrity. Name attestation alone does not independently validate every biographical sentence; the source-based editorial reviews are recorded separately.

The Lua 5.1 suite checks seven-language links, article navigation, ambiguous names, scoped aliases, punctuation, overlapping phrases, language separation, history and layout behavior. Runtime coverage reports examine all 5,259 narratives and 90 introduction variants per language. All encyclopedia data is local: no web requests, AI calls, new polling timer or gameplay text collection is introduced.

The encyclopedia does not store original text from completed quests. Full quest text remains available only for active quests under the existing session-only reader policy.

Polish character-name case endings are recognized only for reviewed identity contexts. English source matching resolves the canonical owner first, so a short name cannot borrow authorization from another character’s longer name. Unsupported or ambiguous forms remain plain text. Direct Polish authorship and its source checks are documented in `research/encyclopedia/polish-authorship/REPORT.md`.

## In-game verification

1. Run `/reload`, choose Spanish narratives and select **Oscuras tormentas** (806). Open Orgnil, Filo Ardiente and Durotar.
2. Switch narratives to English and verify the article language changes independently of interface settings.
3. Follow a related article link. Confirm that no index appears and the active quest stays unchanged.
4. Test history, attached Lore, wide detached Lore, font changes, wrapping and scrolling.
5. Check shared names in the reviewed quest contexts and confirm unsupported names remain plain text.

Automated validation is complete for the packaged code. Native Forever visual verification still requires running the client; simulated layout checks are not in-game screenshots.

Encyclopedia window size and position are saved per character from 0.18.0-beta9 onward, on movement, resizing and close. Saved geometry is restored once per session and bounded to the current screen. Earlier releases did not persist this window geometry, so an old unsaved location cannot be recovered.
