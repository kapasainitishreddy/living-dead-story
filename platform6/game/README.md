## November 18, 2026 · camera-aware little discoveries (source integrated; native verification pending)

**Vision:** In the warm single-player 3:17 journey, noticing the cup, postcard or small kindness in front of you should feel intentional. Turning the camera is a gentle way to settle overlapping prompts, not a precision aim challenge or a reward quota.

**Playable increment:** When two objects are similarly close, the actual player now lightly favors the one near the camera's horizontal forward direction. The preference is capped at 0.48 m of *selection score*; real 3.2 m interaction reach, existing 0.28 m stability margin, and E/A/touch action remain intact. A substantially closer object behind the player is still reachable. Prompt, selected object and natural head/eye glance remain a single focus, with no auto-camera turn, new settings/save keys or loss of reduced-motion access.

**Verification:** Added native player_interaction_focus.gd assertions for front/rear ties, camera turns, closer rear objects, action dispatch, reduced-motion targeting and the hard reach limit. Independent geometric score sweeps confirmed the bias bound and no out-of-range acquisition; source contracts and GitHub remote blob readback checked. **Godot import/native suite, actual 1× playthrough, controller/touch/Windows and human accessibility review were not run here** because the Godot executable and full checkout were unavailable. Next: run the platform6/game/run_tests.sh regression gate, rotate beside clustered objects while watching the focus prompt, and test a rear interaction without moving. This is not release sign-off.

## November 18, 2026 · grounded footsteps for unhurried wandering (source-integrated; native verification pending)

**Vision:** Ordinary walks between the 3:17 train, shared soup and optional imagination adventures should have gentle physical feedback, not a reward meter. Shoes only sound when they actually move across the ground.

**Playable increment:** Two distinct, original, local 100 ms cloth-and-sole sounds alternate according to *actual grounded displacement* after collision, not movement input. Running against a wall, being airborne, stopping, entering dialogue or pause resets the cadence instead of accumulating delayed sounds. One near-foot 3D sound source stays within 8 m, uses existing Master/Effects levels, and stops on mute or control lock. The minimum interval is 220 ms, with no camera shake, new save keys, service calls or downloaded samples. Reduced-motion retains audio without visual motion.

**Exact verification:** Added `tests/player_footsteps.gd` to the real Godot test runner, covering left/right sample generation, grounded steps, blocking walls, airborne travel, pause/dialogue, fresh resume, mute and reduced motion. Deterministic contact-policy calculations and source contracts were checked outside Godot. **Godot import/native tests, 1× audio/video playback, real controller/Windows and independent human feel review were not executed here** (engine and complete checkout unavailable). Next: `cd platform6/game && ./run_tests.sh`; listen at normal speed, start/stop and run into a wall, compare mix with rain/soup, then complete controller/accessibility and fresh-process review. This is not release approval.

## November 18, 2026 · touchable paper-market signs and rolling cart (source-integrated; native verification pending)

**Vision:** STILL HERE: PLATFORM 6 is a warm, unscored single-player 3:17 journey. The optional Supermarket of Small Heroes should make small imagined choices physically pleasant; real customers are safe and retain their agency.

**Playable improvement:** Each of the three large drawn market signs now accepts a direct mouse click or touch-to-mouse finger tap. Existing named keyboard/controller buttons remain available. Tapping follows the same reversible, locally saved activity, including changing your mind after completing the route. On the physical miniature board, all four uniquely named cart wheels roll according to actual forward/backward displacement, the three cardboard signs visibly tilt when selected, and a small flag stirs during the moving parade. Pause freezes the wheels; reduced motion settles the wheels and cart immediately. The original seven chapters, both endings, twelve Journey destinations, return choices and browser prototype are preserved.

**Exact verification:** 14 independent deterministic pointer-target/roll-wrap checks passed; extra native assertions were added to the existing Journey activity/world suites for direct presses, reversals, real wheel motion, pause and reduced motion. **Godot import, native suite execution, 1× audiovisual capture, physical touchscreen/controller and Windows/human playtesting were NOT performed** here because the full local checkout and Godot executable were unavailable. Next: `cd platform6/game && ./run_tests.sh`; click/tap signs in different orders, watch Jo's alternate route at 1×, test pause/reduced motion and reopen after a fresh launch. This is not a release sign-off.

## November 18, 2026 · tactile supermarket marker glides (source-integrated, native verification pending)

**Vision:** STILL HERE: PLATFORM 6 makes the ordinary rewarding to touch. The whimsical paper grocery cart should respond to each reversible marker like a physical toy rather than teleporting. Real shoppers are safe and retain their own agency; there are no real-world rescue tactics, time limits or compulsory tasks.

**Playable increment:** Turning a marker eases the physical cardboard cart from its actual currently shown position to the selected aisle over 0.42 seconds, even if a prior glide is interrupted. Lanterns react immediately. Pause freezes a half-completed movement; reduced-motion mode presents the settled still route and never replays a stale glide when switched back. Completion and Jo's slower demonstration still follow their original paths. All seven chapters, both endings, twelve Journey stops, saves and the old browser prototype remain unchanged.

**Exact verification:** Checked source anchors and the active branch baseline; independent deterministic motion calculations confirm no start jump, half-time smooth displacement, and exact endpoint settlement. Added native journey-world regression checks for successive markers, pause and reduced-motion toggles. **Godot import, native suite, 1× audiovisual footage, controller/Windows, and human playtesting remain unverified** because the engine and complete private checkout are unavailable here. Next: run the existing test runner in platform6/game, then watch rapid route reversals and Jo's demonstration at normal speed, including pause, reduced motion and revisit. Not a release sign-off.

## November 18, 2026 · supermarket paper-cart contact and route fidelity (source candidate)

**Vision:** The Supermarket of Small Heroes is playful make-believe that ends in ordinary care. Every paper sign should change where the little cart actually travels; finishing the arrangement should never jerk it across the table. Nothing asks players to perform a real rescue or rush.

**Changed:** All three reversible aisle markers now bend the animated cardboard cart smoothly toward their respective paper aisles, with the physical stop layout aligned to the routes. The third marker transitions from the existing partial arrangement into a continuous eased cart journey instead of restarting on the far left. Jo's optional demonstration follows all three lanes at the gentler original pace; the reduced-motion scene holds a center-lane still preview and retains each chosen marker lamp. Returning shopping-bag/basket choices, campaign endings, Journey saves and the Living Dead prototype remain unchanged. Native Godot world regression assertions now cover lane-specific geometry, zero-marker paths, the completion boundary, loop wrap, pause and reduced-motion route distinctions.

**Exact verification:** Six independent deterministic route-math checks passed (including three aisle centers, completion continuity, slower Jo continuation, smooth loop and still-mode distinction); source anchors and updated test expectations were checked. **Godot import, native tests, visual/audio capture, real controller/Windows and human playtesting were not run in this worker** because a complete Godot checkout and engine were unavailable. Next run `cd platform6/game && ./run_tests.sh`, then follow the market route through all marker orders and Jo's demonstration after both endings at 1×, including pause, reduced motion and fresh-process revisit. Not a release sign-off.

## November 18, 2026 · The Supermarket of Small Heroes (source-integrated; native playtesting pending)

**Vision:** STILL HERE: PLATFORM 6 is an original warm, single-player 3:17 journey where happiness lives in small things, not in mandatory tasks or a score. This optional whimsical grocery adventure is fictional make-believe, ending with an ordinary act of care. The actual customers are safe, have agency, and do not require rescue.

**Implemented in the Godot working branch:** A twelfth post-ending Journey stop featuring an independent shopkeeper's evening, Jo's imaginary paper-cart route across three large reversible aisle markers, an equally valid watch-Jo demonstration, a procedural walkable market, an animated cardboard cart, reduced-motion still presentation, and three authored story beats. Choices leave a spare paper bag, put a basket aside, or leave the place as found; the first two appear physically on a future visit. The existing separate Journey save schema is reused. Both endings, all seven original campaign chapters, the prior eleven Journey stops and the older browser prototype remain untouched. Catalog, activity, 3D-world, model and two-ending native regression assertions were extended.

**Exact verification:** Twelve destination records and the previous eleven authored records were checked structurally; authored game scripts/tests are source-integrated only. **Godot 4.6.3 compilation, native regressions, 1× visual/audio footage, real controller/Windows and independent human playtests were not run in this environment.** Next release-quality gate: run `cd platform6/game && ./run_tests.sh` in a complete Godot checkout, play the market after both endings, verify saved choice after fresh-process reopen, and inspect walking, paper route and reduced-motion modes. This is not a release claim.

## November 18, 2026 · optional hands-on soup stirring (source integrated)

**Touch follow-through:** The game's real on-screen Interact button is now visible and wired only during the optional Help stirring window; walk/look controls remain locked to the dinner close-up. The same gate owns E, controller A and touch. Added native finger-press/release assertions plus paused control availability. Source and timing checks passed; actual Godot execution is still unrun.


**Vision:** STILL HERE: PLATFORM 6 finds happiness in small things: gently helping Noor stir a pot should feel responsive and warm, not like a scored cooking challenge. The 3:17 journey, Mira's plans and all sit/watch choices stay intact.

**Implemented:** During the existing 4.5-second Night Kitchen **Help** gesture, up to three optional E/A/touch presses add distinct, short physical ladle circles, soup-surface turns and local soft stir sounds. A brief cooldown prevents holding the button from spamming. Automatic preparation continues with zero presses; soup is served identically, with no new save fields or rewards. Sit/watch do not ask for input. Pausing, skipping, finishing, and reduced motion settle safely. New actual-scene test `tests/kitchen_stir_input.gd` covers interaction, spoon/soup response, sounds, limits, pause and reduced motion.

**Verified this session:** GDScript source contracts, offline motion/timing calculations and exact GitHub tree/blob readback after the commit. **Not executed:** Godot 4.6.3 import/native regression, normal-speed visual/audio capture, controller/human testing. Next: run `cd platform6/game && ./run_tests.sh`, test E/A/touch during Help at 1×, and compare zero-press and three-press paths and fresh reopening. Do not call this a released build.

## November 18, 2026 · Night Kitchen original gesture foley (source integrated)

**Vision:** Small ordinary sounds should make stirring soup, scattering herbs, serving a bowl, tearing bread and passing cups feel intimate and rewarding, without a cooking score or mandatory task.

**Implemented:** Actual Kitchen gesture animation emits six authored one-shot cue types at motion thresholds. The existing audio director creates short original deterministic mono 16-bit sounds locally, caches them and honors Master/Effects mute. Optional help produces separate stirring, herb and serving cues; bread/cup/pepper get quieter contact cues. Pauses freeze gesture time; reduced-motion and forced completion avoid stacks of late sounds. Existing spoken captions, saved states and sit/watch choices remain intact. Kitchen sound and world tests now assert cue encoding, order, lifecycle and muting.

**Verified:** Source anchors and deterministic signal-envelope math inspected; exact private commit/blob readback is required. **Not executed:** Godot 4.6.3 import/native tests, 1x audible capture, physical controller and human evaluation. Next: run the native test suite, listen at normal speed to help/sit/watch, verify pause, reduced motion and zero Effects volume. This is not release signoff.

## November 18, 2026 · steady interaction focus between close discoveries (source integrated)

**Creative vision:** STILL HERE: PLATFORM 6 should make wandering, shared cooking and small kindnesses rewarding in themselves. When the player's cup, postcard and other nearby objects overlap, the interaction prompt and character glance should feel intentional rather than jitter with every tiny footstep.

**Implementation:** The actual player retains its nearest current live, in-range object until another comes at least 0.28 m closer. A decisive approach switches promptly; leaving the existing 3.2 m range, removing an object or queuing deletion clears stale focus. The same selected object feeds the E/A interaction, existing on-screen prompt and optional head/eye glance. Reduced-motion, camera, original movement speed, save schema and all eleven Journey destinations are unchanged. Added `tests/player_interaction_focus.gd` to the Godot test runner for close targets, interaction dispatch, switching, gaze and removal.

**Verified:** Source integration contracts and 9 deterministic proximity simulations, plus remote GitHub commit/blob readback. **Not executed:** Godot 4.6.3 import/test suite, normal-speed footage, physical controller or human evaluation—the engine and complete checkout are unavailable here. Next release-quality gate: `cd platform6/game && ./run_tests.sh`; then play the adjacent Night Kitchen/shelter prompts and E/A interactions at 1×, including reduced-motion settings. No release claim.

## November 17, 2026 · contextual walking discoveries (late Eastern, source-integrated)

**Vision:** A warm, single-player 3:17 story where wandering, little glances, cooking together and optional imaginary adventures lead naturally to small moments of care—not chores or a reward counter.

**Changed:** At close range, standing still by a real interactive object for 0.2 seconds lets the protagonist's existing animated eyes and head notice it. Moving, changing nearest object, opening dialogue/pause or switching to reduced motion immediately clears attention. The player's camera, walking physics and interaction trigger are untouched; seven chapters, existing eleven Journey stops, prior kitchen/shelter additions, local saves and the original browser prototype remain intact. Added an actual Godot rig/control regression `tests/player_nearby_attention.gd` to the native suite.

**Checks this session:** GitHub file/branch consistency, source integration anchors, offline timing and target-state simulations, and remote commit/blob readback. **Not yet run:** Godot 4.6.3 import and native test, 1x visual/audio footage, controller or independent human walking review, because the complete private checkout and Godot engine are unavailable in this worker. Next: `cd platform6/game && ./run_tests.sh`, then visually inspect closely spaced interactive targets, pause/reduced motion, and a fresh-process save route before calling this playtested. This is not a release.

## November 17, 2026 · shared soup preparation (source integration, Godot runtime pending)

**New playable choreography in the existing Night Kitchen:** Choosing to help rather than sit or watch now stirs the physical soup surface, brings a visible pinch of herbs down through the steam, and then carries the ladle to the player's waiting bowl. The three options remain equally valid, and helping does not create a score, new save field or a compulsory task. Added native scene assertions for stirring, ingredient visibility, serving and settled/reopened state. **Verification this run:** script anchor and math/path consistency checks, plus GitHub remote file and head readback; the actual Godot 4.6.3 suite, footage, controller and human review were **not run** because a native project checkout/engine is unavailable. Next: `cd platform6/game && ./run_tests.sh`, then watch all three dinner modes at 1x and verify pause/reopen. The 3:17 story, seven chapters and shelter quest remain intact. This is not a release.

## November 17, 2026 · tactile paper routes (source candidate)

**Changed:** Shelter Lantern Parade's three paper figures trace separate smooth forward-and-back loops through their individual turnable gates. A gate changes its figure's visible course, Jo demonstrates at a gentler tempo and the motion closes without the prior teleport at the edge. Reduced-motion holds an equivalent mid-route pose for each gate state. This is visual tabletop storytelling; live cats are not moved and progress is not scored.

**Checks:** offline numeric simulation of exact movement expressions passed 5/5 (movement, choice-specific route, wrap continuity, Jo tempo and still-route difference). Expanded `tests/journey_world.gd` with assertions for different gate tracks at the same instant, smooth loop wrap, a slower spectator cadence and retained reduced-motion gate information. Actual Godot 4.6.3 native tests, visual 1x capture, controller and independent human review were **not run here** (engine and checkout unavailable). Next: `./run_tests.sh`, fresh-process re-entry and visual/audio review. No changes to the seven-chapter campaign, existing ten Journey places, save schema or account/network behavior.

## November 17, 2026 · Shelter Lantern Parade: tabletop motion follow-through

**Changed now:** The optional post-ending shelter scene no longer merely flips the cardboard gates and displays a ribbon. Its three original paper-cat figures now visibly move through a tiny tabletop parade when you choose **Let paper cats parade** or **Watch Jo demonstrate**, with a distinct persisted scene response for Jo's version. Reversing a gate resets the arrangement so it can be replayed without a score or penalty. The living cats remain asleep and are never directed to march. Pause freezes the figures; reduced-motion mode uses the finished still arrangement. No old Journey state keys, campaign saves, provider resources or network calls changed.

**Checks included in the existing native suites:** Journey activity now asserts both saved demonstration and arranged paths and reversal. Journey world now checks actual paper-figure position changes, pause freeze, reduced-motion still pose, Jo's visible acknowledgement and gate-reset behavior. Text-level integration anchors and branch readback were checked during source delivery. **Not executed in this environment:** Godot 4.6.3 import, the native test suite, hardware controls, recorded 1x gameplay or human feel/readability evaluation. Next run `cd platform6/game && ./run_tests.sh` in the engine and inspect the shelf from both story endings through a fresh-process reopen. Do not call this a production release.

**North star:** Wonder in small ordinary things: characterful walking and glances, care at the animal shelter, original imagination-side stories that resolve into tangible kindness, detailed shared cooking and agency for friends and romantic interests. Supermarket, college and new cooking sequences are still future work.

## November 17, 2026 · optional Shelter Lantern Parade (active Godot branch)

After either completed Chapter Seven ending, Journey offers an eleventh destination. The player can wander through Jo's fictional cat shelter, adjust three paper-cardboard parade gates (all reversible) or watch Jo lead a demonstration, and then leave fresh water, fold a soft resting nook or leave the shelter unchanged. Physical generated cat beds, an awning, signs, a tabletop paper procession, gently moving resting cats and persistent return props make this a bounded scene rather than text-only content. Real cats are never forced to participate, and no real-life animal rescue task is assigned. Previous ten authored destinations, original story, saves and old browser prototype are preserved.

**Creative target:** find happiness in ordinary moments and connections through expressive walking and environmental animation, detailed shared cooking and imaginative—but always gentle—optional adventures. The supermarket, college and cooking additions have **not** been built here.

**Verification for this integration:** Compared the original ten authored destinations byte-equivalent after JSON parsing; eleventh catalog entry has Jo metadata, three valid state choices and an authored activity and physical scene. Repaired the Journey's synthetic-NPC test count for the added fixture and the runtime test's ten-button assumption; added a real-world-scene revisit assertion for the saved water-bowl choice. Existing `run_tests.sh` includes all affected Journey model/world/activity/runtime suites. **Not verified:** Godot 4.6.3 import, runtime suite, real controller, 1x visual/audio capture or human playtesting—Godot and the complete checkout aren't available here. Next run `cd platform6/game && ./run_tests.sh` with Godot 4.6.3 and inspect the quest through both endings, spectator route, three choices and a fresh-process reopen. This is not a release.

## Current illustrated graphics · 2026-10-10

All seven campaign chapters and all ten Journey destinations now share matte
cel shading, selective cool outlines and a restrained static paper finish.
Location dressing includes original blossom planters, winter branches, coastal
grass, hills, floorboards, paving, curtains and physical destination signs.
The existing painted panoramas, original character rigs, story, save format,
touch controls and reduced-motion options are retained. This is a Sakura
Crossing-inspired visual milestone, with original Godot art and code; character
art and destination environments still need final production refinement.
See [scope, fresh checks and renderer evidence](../docs/ILLUSTRATED_GRAPHICS_2026-10-10.md).
The playable checkpoint requires Godot 4.6.3 Standard. Earlier package and test
claims below describe historical milestones.

---

## Opening polish · 2026-10-10

Touch movement, independent camera drag, dialogue selection and prose scrolling now accompany desktop controls. The window latch lifts before sliding; the postcard lifts and turns to reveal its kettle hint. Pause, dismissal, reload and reduced motion preserve settled states. Successful new-journey reset clears stale failed-save warnings. All seven chapters and ten Journey destinations remain intact. See [fresh tests and evidence](../docs/OPENING_POLISH_2026-10-10.md). The current playable PCK requires Godot 4.6.3 Standard; no new self-contained executable is supplied. Earlier package claims below are historical.

---

## Current opening refresh · 2026-10-05

The existing apartment → umbrella → station → carriage → shore → return opening now has physical story props, durable remembered replies, clear next-step objectives, an actual reversible shore-camera puzzle, readable speaker framing and layered roof/coast scenery. Five original stereo arrangements share a restrained motif with softer ambience. See ../docs/OPENING_REFRESH_2026-10-05.md and BUILD_INFO.json in the archive root for this delivery’s actual verification and limits. Previous milestone reports below describe their historical passes.

# STILL HERE: PLATFORM 6

An offline, original-geometry Godot desktop seven-chapter build. Warm magical realism: apartment at 3:17, yellow-umbrella stranger, Platform 6, a passenger with an unopened camera, a moonlit overlook and breakfast at night.

## Run
1. Install Godot 4.6.3 from the official Godot site: https://godotengine.org/download/
2. Import this folder's project.godot in Godot's Project Manager
3. Open the project and press F5 / Run Project

From a terminal with Godot on PATH: godot --path /path/to/game

This source archive is the editable project. The accompanying Linux opening-refresh executable contains the current game. Earlier milestone packages are historical. Native cloud Compatibility-renderer checks are recorded separately; Windows/Web runtimes, macOS export and physical controller hardware remain unverified.

## Controls
- WASD or arrows / controller left stick: move
- Mouse / right stick: orbit camera
- E / A: interact with the single nearest labelled target
- Enter / A: confirm a focused choice; arrows / D-pad: move menu focus
- R / right-stick click: reset camera
- Esc / B: back or resume; Esc opens pause while exploring
- P / controller Menu: pause, including inside dialogue/arrival; resume restores the previous choice focus
- Scroll wheel / PageUp and PageDown / right stick in menus: read long text at large text scale

Pause offers text scale, sensitivity, ambient subtitles, reduced motion, separate master/music/effects and three graphics tiers. Low tier lowers render scale and disables antialiasing; high enables shadows. At maximum text scale, long prose scrolls while choices remain visible.

## Journey
The overlook has three inspection points: lighthouse, arch, constellation. Inspect in any order, then use the viewing marker to try actual camera viewpoints. Step back to include the three shapes and choose Keep this framing. View changes are reversible and saved; Back returns to walking. Assist is immediately available and yields the same content. Each camera choice is valid. Done and Not tonight produce identical permanent chapter outcomes and souvenirs.

Local saves: user://still_here/save_v1.json, with schema 2 inside the retained compatible filename. Version 1 saves migrate locally with neutral new defaults and a retained .v1.bak source on first write. Save writes retain verified backups; damaged sources are retained; future schema files are never overwritten. Start a new journey preserves a separate recoverable reset backup. Recovery is local; no account or cloud sync.

## Test
./run_tests.sh runs clean import, model/save/data, world and runtime integration checks. Automated tests use synthetic controller events and Godot physics; they do not establish physical-controller acceptance. See QA_REPORT.md for actual checks and limits.

## Assets and privacy
Original editable Godot/Blender/SVG geometry and art, five original synthesized stereo arrangements and noise-based ambience. See ASSET_LICENSES.md and GODOT_LICENSE.txt. No internet requests, permissions, analytics, accounts, microphone/camera access, runtime AI or external services. The disposable camera is fictional.

This includes Chapters One–Seven, not the full 15–25-hour game. It makes no promised play-duration, mobile or release-readiness claim.

## Standalone export
See `EXPORTING.md` for included presets, built package names, requirements,
controls and exact verification limitations. Chapters One–Seven are implemented; Journey Mode V1 is playable after either completed campaign ending; see ../docs/JOURNEY_V1.md.

## Enriched opening
Mira repairs wind-up boats and has a place to go beyond this journey. Ask about her work, choose quieter company, inspect the window's paper boat, discover three shoreline shapes together, and turn over the breakfast postcard for the next-stop hint. These local exchanges do not add ranks or change chapter completion. Escape returns to exploration; the same person can be spoken to again.

Rain against the apartment window, roof rain, train rails and shore surf have distinct original synthesized beds with crossfades and matching optional ambient captions. Reduced motion preserves the chosen camera orbit, freezes decorative sway/water movement and hides moving rain/steam. Pause → Controls explains keyboard and controller inputs. Movement remains responsive.

Sakura Crossing's MIT source informed damping and small asynchronous environmental motion, credited in ASSET_LICENSES.md. Its Three.js environment has no humanoid rig; this remains an original Godot implementation rather than a port. No third-party music is included.

## Chapter Two · The Unfinished Fair
After Chapter One’s existing souvenir/ending, choose Continue to the Unfinished Fair, or Save and leave. A saved completed Chapter One can reopen this handoff at Keep this journey.

Explore Ada’s courtyard, read opening hours, inspect the prize shelf and painted bird. At the boat rail, set left/straight/right rudder, triangle/square/folded sail and operate/watch/cooperate. One winding press starts the race. The first run drifts toward a wooden duck. Inspect the boat or pond, check with Mira or watch Ada notice the waterline, then shift the packing wedge or let Ada do it. A second race follows the chosen configuration. First/second/third/circular/spectator outcomes all keep the same fair button and story continuation.

Your configured boat is number 1. Folded sail on the operate route circles; left rudder on another sail finishes third; right or square finishes second; straight triangle finishes first. Cooperate is a shared second-place route; watch is an authored audience route. These are deterministic fictional routes, with no score/unlock advantage. Reduced motion provides instant functional paths/results. Replay keeps the canonical past outcome and cannot farm consequences.

Camera take/lend/unopened continuity remains explicit. New authored choice traces and bounded fictional emotion weights remain local and hidden; they are not a diagnosis or a profile of the real player. Mira chooses Lower Mill independently on every departure route. The optional real-world Done/Not tonight response is never revealed to NPCs and remains identical in rewards, relationship/story consequences and future access.

The fair completion panel offers an explicit, optional conservatory continuation. The Chapter Three completion panel offers an explicit Night Kitchen continuation. Chapter Four offers an explicit Quiet Orchard continuation. Chapter Five offers an explicit Return Platform continuation. Chapter Six offers an explicit return home. Chapter Seven closes the authored campaign with two equally valid endings; the bounded Journey Mode V1 continuation is available after either ending. Character art remains intermediate, including the preserved original protagonist/Mira rigs and stylized Ada.


## Chapter Three · A Sky That Fits Through the Door
Meet Noor and Rafi in the warm paper workshop. Choose assemble, direct Noor, or watch; the spectator route can keep a named shape or leave the preview to Mira and Noor. Walk to the star tray, attachment rail, string board and Mira’s drying rack to change the real sign preview.

Use Rafi’s crooked star, Noor’s clean-cut star, or an empty space; choose any of six left/center/right orders and three string lengths. Keep/widen Mira’s fold or leave her spare on the rack; the base timetable boat remains on every sign. The bent shore propeller and BOATS WITH OPINIONS nameplate never disappear.

Raise the rail to test the measured doorway, then carry the sign to the original fair courtyard. The exact physical object is rebuilt from saved choices on revisit. Optional fixed close views show the sign and its silhouette. Esc/B leaves the view; P/Menu can pause it. No device access, uploads, timers, artistic rating or balance failure.

Save schema remains 2 with neutral optional Chapter Three defaults for existing journeys. Choices stay reversible before raising, then the object is canonical. Art remains intermediate. See ../docs/PAPER_MILESTONE.md for current tests, export verification and limits.


## Chapter Four · A Place Before a Task
Continue from the completed sign into the Night Kitchen. Your bowl, spoon, blue cup, cloth and drawn-back chair are already there. Sit immediately, take the ladle, or watch Noor and Ada serve. All three routes receive supper and finish equally.

Walk around the table to pass bread, a cup or pepper, or stay while the food passes. Soup steam, ladle pouring, tearing hands and crust, bowls/cups, passing food, chair movement and window condensation provide layered physical staging while people talk. Mira discusses the early tram to her independently chosen Lower Mill workshop. Your exact paper sign, fictional camera choice and fair button remain visible.

The table and sign have optional stable close views. Esc/B returns immediately, settling any gesture; P/Menu freezes the room and restores the same view or dialogue. Reduced motion freezes decorative movement and completes functional gestures instantly. Choices and completion save before animation, so reopening never requires replaying a gesture. Failed saves keep a visible warning and Save and leave stays open for retry.

Schema remains 2 with neutral optional kitchen state on older saves. Every dinner route leaves prior rewards, hidden fictional dimensions and NPC decisions unchanged. Chapter One's real-world Done and Not tonight response remains private from NPCs and equally consequential. See ../docs/KITCHEN_MILESTONE.md for verification and remaining limits.


## Chapter Five · The Quiet Orchard
Continue from supper into a blue-evening orchard. Ride the physical handcart, walk, or stay at the station bench; every route completes equally. Let a pear fall, crate-carrying workers cross a distant doorway, and train light pass across tree trunks, advancing each moment yourself. There is no timer or wait requirement. Optional stable views can be left immediately with Esc/B; P/Menu pauses, including during the ride. Reduced motion settles physical presentations instantly.

Route and each moment are saved before presentation. Reopening restores the exact chosen route and beat. Existing schema-2 saves gain neutral orchard defaults; no time away erases progress. Failed orchard saves retain a visible warning and block Save and leave, pause Quit and OS close until retry succeeds. See ../docs/ORCHARD_MILESTONE.md for scope and the final QA report for exact verification.


## Chapter Six · The Return Platform

Return to Central Station after the Quiet Orchard. Mira leaves for her independently chosen Lower Mill workshop. Wish her luck, make a joke, thank her, wave or say little. Five equally valid responses have distinct remembered callbacks and restrained live acting. A music-free physical cinematic stages her tools, strap, train approach, gust, sliding doors, boarding, turn and departure. If she carries the borrowed camera, she nearly drops it, catches it and laughs. The empty platform holds its ordinary ambience before exploration returns.

Esc/B skips preparation or departure; P/Menu pauses both; reduced motion settles them immediately. The five farewell choices remain visible at 2× text. Accepted responses and departure save before presentation; reload restores the exact branch and a settled platform. The optional conductor and Jo conversations remain available after completion. No farewell can keep Mira from leaving. Continue home explicitly to Chapter Seven after the settled departure.

See ../docs/RETURN_MILESTONE.md and ../docs/RETURN_QA_REPORT.md for detailed scope, current native keyboard/run evidence and limits. The standalone is a bounded production milestone with intermediate original character art.


## Chapter Seven · STILL HERE

Return to the same apartment. Its mug, chair, crossword, kettle, window and shoes keep the original geometry and positions. Place the ticket by the kettle, in the drawer or in the pocket; make tea, sit by the window or do neither. TAKE THE TRAIN and GO BACK TO SLEEP both complete the campaign equally and remember distinct choices. Both lives continue.

Quiet nighttime staging and credits can be skipped or paused, with reduced motion and durable save/reopen behavior. JourneyPack and the bounded Journey Mode V1 continuation are now playable after either ending. See ../docs/HOME_MILESTONE.md and ../docs/HOME_QA_REPORT.md for verified scope and remaining limits.

## Character polish checkpoint
Protagonist and Mira now have smoother original faces/hair, readable brows/eyes, coherent Mira coat surfaces and varied restrained micro-acting. The source retains the original editable Blender files and compatible 25-bone rigs. Matched native before/after captures demonstrate this bounded improvement; character art remains intermediate. Tests now include the original full campaign runner, exported mesh contracts and natural-motion regressions. See ../docs/CHARACTER_POLISH_MILESTONE.md for exact evidence and remaining limits

## Journey Mode V1

After credits choose PLATFORM 6 CONTINUES. Ten authored small destinations, changed returns, five interactive activity types, a train hub and optional private Tiny Tomorrows/Future Echoes are implemented. Journey uses a separate local save and preserves the complete campaign. This is a tested review milestone, not an infinite-content or release-readiness claim. See ../docs/JOURNEY_V1.md and ../docs/JOURNEY_QA.md.

## Shared apartment art checkpoint
The opening and returning apartment now share original painterly wood/plaster/textile surfaces, floorboards, framed rainy city-window, curtains, reading lamp, shelf, layered bedding and gently softened furniture. Existing floorplan, ordinary prop positions, collision, story targets and persistence remain unchanged. New art is static; existing rain retains reduced-motion support. Editable SVG and Blender source are included. This is a bounded presentation improvement, not a final environment-art or target-device performance acceptance claim. See ../docs/APARTMENT_ART_MILESTONE.md for exact verification and remaining limits.

Medium apartment rendering uses full resolution with vertex lighting and no MSAA; High keeps 2× MSAA. Apartment fill lights stay shadowless for a bounded draw budget. Other locations retain their prior graphics-tier policy. The source checkpoint does not contain a newly exported standalone.

## Implemented opening story beats

Chapter One now shows a short next-step objective and actual landmark-discovery progress. The blank ticket is on a physical bench beside its interaction, then is carried away. The carriage has a liftable window latch and sliding pane; Mira’s tool roll clears the spare seat when you choose quieter company. Camera choices show the unopened box or opened camera, and the breakfast table contains two cups and saucers, the folded timetable, toast and plum jam. Turning over the fair postcard also turns over its physical object.

Local authored dialogue selections are remembered once in the existing local save. Repeating an exchange cannot accumulate consequences. The selected umbrella exchange reaches Jo’s existing later callback. Old saves remain valid and gain no invented past replies. Taking a ticket, accepting company, choosing the camera and sharing breakfast keep your position within the same location. The shore viewing marker shows the actual landscape beside its choices, with a reversible camera preview and explicit Keep; Assist remains available immediately.

Opening dialogue sits along the lower edge of the screen, with scrollable prose and reachable choices at 2× text. Pause restores the same side/lower panel, camera and choice focus. Reduced motion preserves your own exploration camera orbit. The optional real-world invitation, all canonical souvenirs, Mira’s independent plans and later chapters are preserved.
