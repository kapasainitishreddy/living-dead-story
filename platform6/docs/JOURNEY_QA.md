# Journey Mode V1 · review QA

## Verified scope

- Full seven-chapter/character regression runner plus Journey tests: 43,617 reported checks, zero failures; Python GLB/exported-character contracts also pass
- Journey additions: pack 987, model/store 618, worlds 320, activities 23, runtime 291
- Native cloud Compatibility rendering: 256 checks, zero failures; 63 first/return/activity/pause/2×/stage-2-story PNGs
- Software renderer observation: 150 scene frame samples, median 33.349ms, p95 45.301ms. This is a small llvmpipe sample, not a hardware FPS guarantee
- Destination node counts: 103–347, below the tested 1,000-node scene limit
- An isolated recovered compact source is byte-compared with the frozen working tree and run through the full runner before delivery

## Tests that matter

Both campaign endings have equal explicit Journey access. Incomplete campaigns cannot enter. Every destination is boarded, interrupted by pause/return to train, resumed, completed through authored choices and saved/reloaded exactly. All original campaign fields and its separate file remain unchanged through Journey actions. The physical train board target is exercised through main.on_interact, including its empty value.

Hostile nested values, incorrect types, duplicate records, invalid dates, overflow limits, corrupt primary files, backups, reset backups, future versions, protected campaign paths and oversized uninspectable snapshots are tested. Recovering a valid backup discloses that older progress was loaded. Private words retain outer spaces/newlines; Tiny state changes cannot rewrite words, and no private words enter NPC callbacks.

Distinct activity algorithms are tested, including reversible rain channels/letter swaps, constellation undo, tea editing, actual arcade travel/paddle rebound, recoverable miss and pause freezing. Live reduced-motion changes settle the exact active arcade widget even through a pause; the test does not recreate it to hide stale preferences.

Authored time/weather, lighting warmth, music track/gain/captions, NPC work and optional Tiny invitations are consumed by presentation. Exported resource lookup uses ResourceLoader for remapped WAVs. No microphone, camera, analytics, account, clinical inference, runtime LLM, public hosting or paid service is involved.

Native Linux keyboard play covers walking, 2× scrolling, pause/resume inside an activity, two rain switches, the return-to-train route, ordinary save/quit, reopen without reseeding, physical board access, and unchanged campaign continuity. Synthetic headless tests are not substituted for this actual window/input evidence.

## Honest limitations

This is a tested bounded V1 for review, not production-ready or endless newly generated story. It has ten small original-geometry rooms/landscapes and finite authored choices. Art is intermediate; most returning cast still use simple stylized geometry. Worlds have direct loading transitions and conservative collision bounds. Close staged performance/cinematics from the campaign are preserved, not replicated at every Journey stop.

Optional written records are plain local JSON, not encrypted storage or a cloud backup. Future Echo time is local wall-clock time checked on return, with no operating-system scheduled notification. Changing timezone or system clock changes that interpretation. There is no penalty for time away.

Arcade configuration/progress are durable; an in-flight ball is settled/relaunched locally rather than persisting its precise transient physics trajectory. Reduced motion provides the equivalent cabinet demonstration. No activity gates continuation or rewards a real-world wellbeing action.

The cloud desktop uses Mesa llvmpipe, Compatibility rendering and Dummy audio. Only the Linux package is exercised here. Windows/macOS/mobile exports, physical controller hardware, user hardware performance, hearing acceptance, final-art acceptance, accessibility user testing and release-readiness remain unverified. The driver emits its known unsupported V-Sync warning; final runs reject ERROR/SCRIPT ERROR even if Godot exits zero.
