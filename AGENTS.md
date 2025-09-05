# Repository Guidelines

## Project Structure & Module Organization
- `scripts/`: GDScript sources grouped by domain (`managers/`, `player/`, `tool/`, `ui/`).
- `scenes/`: Reusable scenes (player, grid, UI, visuals).
- `assets/` and `resources/`: Art, audio, and data assets.
- `tests/`: Lightweight scene/script tests (e.g., `Z_test.tscn`, `Z_test.gd`).
- `addons/gdai-mcp-plugin-godot/`: GDAI MCP plugin (enabled via `project.godot`).
- Root files: `project.godot` (Godot 4.4 project), `.editorconfig`, README.

## Build, Test, and Development Commands
- Run (Editor): Open `project.godot` in Godot 4.4 and press `F5`.
- Run specific scene: Open and play a scene (e.g., `tests/Z_test.tscn`).
- Export builds: Configure presets in Project → Export…, then from CLI:
  - `godot4 --headless --path . --export-release "Windows Desktop" build/FarmerBeware.exe`
  - Replace preset and output per your target platform.

## Coding Style & Naming Conventions
- Indentation: Tabs for `.gd`, `.tscn`, shaders; 2 spaces for `.md/.json/.yaml` (see `.editorconfig`).
- Line endings/charset: `LF`, UTF‑8; trim trailing whitespace; final newline required.
- GDScript: `PascalCase` for classes/files (`PlayerController.gd`), `snake_case` for functions/variables, `UPPER_SNAKE_CASE` for constants, signals `snake_case`.
- Project layout: Keep domain folders (`managers`, `player`, `ui`) and register singletons via `[autoload]` when introducing new managers.

## Testing Guidelines
- Framework: Scene-driven checks in `tests/`; logs appear in the Godot Output panel.
- Conventions: Name test scenes/scripts clearly (e.g., `feature_test.tscn`, `feature_test.gd`).
- Run tests: Open and play `tests/Z_test.tscn` (or other test scenes). Headless runs can be scripted once export presets and CI are configured.

## Commit & Pull Request Guidelines
- Commit style: Follow existing pattern — `Version <major.minor.patch.build>: <short summary>` (e.g., `Version 0.1.2.11: Added player animations`).
- Scope: One logical change per commit; keep messages imperative and concise. Align strictly with the designated design doc and step (currently `docs/3_PlayerInteractionSystem.md`, Step 12) — no deviations.
- PRs: Include description, rationale, linked issues, test instructions, and screenshots/gifs for visual/UI changes. Note any save/data or network implications.

## Networking Development Tips
- Godot 4 RPCs: Use `method.rpc()` / `method.rpc_id()` with `@rpc` annotations; avoid legacy Godot 3 APIs.
- No recursive RPCs: Never call an RPC from within itself; host applies state without echoing the same RPC back.
- Connection guards: Clients send only after `connected_to_server`; track a `_connected` flag.
- Session hygiene: Always `leave()` before hosting/joining again; log `peer_connected` and related signals.
- Null safety: Defer node lookups or guard access (e.g., `Player`, `CarrySystem`, `InteractionSystem`).

## MCP Plugin Notes (Optional)
- The GDAI MCP runtime (`GDAIMCPRuntime`) is autoloaded and the plugin is enabled under `addons/gdai-mcp-plugin-godot`.
- Avoid renaming/removing plugin files or the autoload entry. Refer to the plugin README in the addon for client setup and security considerations (run locally; do not expose to untrusted networks).
