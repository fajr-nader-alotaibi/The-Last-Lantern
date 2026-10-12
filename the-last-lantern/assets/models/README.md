# Forest model shortlist and imports

The compact forest uses the v7 low-poly tree around the walkable trails and the existing pine model at the far tree line. The v7 Japanese house is the temple exterior; Godot-built timber and shoji details form the playable interior. The optimized GLBs below are copies; files in Downloads were left unchanged.

## Imported into the project

| Model | Project file | Geometry | Project file size | Use / license |
| --- | --- | ---: | ---: | --- |
| Low-poly fern | props/fern_low_poly_512.glb | 306 triangles | 1.53 MiB | Repeated foliage; 512px textures. Sketchfab Free Standard, marked NoAI. |
| Japanese Torii gate | props/japanese_torii_gate_1k.glb | 1,252 triangles | 2.02 MiB | Used on the forest path near the temple; 1K textures. CC BY: credit Sahir Virmani. |
| Japanese stone Tōrō | props/japanese_stone_lanterntoro_512.glb | 1,960 triangles | 8.07 MiB | Used for the four interactive forest lanterns and the menu. 512px textures. CC BY-NC: credit ArunIniyan; non-commercial use only. |
| Low-poly forest tree | props/tree_low_poly.glb | 1,629 triangles | 169 KiB | Repeated on the near tree line; keep the 1K pine for distant silhouettes. Imported from the v7 project archive; source license still needs verification. |
| Japanese old house | props/old_house.glb | 34,772 triangles | 13.3 MiB | One temple exterior instance, not repeated; textures are embedded. Imported from the v7 project archive; source license still needs verification. |

The downloaded fern and lantern each contained many 1K PNGs. Project copies were resized to 512px to reduce their file weight while preserving the originals in Downloads. The fern and Torii copies also have normalized scale/orientation and ground-level pivots for placement in Godot. The pine model was already in the project and was previously reduced to 1K textures.

The gameplay bridge, stone path pavers, grass borders, pond, and temple interior trim are lightweight Godot-built pieces. The Tōrō model is used for the interactive lanterns; their lights and flames are added in Godot. No new Meshy exports are required to run the forest-to-temple progression.


## Credits for imported props

- Fern: Barney2.1, “Fern Low poly game ready,” Sketchfab Free Standard; the page is marked NoAI. https://sketchfab.com/3d-models/fern-low-poly-game-ready-49b475dcbf7a45a0ac4bf5551bf92336
- Torii: Sahir Virmani, “Japanese Torii Gate,” CC BY. https://sketchfab.com/3d-models/japanese-torii-gate-2027a248de1b4b70985ff97e708fb50d
- Stone lantern: ArunIniyan, “Japanese Stone Lantern (Tōrō),” CC BY-NC. https://sketchfab.com/3d-models/japanese-stone-lanterntoro-c1d062b3ff1548e3abfdf7bafc14254d
- The low-poly tree and old house were copied from the supplied v7 project archive. Its archive did not include attribution or license details; verify the original asset pages before distributing the game.

The lantern license is non-commercial. If the game is ever monetized or distributed commercially, replace it with an asset whose license permits that use. Keep the Torii attribution in the credits.

## Best fits from the supplied links

- **Fern:** `Low poly game-ready fern` — 306 triangles, game-ready, Free Standard. Good foliage candidate. [Sketchfab page](https://sketchfab.com/3d-models/low-poly-game-ready-fern-869826a3d24a448eb3bc6a51e8ed5125)
- **Rock:** `Mossy Rock` — 19.9k triangles, CC BY. Fine for a few landmark rocks, but too many repeats are wasteful. [Sketchfab page](https://sketchfab.com/3d-models/mossy-rock-6fea9922d99449a7a20be7e0daa73d20)
- **Lantern alternative:** `Japanese Toro` — about 1.8k triangles, CC BY. Better for repeated gameplay lanterns than the supplied 42k-triangle test model. [Sketchfab page](https://sketchfab.com/3d-models/japanese-toro-afe883adeab045348b7dc9a038975feb)
- **Forest skybox:** the 6K panorama is only a distant backdrop, not walkable fog or a forest mesh. Optional for a menu or horizon; reduce it to 2K before using on a low-memory machine. [Sketchfab page](https://sketchfab.com/3d-models/creepy-misty-forest-skybox-60721c4b8d7c46078e3a9bfda1de3493)

## Skip or replace

- The supplied Japanese red pine is CC0 but has about **508,800 triangles**. Do not scatter it through the level; request a low-poly remake or decimate it in Blender first. [Sketchfab page](https://sketchfab.com/3d-models/cc0-japanese-red-pine-pinus-densiflora-a6be820fbf46456eb35bcafc7e66bd12)
- The supplied mossy stairs have about **149,400 triangles** and a **CC BY-NC-SA** license. Avoid them in a distributable game; simple stair meshes are enough here. [Sketchfab page](https://sketchfab.com/3d-models/mossy-stone-stairs-ff2e39a7896a49189375c2aa5abb8476)
- The supplied pond is about **102,800 triangles**, depicts a landscaped American pond, and does not expose a download button on its page. Use the simple pond mesh in the blockout. [Sketchfab page](https://sketchfab.com/3d-models/valley-pond-d7bf45d6e5ad422b949d58140fae13f7)
- The supplied stone Tōrō is about **2,000 triangles**, but its license is **CC BY-NC**. Use it only in a non-commercial release with attribution. The 42,300-triangle Toro Generator model is CC BY but unnecessarily dense for four copies.
- The original supplied Torii link was unsuitable, so a separate 1,252-triangle CC BY Torii model is used in the project instead.
- `Shimenawa` and its paper streamers are religious markers. They are intentionally omitted along with Buddha/statue props, per the requested art direction.
- The 342k-triangle night-forest scene and the incomplete overgrown location are not used as the playable level; they are too monolithic or unfinished for this small connected map.
- `gravel_ground_module_scan_dry_2.glb` is about **225k triangles**, 15.5 MiB, and roughly 18 × 11 m. It is too large and dense to repeat along this narrow route; the path uses low-poly procedural flagstones and MultiMesh grass instead.

## Meshy prompts

Use one prompt per model, then export as **GLB**. Keep the supplied explorer character consistent with the environment palette.

### Japanese forest pine

```text
Create one standalone Japanese red pine (Pinus densiflora) tree for a compact third-person horror game set in a night forest. Keep a recognizable irregular pine silhouette, a slightly twisted dark trunk, sparse layered branches, and subdued blue-green needles. Stylized realistic, readable in low light, game-ready low-poly mesh with a target below 4,000 triangles, one 1K texture set, simple PBR materials, origin at the trunk base, real-world scale about 8 meters tall. One tree only: no ground, no rocks, no scene, no text, no animation. Export as GLB.
```

### Non-religious Japanese timber hall

```text
Create one small abandoned Japanese-style forest timber hall for a third-person horror game. It should read as an old rural wooden house: dark weathered beams, simple sliding double doors, a broad curved roof, moss only along a few edges, and a shallow stone entry. Do not include Buddha, statues, idols, altars, prayer objects, sacred rope, paper streamers, religious symbols, or writing. Modular game-ready model, target below 8,000 triangles, one 1K texture set, simple PBR materials, door as a separate movable piece if possible. No surrounding forest or background. Export as GLB.
```

### Trail lantern

```text
Create one standalone weathered Japanese-style stone trail lantern for a compact night-forest horror game. Use a simple stacked stone base and roof with a small dark glass window; no symbols, writing, statues, offerings, or sacred decorations. Keep the silhouette clear, stylized realistic, game-ready low-poly, target below 2,500 triangles, one 1K texture set, origin centered at the base. Keep the window non-emissive because the actual warm flame and light will be added in Godot. One lantern only, no background. Export as GLB.
```

### Mossy rocks

```text
Create one small cluster of three separate moss-covered forest rocks for a compact third-person horror game. Give each rock a different natural silhouette with restrained moss patches and wet dark stone; colors should stay readable in cold moonlight. Keep the rocks separate inside one GLB so I can reuse and scale each piece. Game-ready low-poly, below 1,500 triangles total, one 512x512 texture set, simple PBR material, no ground plane, plants, scene, text, or background. Export as GLB.
```

### Rig the existing explorer

```text
Use my supplied explorer GLB as the exact visual reference. Preserve the same face, hooded coat, backpack, proportions, colors, and lantern; do not redesign the character or add equipment. Create a clean humanoid skeleton with good skin weights and a game-ready rig. Provide separate animation clips named Idle, Walk, Hold_Lantern, and Interact_Light. Keep the feet at the origin, the character upright and facing forward, and the scale close to 1.65 meters. Export the rig and animation clips together as GLB.
```

### If a Torii-like entry is still wanted

```text
Create one standalone weathered Japanese timber entry gate for a forest path. Use two dark wooden posts and simple crossbeams with subtle red-brown wear. No sacred rope, paper streamers, plaque, symbols, writing, statues, or religious ornaments. Game-ready low-poly, target below 3,000 triangles, one 1K texture set, base pivot at ground level. No background or extra objects. Export as GLB.
```

## Import notes

- Prefer **GLB** so geometry and materials stay together; do not commit source archives or multiple 4K texture maps unless needed.
- Use imported fern clusters for close foreground accents and the imported Torii at the entry; reuse the low-poly pine for distant trees.
- The imported prop creators and license terms are recorded above for the release credits.


## Imported user model

`Japanese_Pine_v1_1K.glb` is the supplied leafy pine used around both forest paths and distant edges. It is about 10 m tall and has 3,931 triangles. Its three embedded 4096x4096 PNG textures were resized to 1024x1024, reducing the GLB from 31.07 MiB to 3.50 MiB. The source file in Downloads was left unchanged.

## Review of the additional downloads (2026-10-12)

| Download | File size | Triangles / parts | Recommendation |
| --- | ---: | ---: | --- |
| `tree_low_poly_lowpoly.glb` | 0.17 MiB | 1,629 / 2 meshes | Very light, but it is a broadleaf tree rather than a Japanese pine. Keep only as distant variety if needed. |
| `a_forest_3_with_a_road_at_night_for_game.glb` | 14.10 MiB | 151,954 / 1,480 meshes, 2,878 nodes | Do not import as the playable forest; its many separate pieces add scene and editor overhead. Use it as a visual reference. |
| `an_overgrown_japanese-style_location.glb` | 11.07 MiB | 35,837 / 836 meshes, 1,681 nodes | Not recommended as the playable level; inspect its religious props and structure before extracting any single piece. |
| `lowpoly_japanese_old_house.glb` | 13.32 MiB | 34,772 / 6 meshes, 18 images | Could serve as one landmark after reducing its textures and polygons. It is not needed for the current blockout. |
| `ja19_tsuga_diversifolia_japanese_hemlock.glb` | 300.31 MiB | 4,542,928 / 80 meshes | Too heavy for this project and machine; do not import or duplicate it. |
| `ja11_magnolia_soulangeana_saucer_magnolia.glb` | 64.28 MiB | 1,044,357 / 25 meshes | Too heavy to repeat. Skip it unless a single copy is decimated below about 10,000 triangles and its textures are reduced to 1K. |
| `Meshy_AI_bare_pine_trunk_quad__1012004300_texture.glb` | 19.30 MiB | 14,273 / 1 mesh | Usable only after decimation and resizing the embedded 4K textures. The separate foliage image still needs a cutout alpha; it is not a complete leafy tree by itself. |
| `fern_low_poly_game_ready.glb` | 6.62 MiB | 306 / 3 meshes | Light geometry but oversized textures; the project already has a 1.53 MiB version with 512px textures. |
| `japanese_stone_lanterntoro.glb` | 26.38 MiB | 1,960 / 11 meshes | Already present in the project as an 8.07 MiB version with 512px textures. Do not import the original again. |
| `japanese_torii_gate.glb` | 2.04 MiB | 1,252 / 1 mesh | Already present in the project at 2.02 MiB. No replacement needed. |

The pine color image and its black/white alpha mask are each 1024×1024. Together they can make cutout foliage cards, but the pair is only a branch texture, not a ready-made tree. Keep using the existing 3,931-triangle pine for the current forest; the separate bare trunk needs more asset work before it can replace it.
