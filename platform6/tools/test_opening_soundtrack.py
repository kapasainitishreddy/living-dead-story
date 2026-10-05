"""Asset-level regressions for the authored original opening score.

A flattened mono synth, a discontinuous loop or a permanently tonal rail bed
must fail this suite. These signal checks are not a claim of listening quality.
"""
from pathlib import Path
import unittest
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'game/assets/original'
SCORES = ['music_apartment', 'music_umbrella', 'night_train', 'music_shore', 'music_return']
BEDS = ['rain_window', 'rain_roof', 'rails', 'surf', 'kitchen_simmer', 'orchard_hush', 'fair_clockwork']


def read_audio(name):
    with wave.open(str(ROOT / (name + '.wav'))) as stream:
        rate, channels = stream.getframerate(), stream.getnchannels()
        samples = np.frombuffer(stream.readframes(stream.getnframes()), '<i2').astype(np.float64) / 32768
    return rate, channels, samples.reshape(-1, channels)


class OpeningSoundtrackTests(unittest.TestCase):
    def test_each_scene_has_an_original_stereo_arrangement(self):
        for name in SCORES:
            with self.subTest(name=name):
                self.assertTrue((ROOT / (name + '.wav')).exists(), f'{name} needs its own arrangement')
                if not (ROOT / (name + '.wav')).exists():
                    continue
                rate, channels, samples = read_audio(name)
                self.assertEqual(rate, 44100)
                self.assertEqual(channels, 2)
                self.assertAlmostEqual(len(samples) / rate, 48.0)
                if channels == 2:
                    width = np.sqrt(np.mean((samples[:, 0] - samples[:, 1]) ** 2))
                    self.assertGreater(width, 0.002, 'the arrangement must have real stereo space')

    def test_new_assets_have_headroom_and_click_free_loop_boundaries(self):
        for name in SCORES + BEDS:
            with self.subTest(name=name):
                self.assertTrue((ROOT / (name + '.wav')).exists())
                if not (ROOT / (name + '.wav')).exists():
                    continue
                _, _, samples = read_audio(name)
                self.assertLess(np.max(abs(samples)), 0.4, 'leave at least 8 dB of summing headroom')
                self.assertLess(abs(np.mean(samples)), 0.0001, 'remove DC offset')
                self.assertLess(np.max(abs(samples[-1] - samples[0])), 0.001, 'loop wrap must not click')
                self.assertGreater(np.sqrt(np.mean(samples ** 2)), 0.006, 'asset must not be empty')

    def test_every_environment_is_stereo_without_a_continuous_tonal_drone(self):
        for name in BEDS:
            with self.subTest(name=name):
                rate, channels, samples = read_audio(name)
                self.assertEqual(rate, 44100)
                self.assertEqual(channels, 2)
                energy = abs(np.fft.rfft(samples.mean(axis=1))) ** 2
                self.assertLess(np.sort(energy)[-4:].sum() / energy.sum(), 0.035,
                                'an environmental bed must not hide a continuous synth drone')

    def test_score_phrases_leave_audible_space(self):
        for name in SCORES:
            with self.subTest(name=name):
                self.assertTrue((ROOT / (name + '.wav')).exists())
                if not (ROOT / (name + '.wav')).exists():
                    continue
                rate, _, samples = read_audio(name)
                windows = samples[:len(samples)//(rate*2)*(rate*2)].reshape(-1, rate*2, samples.shape[1])
                envelope = np.sqrt(np.mean(windows ** 2, axis=(1, 2)))
                self.assertLess(np.min(envelope), np.max(envelope) * 0.50,
                                'no incessant constant-volume drone or metronomic wash')

    def test_rails_are_a_broadband_environment_without_the_old_bass_drone(self):
        rate, _, samples = read_audio('rails')
        mono = np.mean(samples, axis=1)
        energy = abs(np.fft.rfft(mono)) ** 2
        frequencies = np.fft.rfftfreq(len(mono), 1 / rate)
        self.assertLess(energy[frequencies < 150].sum() / energy.sum(), 0.45,
                        '65/110 Hz continuous drone dominated the old rail bed')

    def test_arrangements_are_not_duplicates_or_pitch_shifted_copies(self):
        paths = [ROOT / (name + '.wav') for name in SCORES]
        self.assertTrue(all(path.exists() for path in paths))
        if all(path.exists() for path in paths):
            self.assertEqual(len({path.read_bytes() for path in paths}), len(paths))


if __name__ == '__main__':
    unittest.main(verbosity=2)
