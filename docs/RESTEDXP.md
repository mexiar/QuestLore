# RestedXP integration

QuestLore reads the live RXPGuides engine through AceAddon-3.0's `GetAddon("RXPGuides", true)`. The global `RXPGuides` table is its guide-import facade, not the engine. No guide text is imported, bundled or persisted.

The per-character **Follow RestedXP's active quest** option defaults to on. A missing addon creates no polling timer. Turn it off to use ordinary selection, or to stop its direct guide following. An active quest selected or focused by the player takes priority over both guides. When no quest has focus and both direct bridges identify a valid accepted quest, Polestar takes priority.

## Target selection

1. Read the visible arrow's `element`, following bounded `source`/`parent` links to an active quest element (`complete`, `turnin`, `collect`, `questgoto`, `questwaypoint`).
2. Require the quest to be in the current log, its step to belong to the current guide, and its element to be neither skipped nor completed nor hidden.
3. If there is no identifiable arrow quest, read the current progress step. Use it only if its remaining relevant elements refer to one unique accepted quest. Do not choose arbitrarily among multiple quests or sticky steps.
4. Otherwise use the ordinary journal / focused / watched quest selection.

Unaccepted quests, acceptance instructions, stale previous-guide arrows and disabled guides cannot take over the summary. QuestLore never changes RXP's progress, route, pins, tracking or guide settings.

A private AceEvent listener receives `RXP_GUIDE_LOADED`, `RXP_STEP_COMPLETE`, `RXP_OBJECTIVE_COMPLETE` and `RXP_TARGET_LIST_UPDATE`. It does not replace RXP's own subscribers. A single one-second local check catches silent arrow changes; unchanged targets do not redraw Lore. Disabling cancels the timer and removes the listener. Callback tokens make stale registrations inert even if removal fails.

## Source contract and validation

Inspected upstream revision: `2d3ca13dff5d31d3be65b8ddee3d24059efad293`.

- [Engine registration](https://github.com/RestedXP/RXPGuides/blob/2d3ca13dff5d31d3be65b8ddee3d24059efad293/Locale.lua)
- [Arrow element and generated source links](https://github.com/RestedXP/RXPGuides/blob/2d3ca13dff5d31d3be65b8ddee3d24059efad293/map.lua)
- [Guide-step and progress fields](https://github.com/RestedXP/RXPGuides/blob/2d3ca13dff5d31d3be65b8ddee3d24059efad293/GuideWindow.lua)
- [Quest IDs and objective tags](https://github.com/RestedXP/RXPGuides/blob/2d3ca13dff5d31d3be65b8ddee3d24059efad293/functions.lua)

`tests/restedxp.lua` covers live-engine discovery, private message subscriptions, direct and parent/source arrow goals, unambiguous step fallback, multiple quests, acceptance guards, skipped/completed elements, cycles, stale guide objects, getter errors, hidden guides, late loading, character preferences, disconnect/reconnect, silent changes, steady-state redraw avoidance and guide precedence.

Questie is supported through its normal tracker/journal interactions, without an independent guide bridge. The installed Forever version uses `C_SuperTrack.SetSuperTrackedQuestID` and `QuestMapFrame_OpenToQuestDetails`, both already observed by QuestLore. This does not mean Lore attaches to every custom Questie tracker layout; attachment still requires ForeverCore.
