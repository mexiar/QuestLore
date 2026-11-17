# Languages and original quest text

QuestLore's base narrative banks are English and Latin American Spanish. The
existing Spanish bank is still undergoing an audit against original esMX names;
"available in Spanish" does not mean every proper name has been client-verified.
A Spanish (Spain) client currently uses the explicitly labeled Latin American
Spanish narrative bank.

French, German and Brazilian Portuguese summaries are provisional translations
of the English narrative bank. They retain English proper names and English quest
titles. They are not summaries generated from independently collected original
French, German or Portuguese quest descriptions. The addon options explain this
distinction. A missing translated entry falls back to English with its actual
language retained in the model metadata.

Automatic summary language selection keeps the established Spanish/English defaults: esMX/esES use Latin American Spanish and other clients use English. French, German and Brazilian Portuguese beta banks require an explicit per-character manual choice while editorial review is incomplete. Locale resolution also recognizes ptPT as the Brazilian Portuguese bank when explicitly requested.

## Read full text

The **Read full text** action appears only for the current quest while it is
still in the player's quest log. It opens the original description and objective
paragraph returned by the game, in a separate native-style scrollable reader.

This text follows the **game client's language**, independently of the summary
language chosen in QuestLore. Changing the summary language does not translate
the original quest dialogue. For example, a French client can show an English
summary and its original French quest text.

The reader does not shorten the description or use an archived narrative as a
substitute. It clears its text on close, context change or quest removal. No
full-text action is provided in the historical summary list. It is also absent
from race/class introductions.

## Source storage and history

Original descriptions are retained only in memory for quests still active in the
log. QuestLore removes older releases' saved source caches on initialization and
prunes inactive in-session sources even when the Lore window is hidden.

The per-character archive keeps up to 200 authored narrative summaries and
introductions. Raw descriptions and extractive source fallbacks are not archived.
Old source extracts can be replaced by an available authored summary during
migration; otherwise the old original text is dropped.

These rules concern QuestLore's own data. The WoW client manages its own quest
cache independently.

## Manual research collection

The private **QuestLoreProbe** collector remains a separate manually started
research addon. It is not bundled with QuestLore and does not run for ordinary
users. The developer can use it with each client language to collect original
quest-query data, exit normally and extract the resulting WDB cache.

The 20-ID experiment recovered titles, objectives and initial descriptions in
both enUS and esMX. A larger 100-ID calibration at the collector's new adaptive
rate is still pending. Neither the 5,259-ID catalog nor a successful API event
alone proves that every original quest description is available.

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

The 0.17.0 release candidate is tested with Lua 5.1 and a simulated client,
including complete original-text scrolling and source-storage isolation. Native
Forever visual verification is pending the end of server maintenance. Translation
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
