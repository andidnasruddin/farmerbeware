# Farmer Beware (Godot 4.4.1)

Centralized, autoload-driven farming game project following the GameManager system in `docs/1_GameManagerSystem.md`.

## Tech

- Engine: Godot 4.4.1 (stable)
- Language: GDScript (tabs for indentation)
- Structure: Autoload managers orchestrated by `GameManager` with strict order

## Autoload Order (current)

1. GameManager
2. GridValidator
3. GridManager
4. InteractionSystem
5. TimeManager
6. EventManager
7. CropManager
8. ContractManager
9. ProcessingManager
10. NetworkManager
11. SaveManager
12. InnovationManager
13. AudioManager
14. UIManager

## Getting Started

- Install Godot 4.4.1.
- Open the project folder in Godot and run the project, or run a lightweight test scene that uses `res://Z_test.gd`.
- Ensure autoloads are configured and ordered as listed above (Project Settings → Autoload).

## Coding Style

- Follow `docs/CODING_STYLE.md` exactly.
- Use tabs for GDScript indentation.
- Defensive checks for nulls and signals.

## Development Notes

- Scene transitions and global events should go through the relevant managers (GameManager, EventManager).
- Do not reference other managers directly unless specified in `1_GameManagerSystem.md`.

## Running the Test Harness

A convenience script `res://Z_test.gd` exercises all autoloads (#1–#14) and prints a status log. Attach it to a simple scene (Node) and run that scene to validate the setup.

## Git & GitHub

This repo includes:

- `.gitignore` tailored for Godot 4
- `.gitattributes` to normalize line endings and mark binary assets
- `.editorconfig` to enforce tabs in `.gd` files

### Initialize and Push (first time)

```bash
# Initialize
git init

# Review files, then stage
git add .

# Commit
git commit -m "chore: initial project setup (godot 4, autoloads)"

# Create a new GitHub repo (via web UI), then set origin and push
git remote add origin https://github.com/<your-username>/<repo-name>.git
git branch -M main
git push -u origin main
```

## License

Add a license appropriate to your goals (MIT, Apache-2.0, GPL-3.0, etc.).

## CI/CD (Optional)

You can add GitHub Actions later for linting/exports. Many setups require credentials; keep workflows out until you’re ready.

