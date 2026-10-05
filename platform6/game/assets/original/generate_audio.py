"""Original STILL HERE music and ambience, generated locally from synthesis.

No samples, soundfonts, network calls, or generative-service output. The shared
48-second harmonic clock lets the audio director crossfade arrangements without
restarting a melody halfway through a sentence. Requires local numpy/scipy.
"""
from pathlib import Path
import json
import math
import wave
import numpy as np
from scipy.signal import butter, sosfilt

RATE = 44100
SECONDS = 48.0
FRAMES = int(RATE * SECONDS)
OUT = Path(__file__).resolve().parent
# Four unhurried four-bar phrases, 80 bpm, D(add9) / Gmaj7 / Bm7 / A(sus)-D.
CHORDS = [(50, 57, 61, 64), (55, 62, 66, 69), (47, 54, 57, 62), (45, 52, 57, 62)]
# The little everyday refrain is original. Its rests are part of the composition.
MELODY = [
    (1.50, 69, .83), (3.00, 66, .72), (4.50, 64, .78), (6.75, 62, 1.00),
    (13.50, 64, .72), (15.00, 66, .80), (17.25, 69, 1.10),
    (25.50, 71, .84), (27.00, 69, .78), (29.25, 66, .92),
    (37.50, 64, .75), (39.00, 62, 1.10), (42.00, 62, .60),
]


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def smoothstep(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def voice(midi, duration, kind='felt', velocity=1.0):
    """A soft struck string, rounded pluck, breath flute or short bowed phrase."""
    n = int(RATE * duration)
    t = np.arange(n, dtype=np.float64) / RATE
    f = hz(midi)
    y = np.zeros(n, dtype=np.float64)
    if kind in ('felt', 'pluck'):
        attack = .026 if kind == 'felt' else .018
        weights = [1.0, .34, .16, .068, .024, .009] if kind == 'felt' else [1.0, .44, .19, .10, .04, .017]
        for partial, weight in enumerate(weights, 1):
            # Upper strings lose energy faster, with tiny physical inharmonicity.
            partial_hz = f * partial * math.sqrt(1.0 + .000035 * partial * partial)
            decay = (2.9 if kind == 'felt' else 1.65) / (1.0 + .38 * (partial - 1))
            envelope = (.70 * np.exp(-t / decay) + .30 * np.exp(-t / .27))
            y += weight * np.sin(2 * np.pi * partial_hz * t) * envelope
        y *= smoothstep(t / attack)
    elif kind == 'flute':
        # Delayed gentle vibrato, breath and harmonics, never a bare sine drone.
        vibrato = .003 * smoothstep((t - .35) / .5) * np.sin(2 * np.pi * 4.6 * t)
        phase = 2 * np.pi * f * np.cumsum(1.0 + vibrato) / RATE
        y = np.sin(phase) + .16 * np.sin(phase * 2) + .045 * np.sin(phase * 3)
        y *= smoothstep(t / .18) * smoothstep((duration - t) / .48)
        y *= .82 + .18 * np.sin(np.pi * t / duration)
    elif kind == 'bow':
        phase = 2 * np.pi * f * t + .008 * np.sin(2 * np.pi * 4.2 * t)
        for partial, weight in enumerate([1, .22, .10, .047, .019], 1):
            y += weight * np.sin(partial * phase)
        y *= smoothstep(t / .72) * smoothstep((duration - t) / .90)
    y *= smoothstep((duration - t) / .20)
    return y * velocity


def add_note(mix, at, midi, level, pan=0.0, kind='felt', duration=5.5):
    note = voice(midi, duration, kind, level)
    start = int(at * RATE)
    left = math.cos((pan + 1.0) * math.pi / 4.0)
    right = math.sin((pan + 1.0) * math.pi / 4.0)
    length = min(len(note), len(mix) - start)
    if length > 0:
        mix[start:start + length, 0] += note[:length] * left
        mix[start:start + length, 1] += note[:length] * right


def room(mix, amount=.16, spacious=False):
    dry = mix.copy()
    # Uneven stereo early reflections instead of a long all-purpose fog of reverb.
    taps = [(0.047, .62), (.083, .36), (.139, .23), (.227, .14)]
    if spacious:
        taps += [(.373, .12), (.563, .08)]
    for i, (delay, gain) in enumerate(taps):
        offset = int(delay * RATE)
        source = dry[:, ::-1] if i % 2 == 0 else dry
        mix[offset:] += source[:-offset] * amount * gain
    return mix


def arrange(scene):
    mix = np.zeros((FRAMES, 2), dtype=np.float64)
    # The same tune is voiced differently, rather than pitched down at the sea.
    melody_gain = {'apartment': .062, 'umbrella': .069, 'train': .075, 'shore': .062, 'return': .067}[scene]
    for index, (at, note, accent) in enumerate(MELODY):
        if scene == 'apartment' and index in (4, 6, 9):
            continue
        kind = 'flute' if scene == 'shore' and index in (0, 1, 2, 3, 7, 8, 9) else 'felt'
        duration = 1.80 if kind == 'flute' else 5.0
        add_note(mix, at, note, melody_gain * accent, .12 + .04 * (index % 2), kind, duration)
    for phrase, chord in enumerate(CHORDS):
        base = phrase * 12.0
        root, fifth, third, ninth = chord
        add_note(mix, base + .12, root, .026 if scene == 'apartment' else .035, -.27, duration=5.0)
        # Two small broken-chord gestures followed by several seconds of room.
        offsets = [(.78, fifth), (1.55, third), (3.10, ninth), (6.10, fifth), (7.58, third)]
        if scene == 'apartment':
            offsets = [(.78, fifth), (3.10, ninth), (7.58, third)]
        for i, (offset, note) in enumerate(offsets):
            kind = 'pluck' if scene in ('umbrella', 'train') else 'felt'
            add_note(mix, base + offset, note, .017 + .002 * (i % 2), -.40 + .1 * (i % 3), kind, 4.0)
        if scene == 'train':
            # Warm little answering figure; no metronomic bell/percussion layer.
            add_note(mix, base + 9.15, third + 12, .020, .38, 'pluck', 2.2)
        if scene == 'shore':
            # A short open voicing only on alternate phrases. Silence matters.
            if phrase in (0, 2):
                add_note(mix, base + 5.50, fifth, .010, -.50, 'bow', 3.8)
                add_note(mix, base + 5.64, ninth, .008, .50, 'bow', 3.7)
        if scene == 'return':
            add_note(mix, base + 6.10, root + 12, .021, -.18, duration=3.8)
    if scene == 'return':
        # A modest home cadence, then enough space to hear a cup and the rain.
        add_note(mix, 43.52, 66, .022, -.28, duration=3.6)
        add_note(mix, 43.58, 69, .020, .28, duration=3.5)
    return room(mix, .15 if scene != 'shore' else .24, scene == 'shore') * 1.8


def filtered_noise(rng, seconds, low, high):
    n = int(RATE * seconds)
    # Warm-up removes a filter transient without inventing a slow fade each loop.
    raw = rng.normal(size=(n + RATE, 2))
    filt = butter(2, [low, high], btype='bandpass', fs=RATE, output='sos')
    y = sosfilt(filt, raw, axis=0)[RATE:]
    return y / np.sqrt(np.mean(y * y))


def add_soft_contact(mix, at, duration, level, rng, cutoff=1800):
    n = int(duration * RATE)
    noise = rng.normal(size=(n, 2))
    filt = butter(2, cutoff, fs=RATE, output='sos')
    noise = sosfilt(filt, noise, axis=0)
    t = np.arange(n) / RATE
    envelope = smoothstep(t / .012) * np.exp(-t / max(.02, duration * .20)) * smoothstep((duration - t) / .04)
    start = int(at * RATE)
    mix[start:start + n] += noise[:len(mix) - start] * envelope[:len(mix) - start, None] * level


def ambience(name):
    rng = np.random.default_rng({'rain_window':617, 'rain_roof':618, 'rails':619, 'surf':620, 'kitchen_simmer':621, 'orchard_hush':622, 'fair_clockwork':623}[name])
    seconds = 24.0
    t = np.arange(int(RATE * seconds)) / RATE
    if name == 'rain_window':
        mix = filtered_noise(rng, seconds, 260, 2600) * .020
        mix *= (1.0 + .13 * np.sin(2 * np.pi * t / 12))[:, None]
        for at in [1.83, 4.71, 9.36, 13.62, 19.37, 21.14]:
            add_soft_contact(mix, at, .14, .039, rng, 1900)
    elif name == 'rain_roof':
        mix = filtered_noise(rng, seconds, 220, 4200) * .025
        mix *= (.90 + .15 * np.sin(2 * np.pi * t / 8.0))[:, None]
        for at in [1.14, 2.67, 5.19, 8.62, 10.14, 13.83, 16.22, 19.73, 22.54]:
            add_soft_contact(mix, at, .13, .045, rng, 2300)
    elif name == 'rails':
        # Wind, wheel texture and irregular muted joints. No oscillator at all.
        mix = filtered_noise(rng, seconds, 90, 1700) * .020
        mix += filtered_noise(rng, seconds, 500, 3400) * .009
        mix *= (.88 + .10 * np.sin(2 * np.pi * t / 12.0))[:, None]
        for i in range(19):
            at = .41 + i * 1.19 + float(rng.uniform(-.09, .09))
            add_soft_contact(mix, at, .18, .028, rng, 1100)
    elif name == 'kitchen_simmer':
        mix = filtered_noise(rng, seconds, 250, 1600) * .008
        mix += filtered_noise(rng, seconds, 700, 2800) * .004
        for at in [1.24, 2.71, 4.26, 6.92, 8.15, 10.52, 13.25, 15.43, 18.20, 20.78, 22.23]:
            add_soft_contact(mix, at, .22, .029, rng, 900)
        # Two softly set-down cups, not a repeated bell phrase.
        for at in [4.60, 17.15]:
            n = int(.38 * RATE)
            u = np.arange(n) / RATE
            cup = (np.sin(2*np.pi*1260*u) + .26*np.sin(2*np.pi*2087*u))
            cup *= smoothstep(u/.018) * np.exp(-u/.075) * smoothstep((.38-u)/.06) * .024
            start = int(at*RATE)
            mix[start:start+n, 0] += cup * .65
            mix[start:start+n, 1] += cup * .35
        rain = filtered_noise(rng, seconds, 600, 3400) * .008
        mix += rain
    elif name == 'orchard_hush':
        breeze = .68 + .21*np.sin(2*np.pi*t/12.0) + .08*np.sin(2*np.pi*t/8.0 + .7)
        mix = filtered_noise(rng, seconds, 500, 2900) * (.020*breeze)[:, None]
        mix += filtered_noise(rng, seconds, 120, 750) * .005
        for at in [4.35, 15.15]:
            add_soft_contact(mix, at, .48, .034, rng, 450)
    elif name == 'fair_clockwork':
        mix = filtered_noise(rng, seconds, 200, 1800) * .009
        for at in [1.27, 4.71, 6.83, 10.59, 14.33, 18.19, 21.74]:
            add_soft_contact(mix, at, .18, .024, rng, 1800)
    else:
        # Nonidentical waves roll in slowly; soft high foam, restrained bass.
        mix = filtered_noise(rng, seconds, 160, 3300)
        swell = .35 + .65 * (.5 - .5 * np.cos(2 * np.pi * t / 8.0))
        mix *= (.035 * swell)[:, None]
        foam = filtered_noise(rng, seconds, 1200, 5300)
        mix += foam * (.009 * swell ** 2)[:, None]
    return mix


def finalize(samples):
    samples -= samples.mean(axis=0)
    # A 12 ms endpoint ramp is inaudible against ambience and guarantees no click.
    ramp = smoothstep(np.arange(int(RATE * .012)) / (RATE * .012))
    samples[:len(ramp)] *= ramp[:, None]
    samples[-len(ramp):] *= ramp[::-1, None]
    peak = float(np.max(abs(samples)))
    if peak > .30:
        samples *= .30 / peak
    return np.round(samples * 32767).astype('<i2')


def write(name, samples):
    pcm = finalize(samples)
    with wave.open(str(OUT / (name + '.wav')), 'wb') as stream:
        stream.setnchannels(2)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    x = pcm.astype(np.float64) / 32768
    return {'duration_seconds':len(x)/RATE, 'channels':2, 'sample_rate':RATE,
            'peak_dbfs':round(20 * np.log10(np.max(abs(x))),3),
            'rms_dbfs':round(20 * np.log10(np.sqrt(np.mean(x*x))),3),
            'loop_step':float(np.max(abs(x[-1]-x[0])))}


def main():
    manifest = {'title':'A Little Way Home', 'original':True, 'method':'local deterministic additive and filtered-noise synthesis; no samples',
                'key':'D major', 'tempo_bpm':80, 'loop_seconds':SECONDS,
                'motif_midi':[[at,note,accent] for at,note,accent in MELODY], 'assets':{}}
    for name, scene in [('music_apartment','apartment'), ('music_umbrella','umbrella'),
                        ('night_train','train'), ('music_shore','shore'), ('music_return','return')]:
        manifest['assets'][name] = write(name, arrange(scene))
    for name in ['rain_window','rain_roof','rails','surf','kitchen_simmer','orchard_hush','fair_clockwork']:
        manifest['assets'][name] = write(name, ambience(name))
    (OUT/'soundtrack_manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
