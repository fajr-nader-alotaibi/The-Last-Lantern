# Forest model shortlist

The forest opening is currently a lightweight Godot blockout built from primitive meshes. No Sketchfab files have been copied into this folder yet.

## Best fits from the supplied links

- **Fern:** `Low poly game-ready fern` — 308 triangles, game-ready, Free Standard. Good foliage candidate. [Sketchfab page](https://sketchfab.com/3d-models/low-poly-game-ready-fern-869826a3d24a448eb3bc6a51e8ed5125)
- **Rock:** `Mossy Rock` — 19.9k triangles, CC BY. Fine for a few landmark rocks, but too many repeats are wasteful. [Sketchfab page](https://sketchfab.com/3d-models/mossy-rock-6fea9922d99449a7a20be7e0daa73d20)
- **Lantern alternative:** `Japanese Toro` — about 1.8k triangles, CC BY. Better for repeated gameplay lanterns than the supplied 42k-triangle test model. [Sketchfab page](https://sketchfab.com/3d-models/japanese-toro-afe883adeab045348b7dc9a038975feb)
- **Forest skybox:** the 6K panorama is only a distant backdrop, not walkable fog or a forest mesh. Optional for a menu or horizon; reduce it to 2K before using on a low-memory machine. [Sketchfab page](https://sketchfab.com/3d-models/creepy-misty-forest-skybox-60721c4b8d7c46078e3a9bfda1de3493)

## Skip or replace

- The supplied Japanese red pine is CC0 but has about **508,800 triangles**. Do not scatter it through the level; request a low-poly remake or decimate it in Blender first. [Sketchfab page](https://sketchfab.com/3d-models/cc0-japanese-red-pine-pinus-densiflora-a6be820fbf46456eb35bcafc7e66bd12)
- The supplied mossy stairs have about **149,400 triangles** and a **CC BY-NC-SA** license. Avoid them in a distributable game; simple stair meshes are enough here. [Sketchfab page](https://sketchfab.com/3d-models/mossy-stone-stairs-ff2e39a7896a49189375c2aa5abb8476)
- The supplied pond is about **102,800 triangles**, depicts a landscaped American pond, and does not expose a download button on its page. Use the simple pond mesh in the blockout. [Sketchfab page](https://sketchfab.com/3d-models/valley-pond-d7bf45d6e5ad422b949d58140fae13f7)
- The supplied stone Tōrō is about **2,000 triangles**, but its license is **CC BY-NC**. Avoid using it in a distributable game. The 42,300-triangle Toro Generator model is CC BY but unnecessarily dense for four copies.
- The supplied Torii listing now points to a paid Fab asset. The rough blockout gate is already built from simple Godot meshes.
- `Shimenawa` and its paper streamers are religious markers. They are intentionally omitted along with Buddha/statue props, per the requested art direction.
- The 342k-triangle night-forest scene and the incomplete overgrown location are not used as the playable level; they are too monolithic or unfinished for this small connected map.

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
- Use the fern and rock for close foreground accents; reuse the simple procedural trees in the distance.
- Keep a copy of each model's creator and license in a credits file before releasing the game.
- Official Sketchfab downloads in this session asked for a Sketchfab login. Sign in manually before any download; do not use third-party rippers.

## Imported user model

`Japanese_Pine_v1_1K.glb` is the supplied distant pine. It is about 10 m tall and has 3,931 triangles. Its three embedded 4096x4096 PNG textures were resized to 1024x1024, reducing the GLB from 31.07 MiB to 3.50 MiB. The source file in Downloads was left unchanged.
