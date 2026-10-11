# The Last Lantern

A small Godot 4.7 horror-exploration foundation for a solo game jam. The project opens on a 3D moonlit forest menu, includes a persistent settings screen, and has a playable opening path with one interactable lantern.

## Run

Open this folder's `project.godot` in Godot 4.7 or newer and press **F5**. The game starts maximized. Press **F6** to run the currently open scene from the editor.

## Controls

| Key | Action |
| --- | --- |
| W A S D | Move relative to the camera |
| Q / E | Smoothly orbit the camera by the configured step |
| F | Light the lantern or use a nearby object |
| Esc | Pause / go back |
| Mouse | UI navigation; gameplay look is optional and off by default |

The opening scene has one working lantern. The counter is prepared for four; the remaining level content is not part of this foundation.

## Settings

Gameplay settings affect the player camera, interaction distance, and prompt. Graphics settings apply display mode, supported window size, VSync, and 3D anti-aliasing quality. Audio sliders control the Master, Music, and SFX buses. UI scale and prompt visibility are applied when **APPLY** is pressed. **BACK** discards un-applied changes. Applied settings persist in `user://settings.cfg`.

The language control is intentionally not offered as an active selector yet: Arabic translation and right-to-left layout are not implemented. No music or sound files are included, but the audio buses are ready for later assets.

## Project structure

- `scenes/main_menu.tscn` and `scripts/ui/main_menu.gd` — 3D menu, keyboard/mouse navigation, and Play/Settings/Quit flow.
- `scenes/environment/menu_environment.tscn` and `scripts/world/forest_environment.gd` — lightweight forest, torii, lanterns, fog, and moving atmospheric details.
- `scenes/ui/settings_menu.tscn` and `scripts/ui/settings_menu.gd` — settings categories and controls.
- `scenes/forest.tscn`, `scenes/player.tscn`, and `scripts/` — playable opening scene, third-person movement, camera orbit, pause menu, HUD, and lantern interaction.
- `assets/character/explorer.glb` — the supplied explorer model.

The original menu image remains in `assets/ui/main_menu_reference.png` for comparison only; the game draws its background from the 3D environment.
