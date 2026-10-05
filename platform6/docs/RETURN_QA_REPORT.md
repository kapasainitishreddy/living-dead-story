# Chapter Six · Return Platform verification

Verified with Godot 4.6.3.stable official on the cloud Linux Compatibility renderer. This report describes the bounded six-chapter milestone; Chapter Seven remains unimplemented.

## Automated aggregate

`sh game/run_tests.sh`: **29,831 checks, zero failures**. All original Chapter One–Five test files and commands remain present. Dynamic checks that iterate snapshot fields or continuation buttons expand naturally with the added chapter.

New Chapter Six suites in the aggregate:

- Durable model: 13,974 checks across route/camera/farewell/optional-conversation combinations, malformed traces, chronology, native saves and exact reloads
- World scene: 44 checks, including actual open doorway bounds and Jo's umbrella/star
- Physical choreography: 46 checks, including skeletal lift/strap, boarding, camera slip/catch/laugh, doors, train movement, silence, 4.2-second hold, pause, skip and reduced-motion toggles
- Five distinct live acknowledgement poses: 30 checks
- Physics/reachability: 26 checks
- Playable adapter: 173 checks, including selected-response interruption, real farewell buttons, rapid repeats, normal-motion pause/Back, text/reduced-motion settings while paused, optional reread and save-before-presentation
- Failed-save exits: 9 checks covering Save and leave, pause Quit and OS close
- Music-free return sound profile/envelope: 7 checks
- Independent live-marker regression: 170 checks covering normal/skip/reduced branches and the original Chapter One return_train interaction

A full fresh-source extraction run is also required and recorded in the delivery evidence. It must pass the same aggregate with every archived entry byte-identical to the frozen tested worktree.

## Native rendered verification

`tests/return_rendered_qa.gd` ran in the actual desktop renderer: **45 checks, zero failures**, with viewport PNGs. Preparation, all train phases, pause freeze, full normal-motion departure, no immediate dialogue, 2× text farewell visibility and all three camera ownership skip paths are covered. Representative frames include preparation, close camera slip/catch, empty platform, retained farewell callback, optional conductor/Jo text and an unobstructed Jo prop inspection.

Two defects found through actual pixels were fixed before acceptance: the opaque train wall overlapped the doorway, and a canopy post blocked the boarding/catch sightline. The doorway is now physically split; the camera eases to a stable portrait for the turn/catch and back to a wider departure composition. Jo's yellow umbrella and crooked hanging star are now tangible props. Overlay outlines retain legibility against the bright carriage.

The final graphical run was performed alone after the standalone game closed. An earlier concurrent two-window run hit X11 pointer-grab contention; it was not used as final acceptance. The final log contains no ERROR or SCRIPT ERROR lines. The graphics driver reports unsupported V-Sync changes; this is retained as an environment warning.

## Exported Linux keyboard acceptance

The Linux Desktop export was run as its standalone executable, not through the editor. It started from a strictly valid completed Chapter Five/Chapter Six arrival snapshot with borrowed camera. Through actual keyboard input:

1. Walked with W to Mira and used E at the real labelled interaction
2. Paused preparation with P, resumed and allowed the normal physical preparation to finish
3. Selected Thanks using Down, Down, Enter; paused and resumed the departure
4. Let the complete normal train/boarding/catch/departure and empty-platform hold play, without skipping
5. Walked back to the hall, used E to read the optional conductor story, dismissed it, and reached the real continuation
6. Completed Chapter Six, saved and left; reopened the exact same local save without reseeding and observed the completed, settled platform
7. Closed normally through pause Quit

The actual desktop save was copied rather than reconstructed: **20 native-save checks, zero failures**. It restores strictly, retains Thanks and the borrowed camera, keeps Lower Mill as Mira's independent destination, preserves all earlier chapter flags/history/rewards/settings/fictional dimensions and confirms Jo was not required. Native PNGs show preparation, the empty-platform hold, the conductor text, completion and completed-state reopening.

## Independent review

Independent review found and verified fixes for stale live interaction markers after cinematic completion and first optional Jo/conductor visits after chapter completion. The added marker probe uses actual interactables rather than bypassing them with direct model dispatch. Selected-response disk recovery, all three camera continuities, skips, pauses, terminal visits and the original return_train route passed the final focused review. No remaining save/control blocker was identified.

## Scope and limits

Original intermediate character rigs and stylized geometry remain. This is not final anime-quality character art, full seven-chapter delivery or release certification. Linux was exercised on Mesa llvmpipe with Dummy audio; physical-controller hardware, mobile/Windows/Web runtime, hardware-GPU performance and audible mix/listening acceptance are not verified. Automated sound tests establish local profiles, silence and envelopes, not subjective listening quality. No paid assets, public hosting, VPS, repository push, analytics, runtime AI or new network service is introduced.
