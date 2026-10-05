# A Place Before a Task · Chapter Four

This local Godot 4.6.3 milestone implements Chapters One–Four. Chapters Five–Seven remain planned and unavailable. It is a playable review checkpoint, not a complete campaign or store release. Kitchen, food and additional character art remain intermediate original procedural geometry; existing protagonist/Mira authored rigs are preserved.

## Playable scope
- Explicit optional Night Kitchen continuation from the preserved Chapter Three completion
- Player's bowl, cup, spoon, folded cloth, fair button and drawn-back chair already present on arrival
- Sit immediately, take the ladle, and watch routes receive supper equally
- Reachable physical bread, cup and pepper interactions; watching the food pass is a full route
- Live soup steam, ladle pouring, paired tearing hands and bread, bowls/cups, pepper, food passing, chair movement, condensation and working/conversing NPCs
- Noor, Ada and Mira maintain authored continuity; Rafi has gone home as in Chapter Three
- Mira discusses her own Lower Mill workshop and early tram. No response changes that decision
- Exact saved paper geometry, bent propeller, BOATS WITH OPINIONS, original fair button and take/lend/unopened camera callbacks remain physical
- Optional fixed dinner/sign views; immediate Esc/B return, whole-room pause/resume and scrolling 2× text
- Reduced motion freezes decorative movement and instantly settles functional gestures, including a live toggle
- Original locally synthesized simmer/cup bed with optional sound captions; no recordings or external assets

## Persistence and safety
Schema remains 2 with neutral optional kitchen defaults on older schema-2 saves. Original v1 migration, backups, damaged-source retention and future-schema protection remain unchanged. Accepted actions save before bounded presentation; interrupted/reloaded gestures reconstruct coherent dinner staging. Completion traces are ordered and validated. Repeated input cannot advance twice or change a completed route.

All 36 mode/exchange/departure combinations retain exactly the same prior souvenirs, fictional hidden dimensions and NPC state. Chapter One's real-world Done and Not tonight still have equal durable outcomes; that response is never revealed to NPCs. There is no earned admission, score, rank, task debt, diagnosis or treatment claim, network call, device permission, paid asset/service, VPS change, public deployment or GitHub push.

Failed saves keep an explicit warning through captions, animation completion, optional views and pause. Save and leave remains open until saving succeeds. A successful later settings/save retry clears the stale warning. Explicitly leaving a gesture immediately settles its saved result and restores exploration without opening an unwanted modal.

## Current verification
The final aggregate runner passes 14,680 checks, including all original 12,149 checks. Additions: kitchen model 1,960; scene/motion/staging 287; actual player physics/nearest target 87; runtime/interruptions/accessibility adapters 114; real-store save-failure/exit retry 49; sound/shutdown 8; character rest regression 26. No Godot ERROR or SCRIPT ERROR lines occur in the final aggregate log.

The final X11/Compatibility graphical run passes 310 checks across all 36 dinner routes, all nine dialogue screens at 1×/2× text, pause/resume, timed serving/tearing, a live reduced-motion toggle, fixed views and exact reloads. Actual PNGs were inspected. Final graphical shutdown logs no resource/leak errors.

Native unsigned Linux release keyboard playthrough began from a seeded Chapter Four arrival only. All subsequent actions used ordinary movement, E, keyboard menu focus and pause controls: help with serving; pause/resume the ladle gesture; walk to the actual bread target; pass torn bread; ask Mira what she will repair; inspect completed table; Save and leave. Release was restarted without reseeding, completed conversation/table/torn bread were reopened, then Quit to desktop completed normally. Actual saved JSON passes 12 production-model checks and retains help/bread/ask, exact prior sign configuration, camera choice, optional response and autonomous Lower Mill decision. Both final native logs contain no Godot errors or leak messages. The driver reports a nonfatal V-Sync capability warning.

A rendered run exposed an inherited rig-rest error: generated presentation clips overwrote imported local bone rest rotations with identity. A red→green actual-skeleton test now confirms protagonist/Mira hands below the head in reduced-motion rest and after walking. The minimal quaternion-composition fix leaves original GLBs and authored idle/walk unchanged; all existing 68 character checks pass. Corrected pixels were independently inspected.

Windows/Linux/Web unsigned exports build successfully. Only the Linux runtime is verified. Current evidence is under evidence/kitchen; compact editable source excludes evidence, exports and Godot caches.

## Limits
Graphics run on Mesa llvmpipe software OpenGL. This establishes graphical correctness on the cloud Linux host, not smoothness on hardware GPU or mobile. Dummy audio is required because this host has no audio output; mixer/streams/captions are tested, human listening is unverified. Windows/Web runtime, macOS, Android/iOS, physical controllers, signing and store acceptance are unverified. No duration claim is made. Chapters Five–Seven and production art/polish remain unfinished.

## Source provenance
Based on recovered Chapter Three commit 7979185257c0adbf4239a2a154ed713c05e76593 in an isolated chapter-four worktree. Early integrated source was persistently checkpointed before final QA so another cloud replacement cannot erase the work. Prior recovery details remain in PAPER_MILESTONE.md.
