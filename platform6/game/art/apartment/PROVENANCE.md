# Original shared-apartment presentation

All new geometry, brush textures and painted city imagery are original project work, supplied for commercial use with this source. No downloaded art, paid asset, external service, sample or franchised content is used.

- tools/author_apartment_art.py authors four deterministic, editable SVG textures: plaster, wood, cloth and a rainy city-window matte
- tools/author_apartment_furniture.py authors the gently beveled table, pillow, duvet and throw in Blender; editable file: source/apartment_furniture.blend. Its .gdignore prevents Godot from trying to reimport the authoring file or requiring Blender to run the game. The exported GLB is the runtime model
- world/apartment_presentation.gd assembles floorboards, curtains, framing, shelf, reading lamp, wall trim and rug details from original geometry. All additions are collision-free and static; the existing rain follows existing reduced-motion and pause handling
- Both Chapter One and Chapter Seven build the same room. No added reward prop, story flag, saved choice, network request or private-writing transmission

The preserved original protagonist and Mira Blender source files and existing third-party notices remain unchanged. This is a bounded scene-presentation milestone; other environments and character art still have intermediate-quality geometry.
