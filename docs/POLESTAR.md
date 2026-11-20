# Polestar integration

Investigated on 2026-11-15 against the public `next` branch at [commit 19bd636e7d6f33231770f6029c76d2d4dfc63798](https://github.com/fitzforge/polestar/commit/19bd636e7d6f33231770f6029c76d2d4dfc63798), with a comparison to the locally installed addon. The initial investigation informed the direct bridge shipped in QuestLore 0.15.0. Integration behavior is verified with a simulated client and message bus, not a live in-game test.

## Finding

**Yes: QuestLore can follow the quest associated with Polestar's current navigation target.** The source exposes a global `Polestar` namespace, a target getter, and a message bus. No modification or copied source from Polestar is needed.

- [Core/Init.lua](https://github.com/fitzforge/polestar/blob/19bd636e7d6f33231770f6029c76d2d4dfc63798/addon/Polestar/Core/Init.lua) exposes `Polestar = ns` and defines `ns.On(message, callback)` / `ns.Off(handle)`.
- [Nav/Nav.lua](https://github.com/fitzforge/polestar/blob/19bd636e7d6f33231770f6029c76d2d4dfc63798/addon/Polestar/Nav/Nav.lua) defines `Nav.GetTarget()` and announces `WAYPOINT_CHANGED` with the current target. A quest-associated target can carry `quest` and `kind` fields; manual targets need not carry a quest.
- [Nav/Bridges.lua](https://github.com/fitzforge/polestar/blob/19bd636e7d6f33231770f6029c76d2d4dfc63798/addon/Polestar/Nav/Bridges.lua) calls `C_SuperTrack.SetSuperTrackedQuestID(q)` for certain accepted, trackable quest targets. It rejects acceptance targets and some area/search/spawn targets; route legs may instead use a user waypoint. Therefore game super-tracking does not represent every Polestar target.

QuestLore already follows game super-tracking through its existing quest API and hook. That provides partial incidental synchronization where Polestar sets it, not a complete guarantee.

## Direct bridge in 0.15.1

The bridge adds a per-character **Follow Polestar's active quest** option, enabled by default, with a soft dependency only. On initialization and late `ADDON_LOADED`, it feature-detects `Polestar.On`, `Polestar.Off`, and `Polestar.Nav.GetTarget`. It reads the initial target and subscribes once to `WAYPOINT_CHANGED`; it removes the subscription and cancels the safety timer when disabling the feature.

The bridge accepts `tonumber(target.quest)` only when it is a positive, ordinary value and `C_QuestLog.GetLogIndexForQuestID` confirms that the quest is currently in the player's log. Absent, manual, and acceptance targets are rejected. Recommended future quests are not rendered before acceptance. Narrative data comes from QuestLore's local corpus, not a later guide step.

An active quest selected in the visible journal or focused in native super-tracking takes priority over the guide. The latest explicit journal/tracker interaction wins. Polestar and RestedXP target updates do not clear this selection. When no valid quest has focus, a valid accepted Polestar target is preferred over RestedXP and ordinary watched-quest selection. Clearing focus or removing the focused quest restores guide fallback. The bridge never calls Polestar setters, changes its route, or forces native tracking.

The bridge uses the target's quest association rather than a temporary travel-stop label. A flight master or boat is not itself the quest whose context should be explained. It subscribes to target changes and coalesces events through QuestLore's refresh queue. Every ordinary refresh rereads the target, including quest acceptance, turn-in, removal, and log updates. A one-second read-only safety check recovers silent or delayed changes while Lore is visible. It requests a redraw only when context changes or the displayed quest disagrees; it never asks Polestar to recalculate its route.

## Automated checks

The simulated-client suite tests initial load, late load, disable/re-enable without duplicate listeners, accepted quest objectives, turn-ins, acceptance recommendations, unrelated manual pins, travel legs, cleared targets, quest removal, same-ID objective changes, journal/tracker focus precedence over both guides, accepting a side quest, completion events, silent target changes, idle redraw suppression, timer cancellation, and absent or changed Polestar APIs.

These namespace functions are visible in current source but are not a versioned compatibility contract. Feature detection and a fallback remain necessary. The bridge is read-only toward Polestar. Manual journal selection is used when the integration is disabled or Polestar has no valid accepted quest. The toggle controls direct target following, while Polestar may independently change the game's native super-tracking.
