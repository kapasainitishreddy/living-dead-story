# Asset manifest

## Whole-game illustrated graphics pass (2026-10-10)

Original Godot presentation in `world/illustrated_world.gd` and
`art/illustrated/`: selective cool ink, matte cel shading, static paper finish,
painted blossom masses, potted plants, coastal grass, winter branches, distant
hills, floorboards, paving, linen folds, shore ribbons and framed destination
signs. These are original project work provided for commercial use with this
source. Existing original Blender, SVG, music and ambience assets are retained.

Reviewed references: [Sakura Crossing](https://github.com/Kenton-GMI/sakura-crossing),
its MIT notice and `src/core/toon.js`, inspected 2026-10-10; stepped lighting,
cool shadows, pale foliage masses and selective contours informed the visual
direction. This is an original Godot implementation. No Three.js code, bundled
art or stock music was copied for this pass. The previously included full MIT
notice in `SAKURA_CROSSING_LICENSE.txt` remains preserved.
[Hotpot's resource directory](https://github.com/HotpotDesign/Game-Assets-And-Resources)
does not grant a blanket asset license. No listed asset was downloaded or used;
no purchase or third-party generation service was needed.

Earlier milestone entries below describe their own historical asset state.

All assets are original for this slice, authored October 3, 2026. No third-party art/music imports or purchases.
- Procedural environments, simple humanoids, umbrella, water, train and props: authored by the Platform 6 implementation assistant using Godot primitive meshes/materials; original project work, provided for commercial use with this source; game/world/world_factory.gd and game/player/player.gd
- Night Train pad/bell music: original additive synthesis, deterministic score; game/assets/original/generate_audio.py; game/assets/original/night_train.wav; generated October 3, 2026; original project work, commercial use permitted; no samples
- Rain/sea bed: original filtered deterministic noise; same authoring script; game/assets/original/rain_sea.wav; generated October 3, 2026; original project work, commercial use permitted; no recordings
- Dialogue: original authored prose in game/data/chapter.json; no AI runtime, voice or third-party text
- Font: Godot built-in default font (Noto Sans); included in engine distribution. Font licence attribution is provided by Godot's third-party licence viewer. No separate font file copied into project
- Godot Engine 4.6.3: MIT; https://godotengine.org/license/; notice in GODOT_LICENSE.txt. Engine not bundled in source ZIP

## Station-first visual pass (2026-10-03)
Canopy, train trim/windows/curtains/door, tiled platform, benches, foliage,
umbrella, distant architecture, and rounded character clothing/hair/accessories
are original procedural 3D geometry authored in world/world_factory.gd.
No Genshin Impact characters, models, textures, branding, or other game assets
are included. The external concept is a composition reference, not a game
background or shipped asset.

## Painterly station milestone (2026-10-03)
Original 1024×512 SVG atlas, landscape posters, material ramp, facade art,
clock and chamfered train visual are authored in art/station/ and
world/station_presentation.gd. Source generator: docs/art/generate_station_atlas.py.
These are original project work, provided for commercial use with this source.
No external texture, Sakura Crossing code/art, character or music asset is copied.
See art/station/PROVENANCE.md. Existing procedural characters remain provisional.

## First-chapter story, sound and motion enrichment (2026-10-03)
- Mira, umbrella exchanges, landmark observations, jokes, paper boat, fair postcard and breakfast dialogue are original fictional project work. Characters are provisional. No testimonial, therapy script or licensed plot is adapted
- Location audio: rain_window.wav, rain_roof.wav, rails.wav and surf.wav are deterministic original synthesis by game/assets/original/generate_audio.py, no samples/recordings; original project work, commercial use permitted
- Sakura Crossing reference: Kenton Wang, https://github.com/Kenton-GMI/sakura-crossing at de01898e89c7f6ab3fad93fa802f0f5ac66fbd81, inspected 2026-10-03, MIT. Exponential damping concept from src/core/player.js:225–235 and asynchronous idle/weather principles from src/world/index.js:665–684 and src/world/petals.js:48–114 are adapted as original Godot routines in player/player.gd and world/ambient_motion.gd. Full copyright/MIT notice is in SAKURA_CROSSING_LICENSE.txt. No Three.js engine code, character rig, visual asset or audio file is imported; the reference has no humanoid animations
- Umbrella sway and low-density breakfast steam use original Godot primitives. Reduced motion preserves orbit and freezes sea/decorative motion and hides rain/steam
The earlier station milestone's no-code-import statement describes that earlier pass. This enrichment credits the subsequently reviewed MIT animation techniques.

## Original protagonist and Mira character milestone (2026-10-03)
- Assets: protagonist/protagonist.glb, mira/mira.glb, mira/camera.glb in game/assets/characters/. Creator: Platform 6 implementation assistant, authored specifically for this project in Blender. Source: tools/author_characters.py and corresponding source/*.blend files. No downloaded or purchased model, texture, motion-capture clip, franchise likeness or stock cast is reused
- Date/version: authored 2026-10-03; reproducible original mesh/rig/animation generator retained in this source. License: original project work, provided for commercial use with the source; no third-party asset license applies. Attribution: no additional third-party attribution required for these original assets
- Modifications: custom contoured faces, eyebrows/eyes/lids/iris/pupil/catchlights, distinctive hair, tailored clothing, fingers/thumbs, soles, armature and weighted surfaces; original idle/walk clips; original compact camera geometry. Used in protagonist player visual and Mira passenger/shore/breakfast placements only
- Character performance controller and additive turn/conversation/gaze/face routines are original GDScript. Existing exponential-damping technique attribution above remains preserved
- Quaternius Universal Base Characters/Universal Animation Library and KayKit character animations were considered as candidates but were not downloaded or included. No license clearance for those candidates is implied, because this milestone uses locally authored original assets
- Existing Godot MIT and Sakura Crossing MIT notices are unchanged; no reference audio or external character assets are added. Original Night Train and location audio remain unchanged

## Delivery report font (not a game asset)
The character milestone PDF embeds a subset of installed DejaVu Sans, by Bitstream/DejaVu contributors. Commercial use and redistribution are permitted under the Bitstream Vera/DejaVu font license, verified 2026-10-03 against the exact official source https://dejavu-fonts.github.io/License.html and the installed package copyright notice. The full notice is attached inside the PDF and accompanies delivery as DejaVu-Font-License.txt. No font file is added to the game; Godot's built-in game font is unchanged.

## The Unfinished Fair milestone (2026-10-03)
- Original fair courtyard, pond, duck, wooden bird, boat hulls/sail silhouettes, pennants and deterministic race trajectories are authored project geometry/code in world/fair_world.gd and world/fair_race.gd. Ada remains a stylized intermediate character; the existing original protagonist/Mira rigs are retained. No paid/downloaded asset or final-art claim
- fair_clockwork.wav is deterministic original mathematical synthesis by tools/author_fair_ambience.py, using quiet damped clicks and a soft reed-tone refrain. No recording, sample or external music is used. Original project work, commercial use permitted with this source
- Chapter Two dialogue and validated fictional choice rules are original project work, not clinical profiling or a diagnosis. No real device access or network service is introduced


## Chapter Three paper workshop
Noor/Rafi silhouettes, conservatory glass/wood/paper stands, hanging sign, bent-propeller ornament, leaf/timetable boat/stars and low-graphics shadow silhouettes are original procedural Godot geometry authored for this project. No paid assets or imported artwork. Rain reuses the project’s original synthesized rain-window bed. Character and environment art remain intermediate.


## Night Kitchen additions
Original procedural Godot geometry and motion in world/kitchen_world.gd: kitchen, place settings, steam, serving utensils, bread/tearing hands, cups, condensation, furniture and callback props. Existing original character assets and paper geometry are reused. No external or purchased art is added.

assets/original/kitchen_simmer.wav is original deterministic synthesized soup resonance, bubble and cup-tap audio authored by tools/author_kitchen_ambience.py using Python's standard library. No recordings, samples or third-party sound source is included. These additions carry the same project code/art license as the existing original assets.


## Quiet Orchard original audio
assets/original/orchard_hush.wav is original deterministic mathematical synthesis authored by tools/author_orchard_ambience.py using Python's standard library: soft filtered leaf-rustle noise, far station hum and sparse rounded wooden resonances. No recording, sample, external sound source, paid asset or service is used. Original project work, commercial use permitted with this source; no additional third-party attribution required.

## Chapter Six original staging

Return Platform station geometry, split-doorway train, canvas tool roll, umbrella/star props, manual skeletal acknowledgements and authored camera choreography are original project code. The existing original Mira/protagonist rigs and synthesized rail ambience are reused. No additional paid or downloaded third-party asset is introduced.


## Chapter Seven · STILL HERE (2026-10-03)
- Original ordinary mug, chair, crossword, kettle, drawer, coat and shoes are shared geometry in world/world_factory.gd, present identically in the original and returning apartment. Home ticket, tea staging and fixed quiet ending views are original project work in world/home_world.gd
- Seated presentation reuses the preserved original protagonist rig; no downloaded model, pose or animation asset was added. Chapter Seven dialogue, choices and credits are original authored project prose. The existing rain bed is reused without a new reward song
- These additions are original project work supplied for commercial use with this source. Existing Godot/Sakura notices remain unchanged; no additional third-party asset licence applies. Character/environment art remains intermediate

## Character-model and natural-motion polish (2026-10-03)
- Original Blender face contours refined with smooth cheek/jaw stations, rounded shallow noses, and larger smoothly contoured almond eyes. Rounded hair crowns and curved swept clumps keep the existing protagonist/Mira identity and palette; Mira's brow and eye line are opened for readability
- Mira coat fronts/pockets are curved skin-weighted cloth surfaces; upper trouser contours stay inside the coat. All geometry remains original project work, with the same commercial-use terms and editable Blender sources
- Varied quick-close/slow-open blinks, earlier eye fixation, restrained held eye darts, breathing/listening tilt/nod and quicker locomotion settling are original GDScript. The existing rig bone names, 1.7 metre height, story/save data and authored chapter staging remain unchanged
- This is a verified bounded polish milestone, not final character art, terrain IK or target-device performance acceptance

## Shared apartment presentation (2026-10-04)
Original editable SVG brush textures/city matte, original beveled Blender furniture and collision-free scenic Godot geometry are shared by the opening and returning apartment. See art/apartment/PROVENANCE.md. New work is provided for commercial use with the project source. No third-party or paid asset is introduced; existing authoring sources and notices remain included.

## Supporting cast and transit completion (2026-10-05)

Ada, Noor, Rafi, conductor and Jo are original project-authored face/body/hair/costume topology, skin weights and compatible idle/walk rigs. Source: tools/author_supporting_cast.py and the five editable Blender files; no external model, texture or animation was imported. Provided for commercial use with this source, like the retained original hero assets. Generic background roles reuse these authored models.

Original rounded upholstery, carriage joinery/ceiling/bulkheads, lighthouse/curved arch and shore detail are authored in world/transit_presentation.gd. The editable night view in art/transit/night_view.svg is original; existing original apartment surfaces are reused. No paid services, runtime dependencies or external assets are added. Existing Godot/Sakura Crossing notices remain unchanged.


## Opening story, depth and stereo soundtrack refresh (2026-10-05)
- Original layered city/roof/coast geometry and painted twilight SVG in world/opening_depth.gd and art/opening_depth/. Editable generator tools/author_opening_depth.py and provenance accompany the source. No downloaded image or paid generation.
- Original physical opening props, viewpoint preview and character-hand attachment code in world/opening_story.gd. The existing original Mira camera GLB and original rigs are reused, with one visible camera following the fictional ownership choice.
- Five 48-second original stereo synthesized arrangements and seven 24-second ambience loops replace the earlier shared pad and rough beds. Generated deterministically by assets/original/generate_audio.py; soundtrack_manifest.json retains arrangement data and byte hashes. No recording, sample, artist imitation, paid generation or external audio service. Original project work, provided for commercial use with this source under the existing project terms. Earlier audio descriptions above describe historical versions.
- All Godot and Sakura Crossing notices remain included. No runtime network or device/audio-recording permission is introduced; capture tests are optional developer scripts only.

## Sakura animation pass (agent/sakura-anim-pass)
- `art/sakura/sakura_cel.gdshader`, `art/sakura/sakura_ink.gdshader`, `art/sakura/sakura_style.gd`, `world/sakura_birds.gd`, the rebuilt `world/cat_companion.gd`, and the procedural body layer in `characters/character_performer.gd` / damped movement in `player/player.gd` are original GDScript/shader code for this project. Techniques (banded cel light with violet-tinted shadow bands, inverted-hull ink, warm key + cool fill lighting and palette values, critically damped `1 - exp(-k*dt)` easing, the cat's proportions) are adapted from Sakura Crossing by Kenton Wang, MIT licence, https://github.com/Kenton-GMI/sakura-crossing — see `SAKURA_CROSSING_LICENSE.txt`. No Sakura Crossing assets or files are copied.

## Real-model pass (agent/real-models) — third-party CC0 assets
All files below live in `assets/third_party/` and are **CC0 1.0 (public domain)**; each pack's original `License.txt` is kept beside the models. Downloaded free from kenney.nl on 2026-10-13, no account or payment. Credit (voluntary): Kenney, www.kenney.nl.

| Folder | Pack / source URL | Licence | Files used | Used for |
|---|---|---|---|---|
| `kenney_mini_characters/` | Mini Characters 1.0 — https://kenney.nl/assets/mini-characters | CC0 1.0 | `character-male-a` (protagonist), `character-female-b` (Mira), `character-female-c` (Ada), `character-female-a` (Noor), `character-male-b` (Rafi), `character-male-c` (conductor), `character-male-e` (Jo), `Textures/colormap.png` | Rigged players/NPCs with idle, walk, sprint, sit, emote-yes, interact clips |
| `kenney_cube_pets/` | Cube Pets 1.0 — https://kenney.nl/assets/cube-pets | CC0 1.0 | `animal-cat`, `animal-chick`, `animal-parrot`, `Textures/colormap.png` | Cat companion (idle/walk/run/eat/gesture clips) and birds (idle/walk/eat/dance) |
| `kenney_nature_kit/` | Nature Kit — https://kenney.nl/assets/nature-kit | CC0 1.0 | `tree_oak`, `tree_default`, `tree_fat`, `tree_detailed`, `plant_bush*`, `flower_*`, `grass*` | Roof / platform / overlook trees, bushes, flowers (foliage recoloured in code to spring tones) |

Licence verification: each downloaded zip's `License.txt` reads "License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/", and each asset page states CC0. The original project rigs remain in the repository and still load (for sockets and the existing contracts) but are hidden in favour of these models. `characters/stylized_rig.gd` (AnimationTree blending), the spring-day lighting in `world/illustrated_world.gd` and the capture script `tests/real_capture.gd` are original project code.
