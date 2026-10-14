# STILL HERE: Platform 6 — Free asset catalog

Researched 2026-10-14. Every entry is free with a commercial-safe licence. Pages were opened and licences checked on the source page.
Second opinions came from Codex CLI and opencode (free model). Their suggestions were merged only after the page/licence was checked here.
"DL" means downloaded into `assets/third_party/<pack>/`. All downloaded models import in Godot 4.6.3 and load (411/411 OK via `tests/asset_contact_sheet.gd`).
Contact sheets: `/workspace/shots/assets/contact_*.png` (box), also copied to `docs/qa/asset-library/`.

Style note: none of these are a 1:1 match for Sakura Crossing. They are low-poly and flat-coloured, and they pick up the project's toon ramp and ink outline well. Faces are painted or simple geometry. No free pack ships facial blendshapes.

## Characters (with faces) + humanoid animation
| Asset | URL | Licence | Formats / rig / anims | Fit | DL |
|---|---|---|---|---|---|
| Quaternius Ultimate Modular Women | https://quaternius.com/packs/ultimatemodularwomen.html | CC0 | glTF/FBX/blend, rigged, 24 clips (Idle, Idle_Neutral, Walk, Run, Run L/R/Back, Wave, Interact, Roll…) + Humanoid-rig variant | Best Mira/villager base: proportioned, simple faces | ✅ `quaternius_modular_women` (7: Casual, Formal, Adventurer, Witch, Worker, Suit, Medieval) |
| Quaternius Ultimate Modular Men | https://quaternius.com/packs/ultimatemodularcharacters.html | CC0 | same 24 clips | Player/villagers (Casual_2, Hoodie, Farmer, Beach, Worker, Suit, Adventurer) | ✅ `quaternius_modular_men` |
| KayKit Adventurers 1.0 | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 (itch: kaylousberg.itch.io/kaykit-adventurers) | CC0 | GLB, rigged, **76 clips** incl. Idle, Walk, Run, Cheer, Interact, Sit (chair/floor), Lie, Jump | Chibi, expressive faces, closest to "soft cute". The fantasy outfits need repainting | ✅ `kaykit_adventurers` |
| KayKit Character Animations | https://kaylousberg.itch.io/kaykit-character-animations | CC0 | GLB/FBX, ~130+ clips on KayKit rig (sit, lie down, interact, emotes) | Big emote/sit/gesture library for KayKit rig | ❌ itch download flow, fetch manually (free) |
| Quaternius Universal Base Characters | https://quaternius.com/packs/universalbasecharacters.html | CC0 (Standard tier) | glTF/FBX humanoid bases, retargetable | Clean faces, pairs with UAL | ❌ itch (free tier; Source tier paid, not needed) |
| Quaternius Universal Animation Library 1 & 2 | https://quaternius.itch.io/universal-animation-library , …-2 | CC0 (Standard) | 120+ humanoid clips, Godot-ready rig | Main walk/sit/gesture library | ❌ itch (rate-limited during check; free tier) |
| Kenney Mini / Blocky Characters | https://kenney.nl/assets/mini-characters , /blocky-characters | CC0 | GLB, animated | Already in repo (mini); chunky style Sai disliked | mini ✅ (pre-existing) |
| Mixamo | https://www.mixamo.com | Adobe terms: free incl. commercial use in games, but **no redistributing raw FBX** as standalone assets; Adobe login required | FBX, auto-rig + 2,500 clips | Good mocap for gestures. Bake into our own characters, don't commit raw files to a public repo | ❌ (licence caveat) |
| Godot4-MixamoLibraries | https://github.com/prfiredragon/Godot4-MixamoLibraries | MIT repo (clips originate from Mixamo; same caveat) | Godot AnimationLibrary + BoneMap | Retarget helper only | ❌ |

## Cats & animals
| Asset | URL | Licence | Anims | Fit | DL |
|---|---|---|---|---|---|
| Quaternius Cat | https://poly.pizza/m/qKICY6xla2 | CC0 | Idle, Idle_Eating, Walk, Run, Jump, Headbutt, Death | Best free animated cat. No sit/sleep/groom | ✅ `quaternius_single_animals/Cat.glb` |
| Quaternius Cat (blob) / Pigeon | https://poly.pizza/m/2f54vbV0In , https://poly.pizza/m/9NGlBTpDEr | CC0 | Idle, Walk, Jump, Dance, Yes/No | Cute round "blob" style, good for a chibi cat and pigeons on the platform | ✅ |
| Quaternius Bunny | https://poly.pizza/m/irZjWFARyl | CC0 | Idle, Walk, Run, Jump, Wave, Yes/No, Duck | Rabbit (anthro-ish) | ✅ |
| Quaternius Ultimate Animated Animals | https://quaternius.com/packs/ultimateanimatedanimals.html | CC0 | 12 animals (Shiba Inu, Husky, Fox, Deer, Alpaca, Horse, Donkey, Cow…) × 12 clips: Idle, Idle_2, HeadLow, Eating, Walk, Gallop, Jump | Dogs and village animals | ✅ `quaternius_animated_animals` |
| Quaternius Cute Fish | https://quaternius.com/packs/cutefish.html | CC0 | swim fast/slow etc. (FBX) | Pond/beach fish | ✅ 7 fish (FBX). Textures are vertex colours and look dark under the current light; recolour in shader |
| Quaternius Farm Animals | https://quaternius.com/packs/farmanimal.html | CC0 | animated pug, pig, sheep, chicken… | Ducks/chickens for the village | ❌ (itch) |
| Vertexcat Farm Animals Set | https://vertexcat.itch.io/farm-animals-set | CC0 | duck, chicken, sheep… | Duck fallback | ❌ |
| Styloo Animals | https://styloo.itch.io/animals | Page lists both CC0 and CC-BY 4.0. Treat as CC-BY and credit | rigged cat/dog/chicken | Softer look, worth testing | ❌ |
| Gobkit bird pack | https://gobkit.com/freebies | CC0 | idle/walk/fly-ish | Birds | ❌ |

## Stations, trains, villages, nature
| Asset | URL | Licence | Contents | Fit | DL |
|---|---|---|---|---|---|
| Kenney Train Kit | https://kenney.nl/assets/train-kit | CC0 | GLB trains, carriages, tram, rails, platform pieces | Platform 6 trains/carriage | ✅ `kenney_train_kit` |
| Kenney City Kit Suburban | https://kenney.nl/assets/city-kit-suburban | CC0 | GLB houses, fences, paths, trees | Village around the station | ✅ `kenney_city_kit_suburban` |
| Kenney Furniture Kit | https://kenney.nl/assets/furniture-kit | CC0 | glTF interior props | Apartment / carriage interiors | ✅ `kenney_furniture_kit` |
| Quaternius Ultimate Stylized Nature | https://quaternius.com/packs/ultimatestylizednature.html | CC0 (Godot wrapper repo MIT: github.com/walterpalladino/godot-quaternius-ultimate-stylized-nature) | 63 FBX: birch/maple/pine/palm trees, bushes, flowers, grass, rocks (+ textures downscaled to 512px) | Ghibli-ish foliage, best match to Sakura | ✅ `quaternius_stylized_nature` |
| Quaternius Stylized Nature MegaKit | https://quaternius.com/packs/stylizednaturemegakit.html | CC0 (Standard) | ~116 nature models | Newer version of above | ❌ (itch) |
| Quaternius Medieval Village MegaKit | https://quaternius.com/packs/medievalvillagemegakit.html | CC0 (Standard) | modular village buildings | Village houses | ❌ (itch) |
| Kenney Nature Kit / Fantasy Town / Building Kit | https://kenney.nl/assets/nature-kit , /fantasy-town-kit , /building-kit | CC0 | props, town, modular station walls | Fill-ins | nature ✅ (pre-existing subset) |
| ambientCG / Poly Haven | https://ambientcg.com , https://polyhaven.com | CC0 | textures, HDRIs, some models | Ground/sky textures, beach sand | ❌ |

## VFX, audio, UI, fonts
| Asset | URL | Licence | Fit | DL |
|---|---|---|---|---|
| Kenney Particle Pack | https://kenney.nl/assets/particle-pack | CC0 | Sparkles, smoke, petals/leaves base, rain | ✅ `kenney_particle_pack` |
| Brackeys VFX Bundle | https://brackeysgames.itch.io/brackeys-vfx-bundle | CC0 | Flipbooks for magic, dust and weather | ❌ |
| Kenney UI Pack (+ click sounds, font) | https://kenney.nl/assets/ui-pack | CC0 | Buttons, panels, UI SFX | ✅ `kenney_ui_pack` |
| Kenney Game Icons / Input Prompts | https://kenney.nl/assets/game-icons , /input-prompts | CC0 | HUD + touch/controller prompts | ❌ |
| Kenney Fonts | https://kenney.nl/assets/kenney-fonts | CC0 | Display fonts | ✅ `kenney_fonts` |
| Fredoka / Baloo / Nunito (Google Fonts) | https://fonts.google.com/specimen/Fredoka | SIL OFL 1.1 (commercial OK, can't sell the font alone) | Soft rounded font, matches pastel look | ❌ |
| Kenney Interface Sounds | https://kenney.nl/assets/interface-sounds | CC0 | UI SFX | ❌ |
| Cinematic Piano BGM (Rosko Vair) | https://roskovair.itch.io/cinematic-piano-bgm | CC0 | Gentle piano score | ❌ |
| Tallbeard Music Loop Bundle | https://tallbeard.itch.io/music-loop-bundle | CC0 | Ambient/cozy loops | ❌ |
| Nature Sounds Pack (Antoinemax) | https://opengameart.org/content/nature-sounds-pack | CC-BY 4.0 (credit required) | Birds, wind, foliage, footsteps | ❌ |
| Sea and River Wave Sounds | https://opengameart.org/content/sea-and-river-wave-sounds | CC0 | Beach/stream ambience | ❌ |

Not used: alkakrab music (custom free licence, not CC). Asset-store "free" packs with no-redistribution terms (Unity/Unreal stores) weren't considered.

## Gaps no free asset covers (original Blender work)
1. **Cat sit, sleep/curl, stretch, groom and knead clips.** No free cat has them. Author them in Blender on the Quaternius Cat armature (CC0, so it can be edited).
2. **Facial expressions** (blink, smile, sad, surprised) for player/Mira. No free stylized character ships blendshapes. Add shape keys or swappable face textures.
3. **Signature characters.** Mira and the player need a unique soft-anime silhouette. Use the Quaternius women/men as a base mesh and resculpt hair and outfits.
4. **Station-specific set** (Platform 6 sign, canopy, ticket gate, bench, vending machine, Japanese-style overhead lines). Train Kit only covers trains and rails.
5. **Duck and swimming birds with paddle/float anims**, plus flying birds with a real flap cycle.
6. **Cherry-blossom tree variants** in Sakura's style (ported procedural ones exist; need 3–5 LOD-friendly meshes).
7. Humanoid **sit-on-bench / pet-cat / hug / gesture emotes** on the Quaternius rig. These come from UAL/KayKit downloads or Mixamo (baked, not redistributed raw).
