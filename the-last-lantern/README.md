# The Last Lantern — Main Menu

This project currently opens on the supplied cinematic main-menu artwork. The menu fills and scales with the game window, including when it is maximized or restored to a smaller size.

## Run

Open `project.godot` in Godot 4.7 or newer, then press **F6** while `main_menu.tscn` is open or press **F5** to run the project. The project starts maximized; restore or resize the window to check the responsive layout.

## Menu controls

- **PLAY** and **SETTINGS** are clickable, transparent hit areas over the text in the provided image. Their signals are ready to connect after the forest scene and settings reference are ready.
- **QUIT** closes the game.

## Files

- `assets/ui/main_menu_reference.png` — supplied menu reference used as the exact full-screen background.
- `scenes/main_menu.tscn` — project startup scene.
- `scripts/ui/main_menu.gd` — responsive menu hit areas and button signals.
- `assets/character/` — the explorer model and textures supplied with the project; preserved for the future forest scene.
