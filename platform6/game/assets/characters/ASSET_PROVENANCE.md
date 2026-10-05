# Platform Six original characters

These characters and camera were created specifically for this project from
newly authored polygon contours, material colors, vertex weights and motion.
No downloaded model, stock human mesh, primitive body stack, photo, image
texture, scanned face, third-party character design or external animation is
included. There are no external texture or buffer dependencies in the GLBs.

## Original design

- **Protagonist:** chestnut asymmetrical swept hair, readable almond eyes with
  separate ivory/iris/pupil/catchlight/upper-lid surfaces, shaped nose and closed
  smile, midnight-blue tailored jacket, cream wrapped scarf with a sewn fold
  and fringe, trouser seams, warm ochre laced sneakers, contoured palms, curved
  thumbs and four distinct tapered finger silhouettes
- **Mira:** dark tapered bob and sweeping fringe, terracotta split-front coat
  with lapels, pocket welts and brass buttons, deep teal underlayer, fitted dark
  trousers and brown boots, the same independently controllable face anatomy
- **Camera:** original cream-and-teal rounded/chamfered compact camera shell,
  molded grip, machined-profile lens housing, optical glass, flash diffuser,
  viewfinder, top shutter and back display, reusable as a separate prop

The low-poly shapes deliberately use smooth sculpted contours with some flat
tailored clothing panels. This is a stylized authored art pass, not a scanned
or photorealistic human asset.

## Editable sources and regeneration

- Generator: `tools/author_characters.py`
- Character source: `protagonist/source/protagonist.blend`
- Character source: `mira/source/mira.blend`
- Prop source: `mira/source/camera.blend`
- Evidence renderer: `tools/render_characters.py`
- Binary contract validator: `tools/test_authored_character_assets.py`
- Validation metrics and content hashes: `asset_validation.json`

The sources were created with Blender 4.3.2. Each source subdirectory contains
`.gdignore`, so Godot uses the committed `.glb` rather than requiring Blender
to import an editable source. The source character files open in a neutral
A pose with animation tracks preserved and muted.

Regenerate exports without rendering:

    blender --background --factory-startup --python tools/author_characters.py -- --no-render

Regenerate studio images separately:

    blender --background --factory-startup --python tools/render_characters.py

Validate the actual exported binary data:

    python tools/test_authored_character_assets.py

## Runtime contract

All three GLBs use metres. Character soles start at local Y=0 and the closed
hair crown reaches local Y=1.7. Blender -Y forward is exported as glTF/Godot +Z
forward. Character root object is `Rig`; Godot imports its 25-joint skin as
`Skeleton3D`. There are no mesh/bone name collisions.

Bones:

    Root Hips Spine Chest Neck Head
    EyeLeft EyeRight BrowLeft BrowRight Mouth
    ShoulderLeft ShoulderRight UpperArmLeft UpperArmRight
    ForearmLeft ForearmRight HandLeft HandRight
    ThighLeft ThighRight ShinLeft ShinRight FootLeft FootRight

Head and HandRight are suitable bone-attachment socket targets. Eye/brow/mouth
local Y is vertical. Eye whites, iris, pupil, glints and upper lid are weighted
to the matching Eye bone; brow ribbons to the matching Brow bone; mouth/lower
lip to Mouth. Thus local-Y eye scaling deforms the visible eye for a blink.
Facial surfaces conform to the actual face contour rather than floating disks.
Mesh names include `FaceEyeLeft`, `FaceEyeRight`, `FaceBrowLeft`,
`FaceBrowRight` and `FaceMouth`.

## Authored animation calibration

The exported clips are lowercase `idle` (5.0 seconds) and `walk` (1.0 second).
The walk is in-place, with a **reference forward velocity of
1.3165116279 metres/second**. This is the 1.332 m/s authored track multiplied
by the common 1.7/1.72 body scale. Each stance foot moves backward through a
0.65825581395 m local track over 0.5 seconds, while hips lower to compensate
leg shortening. The recovery knee bends during swing, the foot counter-rotates
the thigh/knee, and arms swing oppositely. At game velocity 4.2 m/s, the matching
time scale is approximately 3.19025.

This calibration is also saved in `character_manifest.json`. It is not exported
as glTF extras. This gait does not include terrain-aware IK or root motion.
Godot enables looping and applies speed-linked cadence in its controller.

## Camera socket contract

`mira/camera.glb` is unrigged, with +Z lens-forward and a grip-centered origin
on the character's right-hand side of the camera. The authored shell centroid
is offset approximately +0.042 m on local X from the grip origin. Bounds are
approximately 0.151 m wide, 0.092 m tall and 0.0925 m deep including the lens.
The final hand-socket presentation is verified in Godot's station view.

## Verification and remaining scope

The binary validator checks self-contained GLB structure, exactly named bones,
unique node names, facial axes, actual animation lengths, sole/crown bounds,
normalized weights for every exported skinned vertex, valid joint indices and
forward-facing eye geometry. Godot integration separately verifies import,
motion, sockets, repeated gaze and blink behavior. Actual-runtime station
portraits/movie and paired performance evidence are the acceptance reference;
studio images are supplementary. Additional future art-direction polish can
change proportions or silhouette without replacing the rig contract.

## Hero warmth refinement, 2026-10-04

Original authored face, hair and garment contours were refined in the existing generator and Blender sources. No purchased, downloaded, copied-franchise or externally generated assets were added. The 25-bone rig, neutral source pose, one-second walk, five-second idle and hand grip origins are retained. A gentle runtime listening-expression hold/soften is reduced-motion aware. Character art remains intermediate.

## Relaxed whole-body refinement, 2026-10-04

The original two hero models were refined with narrower arm rest positions, tailored sleeve deformation, a tapered weighted neck, resting finger curvature and a more body-led idle. Mira has a distinct forward carrying posture that keeps the original camera grip origin and prop geometry while clearing her coat. The same 25 named bones and parent structure remain, with intentional changes to arm rest transforms. No external model base or assets were imported. Editable Blender sources and the generator are retained.
