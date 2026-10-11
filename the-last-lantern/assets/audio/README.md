# The Last Lantern — audio assets

The requested audio is now stored here as real, compressed audio files. Playback triggers are intentionally deferred until the forest areas and player surface detection are ready.

## Clips

| Requested sound | Files in this folder | Notes |
| --- | --- | --- |
| Night forest ambience | AMB_Forest_Night_Loop.mp3 | Loop candidate; check/fade its loop boundary in-game. |
| Dirt-path footsteps | SFX_Footsteps_Dirt_01.ogg–04.ogg | Grass/soil surface variations from a small licensed pack. |
| Wooden bridge footsteps | SFX_Footsteps_WoodBridge_01.ogg–04.ogg | Wood surface variations from the same pack. |
| Lantern ignition | SFX_Lantern_Ignite.mp3 | A synthesized fire sound candidate, not a realistic flint/lantern strike. Replace later if it does not fit. |
| Distant whisper | SFX_Distant_Whisper_01.ogg–04.ogg | Very short synthetic whispered vocal fragments; use rarely, with variation. |
| Branch creak | SFX_Branch_Creak.ogg | One-shot. |
| Shrine wind | AMB_Shrine_Wind.ogg | Wind loop candidate. |
| Temple drone | AMB_Temple_Drone.ogg | Dark atmospheric loop candidate. |

These use MP3/OGG files to keep the download small. Godot supports both formats. The source pack contributes four variations for footsteps and whispers; filenames have numeric suffixes so a future audio player can choose randomly without repeating the same clip every time.

## Sources and license notes

- **Forest ambience:** TinyWorlds, “Forest Ambience,” CC0. [OpenGameArt page](https://opengameart.org/content/forest-ambience)
- **Footsteps:** congusbongus, “Footsteps on different surfaces,” CC BY 3.0; grass and wood clips are derived from footstep-grass.wav and footstep-wood.wav by swuing. Keep attribution with redistributed builds: [OpenGameArt pack](https://opengameart.org/content/footsteps-on-different-surfaces), [grass source](https://freesound.org/people/swuing/sounds/38874/), [wood source](https://freesound.org/people/swuing/sounds/38876/), [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- **Whispers:** MirceaKitsune, “Dialog Vocal Samples,” Public Domain/CC0. [OpenGameArt page](https://opengameart.org/content/dialog-vocal-samples)
- **Lantern ignition candidate:** Spring Spring, “Synthesized Fire Sound Effect,” CC0. [OpenGameArt page](https://opengameart.org/content/synthesized-fire-sound-effect)
- **Branch creak:** AntumDeluge (original by Department64), “Tree Creaking,” CC0. [OpenGameArt page](https://opengameart.org/content/tree-creaking)
- **Shrine wind:** SketchMan3, “Wind Whoosh Loop,” CC0. [OpenGameArt page](https://opengameart.org/content/wind-whoosh-loop)
- **Temple drone:** congusbongus, “Lost in a bad place (horror ambience loop),” CC0. [OpenGameArt page](https://opengameart.org/content/lost-in-a-bad-place-horror-ambience-loop)

The footsteps are CC BY 3.0, so retain the attribution above in the game credits if they are included in a public build. Other listed clips are CC0/Public Domain according to their source pages.

## Later integration

- Loop forest, shrine, and temple beds on the existing ambience/music route and crossfade when the player enters each area.
- Choose a random dirt or wood variation when the movement system emits a footstep.
- Play ignition only after a lantern lights successfully.
- Trigger whispers and branch creaks infrequently, with cooldowns.
- Keep a single ambience player per active area; do not restart looped ambience on every frame.
