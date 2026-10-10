"""Generates the placeholder sound effects and music for the racing game.

Run from the project root:   python3 tools/generate_audio.py
Output goes to assets/audio/sfx and assets/audio/music.

Replace any file with your own sound using the SAME file name and the game
will use it. Keep the loop files (engine_loop, tire_screech_loop, menu_loop,
race_loop) seamless so they repeat without a click.
"""
import math
import os
import random
import struct
import wave

SR = 22050
TAU = 2 * math.pi
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SFX_DIR = os.path.join(ROOT, 'assets', 'audio', 'sfx')
MUSIC_DIR = os.path.join(ROOT, 'assets', 'audio', 'music')
rnd = random.Random(7)


def write_wav(path, samples, peak=0.9):
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b''.join(struct.pack('<h', int(max(-1, min(1, s * k)) * 32767)) for s in samples)
        w.writeframes(frames)
    print('wrote', os.path.relpath(path, ROOT), round(len(samples) / SR, 2), 's')


def noise_list(n):
    return [rnd.uniform(-1, 1) for _ in range(n)]


def circular_smooth(x, k):
    """Moving average that wraps around, so loops stay seamless."""
    n = len(x)
    out = [0.0] * n
    acc = sum(x[j % n] for j in range(-k, k + 1))
    w = 2 * k + 1
    for i in range(n):
        out[i] = acc / w
        acc += x[(i + k + 1) % n] - x[(i - k) % n]
    return out


def engine_loop():
    # Exactly 1 second, all partials are whole multiples of 1 Hz -> seamless.
    n = SR
    out = [0.0] * n
    for h in range(1, 13):
        amp = (1.0 / h) * (1.6 if h % 2 == 1 else 0.7)
        f = 42 * h
        for i in range(n):
            out[i] += amp * math.sin(TAU * f * i / SR)
    rough = circular_smooth(noise_list(n), 3)
    for i in range(n):
        out[i] += 0.25 * rough[i]
    write_wav(os.path.join(SFX_DIR, 'engine_loop.wav'), out)


def tire_screech_loop():
    n = SR
    x = noise_list(n)
    lo = circular_smooth(x, 12)
    hi = [a - b for a, b in zip(x, lo)]
    write_wav(os.path.join(SFX_DIR, 'tire_screech_loop.wav'), hi)


def decay_noise(dur, decay, thump_hz=None, thump_amp=0.0, lowpass=0):
    n = int(SR * dur)
    x = noise_list(n)
    if lowpass:
        x = circular_smooth(x, lowpass)
    out = []
    for i in range(n):
        t = i / SR
        v = x[i] * math.exp(-t * decay)
        if thump_hz:
            v += thump_amp * math.sin(TAU * thump_hz * t) * math.exp(-t * decay * 1.5)
        out.append(v)
    return out


def sweep_whoosh():
    dur = 0.9
    n = int(SR * dur)
    x = noise_list(n)
    out = []
    y = 0.0
    for i in range(n):
        t = i / n
        cutoff = 300 + (3200 - 300) * t
        a = 1 - math.exp(-TAU * cutoff / SR)
        y += a * (x[i] - y)
        env = math.sin(math.pi * t) ** 0.8
        out.append(y * env)
    write_wav(os.path.join(SFX_DIR, 'nitro_whoosh.wav'), out)


def beep(freq, dur, harmonic=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1, t / 0.005) * math.exp(-t * 6 / dur)
        out.append(env * (math.sin(TAU * freq * t) + harmonic * math.sin(TAU * freq * 2 * t)))
    return out


def chime():
    notes = [1047, 1319, 1568, 2093]
    out = []
    for f in notes:
        out += beep(f, 0.14)
    return out


def chord_loop(bpm, bars, progression, bass_eighths):
    """Simple looping music: pad chords + bass pulse. Seamless via crossfade."""
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * bars
    fade = 0.35
    n_total = int(SR * (total + fade))
    out = [0.0] * n_total
    for b in range(bars):
        chord = progression[b % len(progression)]
        start = b * bar
        for note in chord:
            for i in range(int(SR * (bar + 0.2))):
                idx = int(SR * start) + i
                if idx >= n_total:
                    break
                t = idx / SR
                env = 0.5 + 0.5 * math.cos(TAU * (t - start) / bar * 0.5)
                out[idx] += 0.10 * env * math.sin(TAU * note * t)
        root = chord[0] / 2
        step = beat / (2 if bass_eighths else 1)
        for k in range(int(bar / step)):
            t0 = start + k * step
            for i in range(int(SR * 0.16)):
                idx = int(SR * t0) + i
                if idx >= n_total:
                    break
                t = idx / SR - t0
                env = math.exp(-t * 14)
                out[idx] += 0.22 * env * math.sin(TAU * root * (idx / SR))
    # Crossfade the tail into the head so the loop has no click.
    fn = int(SR * fade)
    loop_n = int(SR * total)
    for i in range(fn):
        w = i / fn
        out[i] = out[i] * w + out[loop_n + i] * (1 - w)
    return out[:loop_n]


# Chords (Hz) for a calm menu and a more driving race bed.
MENU_CHORDS = [
    [220.0, 277.18, 329.63],
    [174.61, 220.0, 261.63],
    [196.0, 246.94, 293.66],
    [164.81, 207.65, 246.94],
]
RACE_CHORDS = [
    [146.83, 185.0, 220.0],
    [123.47, 155.56, 185.0],
    [130.81, 164.81, 196.0],
    [110.0, 138.59, 164.81],
]

if __name__ == '__main__':
    engine_loop()
    tire_screech_loop()
    write_wav(os.path.join(SFX_DIR, 'impact_wall.wav'), decay_noise(0.5, 14, 110, 0.9, lowpass=2))
    write_wav(os.path.join(SFX_DIR, 'impact_car.wav'), decay_noise(0.4, 18, 180, 0.7, lowpass=1))
    sweep_whoosh()
    write_wav(os.path.join(SFX_DIR, 'beep_count.wav'), beep(880, 0.14))
    write_wav(os.path.join(SFX_DIR, 'beep_go.wav'), beep(1320, 0.45, harmonic=0.3))
    write_wav(os.path.join(SFX_DIR, 'ui_click.wav'), beep(1800, 0.05))
    write_wav(os.path.join(SFX_DIR, 'pickup_chime.wav'), chime())
    write_wav(os.path.join(MUSIC_DIR, 'menu_loop.wav'), chord_loop(84, 4 * 4, MENU_CHORDS, False), peak=0.5)
    write_wav(os.path.join(MUSIC_DIR, 'race_loop.wav'), chord_loop(132, 8 * 2, RACE_CHORDS, True), peak=0.5)
