# Contributing

Please describe the player-visible problem and expected behavior before submitting a change. Keep changes focused and run `python3 tools/package.py --lua lua5.1` before opening a pull request. Client interaction and visual changes should also be checked in Forever when possible; state any testing limits.

## Narrative corrections

Include the quest ID, the Forever title, and a source URL or a short relevant excerpt from the acceptance text. Match the current Forever quest rather than assuming its Classic namesake is identical. Update both language entries in `QuestLore/Narratives.lua` and any matching legacy Spanish entry in `Stories*.lua` so the compatibility fallback agrees. Additional languages live in `Narratives_<language>.lua`; opening stories live in `Origins_Stories.lua`. Encyclopedia articles live in `Encyclopedia_Data.lua`. Update the affected language without silently replacing localized names with English names.

Write concise original prose, normally no more than 100 words per language. Explain the assignment's problem, motivation, and known stakes. Use neutral Spanish, natural English, and equivalent meaning. Avoid filler, objective-list rewrites, editorial commentary, invented personal history, and unsupported causes. Preserve uncertainty when the quest giver is uncertain.

Use only information already known at acceptance of that exact step. Do not import the next quest's revelation, completion result, or later chain outcome. Automatic pickups or reward offers sometimes put their initial dialogue in a field named Completion; explain why that is the initial offer if using it as evidence. Do not contribute copied quest databases, long verbatim quest descriptions, or personal character data.

By contributing, you agree to license your original contribution under this project's MIT License. Underlying game content remains with its respective rights holders.
