# Hero warmth checkpoint · 2026-10-04

## What changed

This is a bounded refinement of the existing original Mira and protagonist assets. It is not a new campaign or a whole-cast art replacement.

- Upper eyelids now share the actual smooth almond eye contours instead of cutting across the enlarged whites
- Calmer iris/pupil/glint proportions, a more deliberate cheek-to-chin taper and smaller nose profile
- Flatter tapered hair clumps, a restrained directional fringe accent and deliberately unequal Mira temple-lock lengths
- Less inflated upper sleeves; shorter curved collars and lapels conform to their underlying torso with compatible skin weights
- A listening expression gently rises, holds and softens; reduced motion clears decorative brow/mouth offsets immediately

The original 25-bone rig, bone names/parents, 1.7 m ground-origin contract, idle/walk timing, in-place gait and prop grip origin are retained. The editable .blend sources and the source generator are included. No external or paid assets/services were used; original music remains unchanged.

## Verification

- Baseline full suite: 43,935 checks, zero failures
- Final full suite: 43,945 checks, zero failures, including the ten new expression/reduced-motion checks
- Exported character-asset and prior character-polish contracts pass
- New exported hero warmth contract passes; original eyelid and asymmetric-hair regressions fail against baseline assets
- Actual Compatibility-renderer close-ups and wider views captured before/after under the same setup
- Real game-controller animation capture: 727 frames at 24 fps, 30.29 seconds; idle, input-driven walk/stop/turn, conversation gaze/blinks, reduced-motion segment and Mira camera socket. The labelled side-by-side MP4 is visual-only
- Final Linux release exported and exercised with native keyboard/mouse controls: approach Mira, E interaction, optional boats dialogue, Escape cancellation, repeated interaction, pause/settings, reduced-motion toggle, quiet-company branch, shoreline progression, normal quit and reopen
- Eight checks on the actual native save/reopened save: strict restore, shoreline checkpoint, persisted reduced motion, identical full snapshot, unchanged schema and no presentation-generated choice consequences
- Fresh extracted archive validation is recorded in evidence/hero/fresh-archive-tests.txt

The Linux run used Mesa llvmpipe Compatibility rendering. No target-GPU/mobile performance, physical controller, Windows, macOS or Web runtime acceptance is claimed. One Return-key press did not visibly activate the focused dialogue control during native QA; mouse activation, E, Escape, P and movement worked. Existing automated keyboard/controller navigation coverage remains unchanged. This pass does not establish a new native Enter acceptance claim.

## Honest art assessment

The characters are clearer and more intentional, but the visual improvement is incremental. They remain intermediate original procedural character art. Near-A-pose arms, tubular limbs, the cylinder-like neck connection, simplified facial anatomy and camera grip, and blocky carriage surroundings remain visible. This is not production-grade painted anime art or a Genshin-quality claim.

The next high-impact pass should address whole-body silhouette, a more natural relaxed pose and deformation/modeling fundamentals with a deliberately authored model base. More small eyelid deltas alone would not solve those issues. Supporting cast and environments were deliberately preserved in this checkpoint.

## Preserved game contracts

All seven authored chapters, ten Journey destinations, saves, story branches, NPC independence, choice consequences, non-punitive Done/Not tonight outcomes, privacy, offline behavior and accessibility remain covered by the existing regression suite. No VPS, public deployment, GitHub push, analytics or external runtime service was added.
