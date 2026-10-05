# Painterly station milestone — October 3, 2026

Approved scope: upgrade the existing station presentation in Godot 4.6 Compatibility, with unchanged story, controls, save data, collisions and optional outcomes. Keep night identity and explicitly provisional procedural characters. No external art, engine migration, paid service, publication or push.

## Implementation sequence
1. Freeze source and capture matching medium-quality station baseline at1280×720
2. Add failing station isolation, fallback, collision, atlas and custom-material checks
3. Author one original 1024×512 SVG sheet, a shared opaque three-band shader and station-only presentation layer
4. Add visual train bevels, travel posters/clock and replace distant bright window boxes with painted opaque facades
5. Run all regression suites; inspect fixed and moving Compatibility frames; compare warmed60-second stationary and route median/p95 timings
6. Retain only effects that pass readability and software-renderer cost gates; commit source and verified evidence

## Presentation design
- Shadow hue: lavender; controlled fill and warm cream highlight band
- Custom per-light diffuse accumulation respects incidence/attenuation. Shadow floor is emitted once per fragment; Compatibility multiplies diffuse contribution by albedo once
- Authored atlas marks: broad stone wear, wood grain, plaster repair, carriage seams/rivets, canopy panels, quiet skyline windows and original landscape posters
- Fragment lighting is explicitly retained with force_vertex_shading=false (already the desktop default). The atlas intentionally uses linear filtering without mipmaps; broad marks avoid high-frequency texture noise, and facade boundaries have a 2px inset
- BoxMesh UVs normalized to the full face in newly created ArrayMeshes. Original shared meshes and every collision shape remain untouched
- Main train visual is a26-face chamfered box with original extents and original BoxShape3D collision
- Original opaque distant buildings remain actual geometry. Removed decorative window boxes are replaced with painted facade marks; no background cards inside the walking area
- Ordinary depth fog separates skyline from station; no new shadow-casting local lamps
- Existing spring arm, no camera bob and reduced-motion treatment retained while camera-route QA verifies readability. Lens changes require comparing gameplay framing before adoption
- Original characters, gait and faces unchanged: this pass does not represent modeled/rigged anime characters

## Fallback
Project setting station/painterly_enabled=false builds the old station art/materials. All other locations are unchanged. No screen-space ink, fullscreen postprocess, transparency or additional renderer capability is required. Inverted hull ink remains subject to actual visual evidence, rather than outlining every prop automatically.

## Evidence
The benchmark and QA report are written after actual runs. Headless tests verify scene/gameplay invariants but cannot prove shader compilation or visible quality; those require the real Compatibility desktop capture.

## Palette/style sheet
- Ink/navy: #24364f, existing structural blue and dark train enamel
- Lavender fill: #9186b8, violet shadow separation instead of neutral gray
- Stone: existing #777b87 with broad #d4cfc7 scumbles, no noisy photoreal roughness
- Wood: existing #9c7054 plus #ac9174 long curved grain; steel bench legs retain enamel treatment
- Cream/brass: existing #ece2cb / #b99055; glowing train windows remain existing #eebf79
- Distance: #7787a6 multiplier with muted #cfba97 painted windows, no bright per-window geometry
- Posters: original moon/sea and mountain geometries, broad flat fields, cream borders and restrained dark linework

The three-band material uses a small smooth transition at band boundaries to avoid overly brittle pixel edges. It is an opaque, one-sample atlas material. Surface marks remain object-UV anchored as the camera moves. Ordinary depth fog is intentionally gradual from 15m to 48m; it is not a fullscreen reconstruction effect.

## Acceptance result

The held medium station frame and moving route pass the relative software-renderer cost gate. Final paired stationary p95 improves 6.9%; moving p95 improves 4.6%. Headless regression suite 353 checks passes; corrected real-display settings/fallback/orbit/keyboard QA 94 checks passes. Independent production-code review is clear. See game/QA_REPORT.md and paired metrics for details and limitations.

High shadows are a documented remaining presentation limitation: fallback-high shows the same diagonal layout, while the new floor's color separation makes it stronger. Medium is the reviewed baseline/candidate setting. No outline pass is shipped, and no new automatic camera animation is added. Retain the existing stable spring-arm/no-bob behavior rather than introduce movement merely for the art pass. Original character modeling/rigging, physical-controller validation, a target-GPU performance gate and spreading the style beyond this station remain separate work.
