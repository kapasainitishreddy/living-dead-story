> Historical milestone record. The current build adds Chapter Four; see KITCHEN_MILESTONE.md for current scope and verification.

# The Unfinished Fair · second playable chapter

This local Godot 4.6.3 build implements Chapters One and Two. Chapters Three–Seven remain planned and unavailable. Original protagonist/Mira rigs are preserved; the stylized Ada and world art remain intermediate.

## Playable content
- Chapter One’s original 12 checkpoints, three shore shapes, alignment puzzle, camera options, real-world invitation and Platform 6 souvenir remain intact
- Explicit Continue / Save and leave adapter after the original ending, including reopening a completed Chapter One save
- Warm compact fair courtyard, accessible deck, pond rim, optional hours/prize/bird inspections, train and labelled future doors
- Left/straight/right rudder, triangle/square/folded sail; operate/watch/cooperate modes
- Visible winding keys and animated boats; first race drifts to the duck, boat/pond/together/watch inspections reveal the crooked platform, self/Ada repair levels it
- Deterministic first/second/third/circle/spectator outcomes with equal fair buttons and distinct jokes; replay preserves canonical history
- Explicit camera callbacks, sign-card/speak/wait departures and Mira’s independently chosen Lower Mill workshop
- Clear end of available build; no fictional implementation of conservatory/supper/orchard/home chapters

## Persistence and safety
Schema 2 retains the existing save_v1.json filename. All version-1 checkpoints migrate without invented choices, relationship history or emotion weights. Only the explicit camera choice becomes a historical callback. The original version-1 source is retained byte-for-byte in immutable .v1.bak, including recovery from a rotating v1 backup. Verified rotating backups, damaged-source retention, future-schema protection and recoverable reset backups remain local.

Choices use a validated authored JSON catalog and bounded fictional joy/calm/connection/wonder/agency/energy/future_pull/meaning dimensions. These are hidden story weights, not a real-user diagnosis. Unknown IDs fail safely. Consequences are idempotent; physical configuration remains reversible. Malformed/premature choice history is rejected; failed transitions roll back. Mira/Ada have independent fictional state; Mira’s destination is autonomous on all completed routes.

Done and Not tonight retain the same story/relationship consequences, souvenirs and access. No NPC sees their raw value. No decay, attendance penalty, timer, streak, FOMO, network call, account, runtime AI, microphone/camera use or paid asset was introduced.

## Verification
See evidence/fair/final-tests.txt, evidence/fair/branch-matrix.txt and evidence/fair/rendered/report.json. The final aggregate suite passed 2,667 checks, including all 470 old checks and exercises migration, malformed saves, exact immutable backup bytes, each fair checkpoint/reload, all 27 configuration routes, canonical-safe replay, NPC autonomy, durable fair collection, world collisions, menus, pause and live reduced-motion toggles.

Actual cloud desktop Godot Compatibility rendering completed the full chapter and all five outcomes, with 2× choice visibility, race pause, camera callbacks, reload and screenshots. The exported Linux release binary additionally completed a native spectator/repair/pause/replay/departure route; its final saved JSON validates. Separate source native keyboard traversal walked the production deck to Ada, set a left rudder/folded sail, operated both races, inspected/shifted the wedge, completed the circle route, scrolled the end disclosure and quit normally. Manual screenshots are in evidence/fair/manual. Test seeds set a fair-arrival checkpoint only; all subsequent manual actions use ordinary production controls.

The cloud renderer is Mesa llvmpipe software OpenGL. VSync-mode warning is driver-specific. Audio assets/settings are checked, but hardware listening is unverified because this cloud desktop has no audio device; graphical QA explicitly uses Dummy audio. Physical controller hardware, Windows/Web runtime, macOS, Android/iOS and hardware-GPU performance are unverified. Exports are milestone packages, not store-ready or signed releases. No play-duration claim is made.
