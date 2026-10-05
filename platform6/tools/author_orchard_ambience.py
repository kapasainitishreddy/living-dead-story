"""Deterministic original orchard leaves, far station hum and distant wood.

Standard-library mathematical synthesis only; no recorded or external samples.
A periodic low-pass noise bed and soft envelopes make a seamless 16-second loop.
"""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
DURATION = 16
COUNT = RATE * DURATION
rng = random.Random(640616)
# Warm rustle: two-pole filtered noise. Pre-roll settles the filter, and a
# periodic crossfade removes the join without a repeating silent gap.
noise = []
a = b = 0.0
for n in range(COUNT + RATE):
    a += 0.065 * (rng.uniform(-1, 1) - a)
    b += 0.065 * (a - b)
    if n >= RATE:
        noise.append(b)
join = RATE
for n in range(join):
    blend = 0.5 - 0.5 * math.cos(math.pi * n / (join - 1))
    noise[n] = noise[COUNT - join + n] * (1 - blend) + noise[n] * blend
# The crossfaded prefix replaces the tail; final length remains >=8 seconds.
noise = noise[:-join]
count = len(noise)
duration = count / RATE
samples = []
for n in range(count):
    t = n / RATE
    breeze = 0.55 + 0.25 * math.sin(math.tau * 2 * t / duration) + 0.15 * math.sin(math.tau * 3 * t / duration + 0.7)
    hum = 0.007 * math.sin(math.tau * 60 * t) + 0.003 * math.sin(math.tau * 120 * t)
    samples.append(0.12 * breeze * noise[n] + hum)
# Two distant, broadly rounded wooden resonances, deliberately sparse.
for when, pitch in [(4.35, 144), (11.15, 168)]:
    start = int(when * RATE)
    length = int(0.85 * RATE)
    for j in range(length):
        t = j / RATE
        env = math.sin(math.pi * j / length) ** 2 * math.exp(-3 * t)
        samples[start + j] += 0.013 * env * (math.sin(math.tau * pitch * t) + 0.25 * math.sin(math.tau * pitch * 2 * t))
out = Path(__file__).resolve().parents[1] / 'game/assets/original/orchard_hush.wav'
with wave.open(str(out), 'wb') as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(RATE)
    wav.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, s)) * 32767)) for s in samples))
print(out)
