# QuestLore 0.18.0-beta11

All changes since **0.18.0-beta7**.

## Russian language support

- Added 5,259 quest summaries, 90 race/class introductions, 2,163 encyclopedia articles and the interface in Russian.
- Russian narratives and articles are provisional English-based translations retaining English proper names and article titles. Quest titles and full text follow the game client's language.
- German remains available alongside English, Latin American Spanish, French, Brazilian Portuguese and Polish.

## Update notices and version history

- Added a discreet **Updated - See what's new** notice after upgrading, with **Show update notices** enabled by default.
- Notices remain pending until opened or dismissed; acknowledgement is saved per character and version, including across reloads and reinstalls. Notices stay hidden while Lore is minimized.
- Added **What’s new** in addon options with the last five releases, newest first, in all seven interface languages, plus a copyable link to the complete CurseForge changelog.
- Fixed release-history separators appearing as missing-character boxes with the game font.
- No online version checks, addon-message traffic or additional polling timers.

## Window persistence and history performance

- Fixed encyclopedia position and size not being saved between sessions. Geometry is now saved per character and restored after login or a UI reload.
- Reuse link controls for visible history stories instead of retaining controls for every story visited. Defer rebuilding a closed history panel and reuse name-matching results during font and width changes.
- Keep the existing limit of 200 unique stories per character, newest first.
- Added saved-profile regression coverage for transparency at 0%, 37% and 100%, enabled and disabled backgrounds, languages, text size, guide integrations, attachment, visibility, minimization, history and geometry of all three windows across repeated saved reloads and upgrades.
- Preserve existing preferences per character.

## Bugs and news

- Added **Bugs and news** in options with [@alejandrosena](https://x.com/alejandrosena) for bug reports and updates, including a copyable profile URL and instructions in all seven interface languages.
- Added the creator's X credit to the CurseForge description. Retained [dawiss](https://github.com/dawiss)'s Polish contribution credit.
