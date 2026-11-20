## 0.18.0-beta9 — 2026-11-20

- Save encyclopedia window position and size per character, restoring them after login or a UI reload. Keep saved geometry when switching articles or languages, and fit it safely within the current screen.
- Reuse a shared pool of encyclopedia link controls for visible history entries instead of retaining a separate set for every story visited.
- Defer hidden history feed rebuilds until the panel is opened, and reuse entity matching results during font-size and width changes.
- Retain the existing limit of **200 unique stories per character**, newest first. Existing preferences and saved Lore/full-text window geometry are preserved.
- Add regression coverage for encyclopedia geometry, profile isolation, settings preservation and a complete 200-story history traversal.

