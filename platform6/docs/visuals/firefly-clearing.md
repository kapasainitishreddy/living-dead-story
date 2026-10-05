# Fireflies at the Field Edge: frozen visual progress checkpoint

This is a single-destination art-direction improvement on Journey V1, not a claim that the full game or the final premium painted-anime target is complete.

## Scope and design

Firefly-only presentation now has a deep indigo sky, original painted foliage, cool lifted meadow shadows, two warm enclosed paper lanterns, concentrated firefly clusters, a continuous blended winding path, layered rolling ridges, a stream crossing, and a distant three-car evening train grounded on rails and a sloped embankment. Low brush visually replaces the rectangular perimeter fence. The existing collision proxies remain in their original safe positions; the visual horizon is scenery, not additional walkable world.

The physical constellation board is smaller, a close-range observatory/art board. World title banners were removed from this vista. NPC/revisit text is visible only at close range; the authored full activity instructions remain in the activity UI, with a shorter nearby interaction cue.

No story, model, save-store, campaign progression, destination roster, activity rules, or visit/local-choice consequences changed. Camera and spawn remain the original baseline for the paired screenshots.

## Asset provenance

- `game/assets/foliage/moonlit_alder_crown.png`: original project-specific image generated with the built-in OpenAI image generation tool, genuinely transparent RGBA, 1254x1254 pixels. No downloaded third-party assets, licensed stock, paid asset packs, or external generation services were used. The original alpha and image provenance metadata are retained.
- Geometry, sky shader, meadow colors, path, railway, lantern enclosures and instancing are original authored source in `game/world/firefly_clearing.gd`.
- Existing character assets and their provenance remain unchanged.

Exact canopy generation prompt:

Use case: stylized-concept. Asset type: original game foliage alpha texture to apply to crossed 3D canopy planes in a Godot nighttime clearing. Create ONE isolated broad, irregular deciduous tree crown, no trunk, no ground, no sky. Genuine transparent background. Fine natural scalloped outer silhouette made of small foliage clusters, multiple layers of hand-painted leaves. Premium painted Japanese animation background technique, watercolor-gouache brushwork and softly layered shapes, NOT polygonal, NOT spherical blobs. Cool indigo teal shadows deliberately lifted, muted sage blue-green upper leaves, restrained silver moonlight along upper-left edges. Darkest color still readable navy teal. Entire canopy fits inside square image with clear transparent margin. No text, no logos, no characters, no scenery, no glow, no fake screenshot. Render only an original crown texture, professionally authored organic silhouette.

## Evidence and constraints

The native Compatibility/llvmpipe capture uses the same spawn, camera and 1180x812 application viewport before/after. Final focused graphical QA: 31 checks, 0 failures, including activity/story/pause/2x text/reduced motion/remembered return. Fifteen sampled native software-render frames gave median 63.330 ms and p95 67.068 ms; matching old Firefly scene gave median 41.651 ms, p95 50.073 ms. This is approximately 52% more frame time on the software renderer, an observational art-cost tradeoff, not a hardware performance certification. Real GPU/controller/audio hardware remain unverified.

The exported Linux executable was played through the actual keyboard and pointer UI: walking to the board, opening activity, advancing story, selecting the star-line choice, returning to the carriage, revisiting Fireflies, normal quit, and a separate restart without reseeding. Saved visit count and star-line local state survived. Campaign JSON was semantically exact against the original completed-campaign fixture. Native save fixtures are isolated QA user directories, not the user's saves.

Independent screenshot review accepted the final version only as a frozen progress checkpoint. Remaining gaps include plain cylindrical trunks and simple characters against detailed illustrated foliage, relatively flat walkable terrain, and graphic horizontal hill/railway bands. The scene has a recognizable night mood and clearly improves the prior empty fenced room; it does not yet consistently reach the final premium painted-anime world target.

## Reproduce

Use Godot 4.6.3 Compatibility. Set fresh writable HOME/XDG data/config/cache directories before running the tests in a managed environment. `sh game/run_tests.sh` runs the existing full suite plus a 26-check Firefly visual contract. `tests/firefly_rendered_qa.gd` captures the Firefly-only native QA matrix. `FIREFLY_QA_DIR` may set an absolute output directory, allowing paired captures against the frozen previous source. `tests/firefly_native_seed.gd` creates an isolated completed-campaign Firefly test save.
