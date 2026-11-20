# Languages and original quest text

QuestLore's base narrative banks are English and Latin American Spanish. The
existing Spanish bank is still undergoing an audit against original esMX names;
"available in Spanish" does not mean every proper name has been client-verified.
A Spanish (Spain) client currently uses the explicitly labeled Latin American
Spanish narrative bank.

French, German, Brazilian Portuguese and Russian summaries are provisional translations
of the English narrative bank. They retain English proper names inside the narrative. The displayed quest title
uses the localized name from the game client, independently of summary language;
a catalog title is only a fallback when the client has no title available.
They are not summaries generated from independently collected original
French, German, Portuguese or Russian quest descriptions. The addon options explain this
distinction. A missing translated entry falls back to English with its actual
language retained in the model metadata.

Automatic summary language selection keeps the established Spanish/English defaults: esMX/esES use Latin American Spanish and other clients use English. French, German, Brazilian Portuguese and Russian beta banks require an explicit per-character manual choice while editorial review is incomplete. Locale resolution also recognizes ptPT as the Brazilian Portuguese bank when explicitly requested.

## Polish community contribution

[dawiss](https://github.com/dawiss) contributed all 5,259 Polish quest narratives,
90 race/class introductions and the initial interface translation in
[issue #2](https://github.com/mexiar/QuestLore/issues/2). The maintainers adapted
that contribution to the latest addon, translated the newer interface controls
and completed the Polish encyclopedia. Choose **Polski** manually in the story
and/or interface language selectors. The established automatic narrative policy
remains Spanish for Spanish clients and English otherwise.

The quest contribution uses natural Polish declensions of English names. A
reviewed subset of undeformed character-name stems can still link to their
encyclopedia entries when inflected; ambiguous identities and unrecognized
forms remain plain text. No generic Polish stemming is applied to names.

Polish encyclopedia articles are translated directly from the complete English
articles by AI authors after raw automatic-translation experiments failed
semantic review. English proper names and article titles are retained. They
are not official localized client descriptions or native-human-certified prose.

## Encyclopedia languages

All 2,163 encyclopedia entities have articles in English, Latin American Spanish,
French, German, Brazilian Portuguese, Polish and Russian. An article opens in the language of the
narrative link, independently of the interface language. Related article links
retain that language. French, German, Brazilian Portuguese and Russian are provisional translations
of the English articles; their titles, aliases and proper names remain English.
They are not official localized game descriptions. Their links reuse the same
reviewed English identity scopes and do not grant ambiguous names wider access.

The French, German and Portuguese encyclopedia prose uses local machine translation with protected
names and sampled AI editorial review. Automated checks cover every article's
presence, current English-source hash and protected-name preservation; they do
not establish complete semantic accuracy or native-language review.

## Interface language

The interface is available in English, Latin American Spanish, French, German,
Brazilian Portuguese, Polish and Russian. **Interface language** has its own per-character
selector, separate from **Story language**. Its automatic mode recognizes
enUS/enGB, esMX/esES, frFR, deDE, ptBR/ptPT, plPL and ruRU; other game locales use English.
The narrative automatic policy described above is unchanged.

Switching the interface updates the settings, history category, tracker heading,
tooltips, loading states and key-binding labels without changing narrative text
or original client dialogue. Language choices use native names so they remain
recognizable after an accidental selection. On upgrade, an existing explicit
language preference is initially retained for the interface as well; characters
using automatic mode receive native interface detection. Both choices can then
be changed independently. Fully translated interface controls do not change the
beta status of the French, German and Portuguese narrative banks.

## Read full text

The **Read full text** action appears only for the current quest while it is
still in the player's quest log. It opens the original description and objective
paragraph returned by the game, in a separate native-style scrollable reader. Drag its bottom-right corner to resize
it; its position and dimensions are saved per character. Use the standard
top-right close button to return to the summary.

This text follows the **game client's language**, independently of the summary
language chosen in QuestLore. Changing the summary language does not translate
the original quest dialogue. For example, a French client can show an English
summary and its original French quest text.

The reader does not shorten the description or use an archived narrative as a
substitute. It clears its text on close, context change or quest removal. History can open original text while the corresponding quest remains active.
The full-text button can be hidden in settings; the preference applies to Lore
and history. No full-text action is provided for race/class introductions.

When a quest has no usable authored summary, Lore shows a short literal preview
of its original client-language description/objectives, ending in **…**. Clicking
the preview opens the full-text reader. This preview is not translated to match
the selected summary language and is never archived. Empty originals remain an
explicit loading or unavailable state.

## Source storage and history

Original descriptions are retained only in memory for quests still active in the
log. QuestLore removes older releases' saved source caches on initialization and
prunes inactive in-session sources even when the Lore window is hidden.

The per-character archive keeps up to 200 authored narrative summaries and
introductions. Raw descriptions and extractive source fallbacks are not archived.
Old source extracts can be replaced by an available authored summary during
migration; otherwise the old original text is dropped.

The history feed can open original text for any quest still active in the log,
without changing the current live summary. Inactive entries keep their narratives
but cannot open original text. No original dialogue is added to saved history.

These rules concern QuestLore's own data. The WoW client manages its own quest
cache independently.

## English client-source reconciliation

Version 0.17.2 revises 34 English narratives against validated original Forever
client descriptions and current-step objectives collected on build 70959. Their
French, German and Brazilian Portuguese versions were revised from that English
text, retaining English proper names. Latin American Spanish was left unchanged
for its separate original-language review. Six English fallback quest titles
were also corrected; client-localized titles still take priority.

This is an incremental source correction, not a claim that every original
English description was recovered. Missing originals, unvalidated parses and
placeholder descriptions do not trigger automatic rewrites. These stories use
the current assignment, without importing later completion dialogue or future
chain events. The targeted translations were authored and reviewed with AI;
they have not received native human review.

## Latin American Spanish client-source reconciliation

Version 0.17.3 updates 404 Spanish narratives against original esMX quest data:
35 stories were rewritten and 369 received source-attested name corrections.
It also adds or corrects 4,055 Spanish fallback titles from validated client
records. The English, French, German and Portuguese narrative text is unchanged.

The review uses the Spanish descriptions and current objectives directly,
preserving localized names and differences between language versions. For
example, the recovered esMX text of Galgar's quest does not mention the training
manual offered by the English original, so its Spanish summary does not add it.
Names shared with earlier known context may use another validated esMX record
as evidence. Families, wells and ships are distinguished from similarly named
NPCs. Later completion text is excluded.

This remains an incremental audit: the saved esMX cache contains 4,463 catalog
records, with 3,649 nonempty descriptions validated by the current parser.
Missing, unvalidated and placeholder descriptions are not treated as complete
originals. Existing narratives remain available for those quests. A separate
Spain Spanish narrative bank has not been introduced.

## Manual research collection

The private **QuestLoreProbe** collector remains a separate manually started
research addon. It is not bundled with QuestLore and does not run for ordinary
users. The developer can use it with each client language to collect original
quest-query data, exit normally and extract the resulting WDB cache.

The 20-ID experiment recovered titles, objectives and initial descriptions in
both enUS and esMX. The subsequent enUS calibration on build 70959 received
100 successful responses in 69 seconds at up to two requests per second. Cache
extraction recovered 100 complete records with 99 nonempty descriptions. The one
empty description (quest 16) is also absent from the previous reference. The 21
initially unconfirmed descriptions were validated: 20 have no countable objective
records and one is a zero-count exploration objective. All 21 match the previous
reference after comparison-only normalization of whitespace and player markers.
The reader now recognizes these observed build-70959 cases without applying the
fixed layout to future builds. The larger esMX calibration remains pending. Neither the 5,259-ID
catalog nor a successful API event alone proves that every original quest
description is available.

Research inputs and full original dialogue are excluded from the public addon
ZIP. Only the short narrative banks and runtime code are distributed.

## Release validation

The provisional quest translations are produced locally from the existing
English summaries, sentence by sentence, with protected English names and
sampled editorial corrections. They use
[OPUS-MT English–French](https://huggingface.co/Helsinki-NLP/opus-mt-tc-big-en-fr),
[WMT19 English–German](https://huggingface.co/facebook/wmt19-en-de), and
[OPUS-MT English–Portuguese](https://huggingface.co/Helsinki-NLP/opus-mt-tc-big-en-pt).
The Portuguese engine is general Portuguese; samples receive Brazilian usage
corrections, but consistency across the entire bank is not yet verified.
The 90 new race/class introductions per language are separately translated and
reviewed by AI agents against the complete English source. This is not a claim
of human native-speaker review. Model weights are not bundled.

Automated validation uses Lua 5.1 and a simulated client, including complete
original-text scrolling, clickable previews and source-storage isolation. Translation
coverage, protected-name checks and the scope of sampled editorial review must
be reported separately; automated checks do not establish native-speaker review.

When the server is available, verify the candidate with an active quest:

1. Choose a beta summary language and confirm the English names remain visible.
2. Open **Read full text** and compare it to the quest journal in the client's
   language. Scroll to the last line of a long description.
3. Change text size while the reader is open; then minimize Lore or hide the
   interface with Alt+Z. The cleared reader must not reappear as an empty panel.
4. Change the current quest, then complete or abandon it. Its original reader
   must close; history must retain only its summary.
5. Confirm that automatic language selection still uses Spanish for a Spanish
   client and English for other clients, while manual language choices persist
   per character after a reload.

## Russian (0.18.0-beta10)

Russian includes all 5,259 quest narratives, 90 race/class introductions,
2,163 encyclopedia articles and the interface. It is a provisional translation
from the canonical English summaries and articles, not from original Russian
client dialogue. Proper names and encyclopedia titles remain in English. Quest
titles and full quest text continue to use the client's localized records.

Russian UI detection recognizes ruRU. Russian narratives require an explicit
manual choice, preserving the existing automatic Spanish/English policy.
The Russian story selector is labeled **Русский (бета)**; the interface selector uses **Русский**.
The pinned offline translation model, exact source hashes, protected-name
checks and sampled AI editorial corrections are recorded in research/russian.
Automatic completeness/name checks do not certify full semantic accuracy or
native-human review. No translation model or online translation service runs
inside the addon. German's existing complete beta banks remain unchanged.
