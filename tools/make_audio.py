#!/usr/bin/env python3
"""Generates every sound in the game as 16-bit mono WAV files in assets/audio/.

Run from the project folder:  python3 tools/make_audio.py
It is a tiny chiptune synthesizer (square / triangle / saw / sine / noise) with envelopes,
so the game needs no downloaded audio. Edit the recipes below and re-run to change a sound.
"""
import math
import os
import random
import struct
import sys
import wave

SFX_RATE = 22050
MUSIC_RATE = 16000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")

NOTE_INDEX = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
              "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def freq(name):
    """'A4' -> 440.0"""
    note, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTE_INDEX[note] + 12 * (octave + 1) - 69) / 12.0)


def osc(kind, ph, duty=0.5):
    if kind == "square":
        return 1.0 if ph < duty else -1.0
    if kind == "tri":
        return 4.0 * abs(ph - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * ph - 1.0
    return math.sin(2 * math.pi * ph)  # sine


def tone(f, dur, kind="square", vol=0.3, a=0.004, d=0.05, s=0.6, r=0.05, duty=0.5, vib=0.0,
         slide_to=None, sr=SFX_RATE, trem=0.0):
    """One note. f can slide to `slide_to` over its length. Returns a list of floats."""
    n = int(dur * sr)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / sr
        fr = f if slide_to is None else f + (slide_to - f) * (i / max(n - 1, 1))
        if vib:
            fr *= 1.0 + vib * math.sin(2 * math.pi * 6.0 * t)
        phase += fr / sr
        ph = phase - math.floor(phase)
        v = osc(kind, ph, duty)
        # ADSR envelope with the release taking up the end of the note.
        if t < a:
            e = t / a
        elif t < a + d:
            e = 1.0 - (1.0 - s) * ((t - a) / d)
        else:
            e = s
        left = dur - t
        if left < r:
            e *= left / r
        if trem:
            e *= 1.0 - trem * (0.5 + 0.5 * math.sin(2 * math.pi * 12.0 * t))
        out[i] = v * e * vol
    return out


def noise(dur, vol=0.3, decay=6.0, smooth=1, sr=SFX_RATE, hp=False):
    """A burst of noise with an exponential decay. smooth > 1 gives a duller, lower sound."""
    n = int(dur * sr)
    raw = [random.uniform(-1, 1) for _ in range(n + smooth)]
    out = [0.0] * n
    prev = 0.0
    for i in range(n):
        if smooth > 1:
            v = sum(raw[i:i + smooth]) / smooth
        else:
            v = raw[i]
        if hp:
            v, prev = v - prev, v
            v *= 0.7
        e = math.exp(-decay * i / sr) if decay > 0 else 1.0
        out[i] = v * e * vol
    return out


def mix(*parts, length=None):
    """Sum lists of samples, each given as (samples) or (samples, start_seconds)."""
    items = []
    for p in parts:
        if isinstance(p, tuple):
            items.append(p)
        else:
            items.append((p, 0.0))
    return mix_at(items, length)


def mix_at(items, length=None, sr=SFX_RATE):
    end = 0
    for samples, start in items:
        end = max(end, int(start * sr) + len(samples))
    n = length if length is not None else end
    out = [0.0] * n
    for samples, start in items:
        off = int(start * sr)
        for i, v in enumerate(samples):
            j = off + i
            if 0 <= j < n:
                out[j] += v
    return out


def normalize(samples, peak=0.9):
    m = max((abs(v) for v in samples), default=1.0) or 1.0
    k = peak / m
    return [v * k for v in samples]


def write_wav(name, samples, sr, peak=0.9):
    os.makedirs(OUT, exist_ok=True)
    samples = normalize(samples, peak)
    data = struct.pack("<%dh" % len(samples), *[int(max(-1.0, min(1.0, v)) * 32767) for v in samples])
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data)
    print("  %-20s %5.2fs  %4d KB" % (name, len(samples) / sr, len(data) // 1024))


def arp(notes, step, kind="square", vol=0.25, **kw):
    """A run of notes one after another; returns (samples) in one list."""
    out = []
    for n in notes:
        t = tone(freq(n), step, kind, vol, **kw)
        out.extend(t)
    return out


def seq(items):
    """Lay (samples, start) pairs end to end into one list via mix."""
    return mix_at(items)


# ---------------------------------------------------------------- sound effects

def sfx():
    random.seed(7)
    S = {}

    S["swing"] = mix(noise(0.14, 0.5, 18, 3, hp=True), tone(700, 0.12, "sine", 0.25, slide_to=250, d=0.02, r=0.04))
    S["hit"] = mix(noise(0.09, 0.6, 30, 2), tone(260, 0.09, "square", 0.3, slide_to=110, s=0.4, r=0.03))
    S["enemy_die"] = mix(arp(["E5", "C5", "G4", "C4"], 0.06, "square", 0.25, s=0.5, r=0.02), noise(0.22, 0.35, 12, 3))
    S["hurt"] = mix(tone(190, 0.28, "saw", 0.4, slide_to=80, s=0.7, r=0.08), noise(0.1, 0.5, 20, 2))
    S["dash"] = noise(0.18, 0.55, 14, 4, hp=True)
    S["fireball"] = mix(tone(220, 0.34, "saw", 0.28, slide_to=900, d=0.1, r=0.1, trem=0.5), noise(0.3, 0.3, 8, 2, hp=True))
    S["boom"] = mix(noise(0.55, 0.9, 6, 5), tone(90, 0.5, "sine", 0.7, slide_to=40, s=0.5, r=0.2))
    S["coin"] = mix(tone(988, 0.07, "square", 0.25, s=0.8, r=0.01), (tone(1319, 0.22, "square", 0.25, d=0.12, s=0.3, r=0.1), 0.07))
    S["buy"] = mix(*[(tone(freq(n), 0.12, "square", 0.22, d=0.05, s=0.4, r=0.05), i * 0.07) for i, n in enumerate(["E6", "G6", "C7"])])
    S["click"] = tone(900, 0.035, "square", 0.22, s=0.5, r=0.01, a=0.001)
    S["tick"] = tone(1500, 0.018, "square", 0.1, s=0.5, r=0.005, a=0.001)
    S["open"] = mix(tone(freq("C5"), 0.07, "square", 0.2, r=0.02), (tone(freq("G5"), 0.1, "square", 0.2, r=0.05), 0.06))
    S["close"] = mix(tone(freq("G5"), 0.07, "square", 0.2, r=0.02), (tone(freq("C5"), 0.1, "square", 0.2, r=0.05), 0.06))
    S["blip"] = tone(520, 0.03, "square", 0.16, s=0.6, r=0.01, a=0.001, duty=0.25)
    S["eat"] = mix(*[(noise(0.06, 0.6, 30, 3), i * 0.11) for i in range(3)])
    S["potion"] = mix(tone(300, 0.45, "sine", 0.35, slide_to=900, vib=0.03, d=0.1, s=0.7, r=0.1), noise(0.4, 0.12, 4, 4))
    S["heal"] = arp(["C5", "E5", "G5", "C6"], 0.07, "sine", 0.3, d=0.05, s=0.6, r=0.05)
    S["powerup"] = arp(["C5", "E5", "G5", "C6", "E6"], 0.065, "square", 0.22, d=0.04, s=0.5, r=0.03)
    S["levelup"] = mix(arp(["C5", "E5", "G5", "C6"], 0.11, "square", 0.22, r=0.05),
                       (mix(tone(freq("C6"), 0.7, "square", 0.2, d=0.2, s=0.5, r=0.3), tone(freq("E6"), 0.7, "tri", 0.25, d=0.2, s=0.5, r=0.3), tone(freq("G6"), 0.7, "tri", 0.2, d=0.2, s=0.5, r=0.3)), 0.44))
    S["quest_accept"] = arp(["G4", "C5", "E5"], 0.09, "square", 0.22, r=0.04)
    S["quest_done"] = mix(arp(["C5", "E5", "G5", "E5", "G5", "C6"], 0.085, "square", 0.22, r=0.04),
                          (tone(freq("C6"), 0.5, "tri", 0.3, d=0.2, s=0.4, r=0.25), 0.5))
    S["chest"] = mix(tone(110, 0.42, "saw", 0.25, slide_to=210, vib=0.04, trem=0.5, r=0.1),
                     (arp(["E6", "G6", "B6", "E7"], 0.06, "sine", 0.22, r=0.04), 0.3))
    S["prize"] = mix(arp(["C5", "E5", "G5", "C6", "G5", "C6", "E6", "G6"], 0.11, "square", 0.22, r=0.05),
                     (mix(tone(freq("C6"), 1.5, "tri", 0.3, d=0.3, s=0.6, r=0.6), tone(freq("G6"), 1.5, "tri", 0.2, d=0.3, s=0.6, r=0.6),
                          tone(freq("E7"), 1.5, "sine", 0.18, d=0.3, s=0.6, r=0.6, vib=0.01)), 0.88))
    S["roar"] = mix(tone(75, 1.1, "saw", 0.5, slide_to=38, vib=0.05, d=0.3, s=0.7, r=0.3), noise(1.0, 0.35, 2.5, 6))
    S["boss_defeat"] = mix(arp(["A4", "F4", "D4", "A3", "D3"], 0.2, "saw", 0.3, d=0.1, s=0.7, r=0.12),
                           (mix(noise(1.2, 0.8, 2.5, 6), tone(70, 1.2, "sine", 0.6, slide_to=30, r=0.5)), 0.4))
    S["bolt"] = tone(950, 0.16, "square", 0.2, slide_to=380, s=0.5, r=0.06, duty=0.25)
    S["door"] = mix(noise(0.1, 0.7, 24, 5), tone(120, 0.14, "sine", 0.5, slide_to=70, r=0.06))
    S["chop"] = mix(noise(0.08, 0.7, 40, 4), tone(170, 0.1, "sine", 0.55, slide_to=70, r=0.04))
    S["mine"] = mix(tone(1800, 0.2, "sine", 0.4, d=0.18, s=0.0, r=0.02), tone(2750, 0.14, "sine", 0.2, d=0.12, s=0.0, r=0.02), noise(0.04, 0.5, 40, 1))
    S["cast"] = mix(noise(0.2, 0.45, 12, 3, hp=True), tone(500, 0.2, "sine", 0.2, slide_to=150, r=0.06))
    S["bite"] = mix(tone(1568, 0.07, "square", 0.25, r=0.01), (tone(1568, 0.07, "square", 0.25, r=0.01), 0.1), (tone(2093, 0.12, "square", 0.25, r=0.04), 0.2))
    S["reel"] = mix(*[(tone(700, 0.025, "square", 0.2, s=0.6, r=0.005, a=0.001), i * 0.05) for i in range(6)])
    S["splash"] = mix(noise(0.35, 0.6, 9, 3), tone(300, 0.25, "sine", 0.3, slide_to=120, r=0.1))
    S["catch_common"] = arp(["C5", "E5"], 0.08, "square", 0.22, r=0.03)
    S["catch_uncommon"] = arp(["C5", "E5", "G5"], 0.08, "square", 0.22, r=0.03)
    S["catch_rare"] = arp(["C5", "E5", "G5", "C6"], 0.08, "square", 0.22, r=0.04)
    S["catch_epic"] = mix(arp(["C5", "E5", "G5", "C6", "E6"], 0.08, "square", 0.22, r=0.04),
                          (tone(freq("G6"), 0.5, "tri", 0.3, d=0.2, s=0.5, r=0.25), 0.4))
    S["catch_legendary"] = mix(arp(["C5", "E5", "G5", "C6", "E6", "G6", "C7"], 0.075, "square", 0.22, r=0.04),
                               (mix(tone(freq("C6"), 1.3, "tri", 0.3, d=0.3, s=0.6, r=0.5), tone(freq("E6"), 1.3, "tri", 0.2, d=0.3, s=0.6, r=0.5),
                                    tone(freq("C7"), 1.3, "sine", 0.18, d=0.3, s=0.6, r=0.5, vib=0.01)), 0.5))
    S["shoot"] = mix(tone(300, 0.12, "saw", 0.3, slide_to=120, s=0.4, r=0.05), noise(0.08, 0.4, 25, 2, hp=True))
    S["target_hit"] = mix(noise(0.05, 0.7, 40, 3), tone(380, 0.08, "square", 0.3, slide_to=200, r=0.03))
    S["bullseye"] = mix(tone(1319, 0.5, "sine", 0.4, d=0.4, s=0.0, r=0.05), tone(1975, 0.4, "sine", 0.2, d=0.3, s=0.0, r=0.05))
    S["gold_target"] = arp(["E6", "G6", "B6", "E7", "G7"], 0.05, "sine", 0.3, r=0.03)
    S["miss"] = tone(220, 0.12, "tri", 0.2, slide_to=140, s=0.4, r=0.05)
    S["pet"] = mix(tone(900, 0.07, "sine", 0.3, slide_to=1400, r=0.02), (tone(1100, 0.09, "sine", 0.3, slide_to=1700, r=0.03), 0.09))
    S["night"] = mix(*[(tone(freq("G3"), 1.0, "sine", 0.4, d=0.6, s=0.1, r=0.3), 0.0), (tone(freq("D3"), 1.2, "sine", 0.4, d=0.7, s=0.1, r=0.4), 0.7)])
    S["dawn"] = mix(*[(tone(freq(n), 1.2, "sine", 0.28, d=0.6, s=0.2, r=0.5), i * 0.12) for i, n in enumerate(["C5", "E5", "G5", "C6"])])
    S["sizzle"] = mix(noise(0.9, 0.4, 1.5, 1, hp=True), *[(noise(0.03, 0.8, 50, 1), random.uniform(0.0, 0.8)) for _ in range(14)])
    S["cook_done"] = mix(tone(freq("C6"), 0.5, "sine", 0.4, d=0.4, s=0.0, r=0.05), (arp(["E6", "G6", "C7"], 0.08, "square", 0.2, r=0.04), 0.1))
    S["freeze"] = mix(tone(2400, 0.3, "sine", 0.25, slide_to=3200, d=0.25, s=0.0, r=0.03), noise(0.2, 0.3, 14, 1, hp=True))
    S["slam"] = mix(noise(0.6, 0.9, 5, 6), tone(65, 0.55, "sine", 0.8, slide_to=30, r=0.2), (noise(0.15, 0.6, 30, 1, hp=True), 0.03))
    S["ice_shatter"] = mix(noise(0.25, 0.5, 14, 1, hp=True), arp(["E7", "C7", "G6", "E6"], 0.04, "sine", 0.2, r=0.02))
    S["victory"] = mix(arp(["C5", "C5", "C5", "G4", "A4", "C5", "A4", "C5"], 0.1, "square", 0.22, r=0.04),
                       (mix(tone(freq("C6"), 1.0, "tri", 0.3, d=0.2, s=0.6, r=0.4), tone(freq("E6"), 1.0, "tri", 0.2, d=0.2, s=0.6, r=0.4)), 0.8))
    for name, samples in S.items():
        write_wav(name, samples, SFX_RATE, 0.85)


# ---------------------------------------------------------------- ambience

def crossfaded(samples, fade):
    """Make a loop seamless by fading the tail into the head."""
    n = len(samples) - fade
    out = samples[:n]
    for i in range(fade):
        k = i / fade
        out[i] = out[i] * k + samples[n + i] * (1 - k)
    return out


def ambience():
    random.seed(11)
    sr = SFX_RATE
    # Birds: soft chirps at random moments.
    dur = 12.0
    items = []
    t = 0.6
    while t < dur - 1.0:
        base = random.choice([2400, 2900, 3300, 3800])
        for k in range(random.randint(2, 4)):
            chirp = tone(base, 0.06, "sine", 0.35, slide_to=base * random.choice([1.25, 0.8]), a=0.005, d=0.03, s=0.3, r=0.02)
            items.append((chirp, t + k * 0.085))
        t += random.uniform(0.9, 2.6)
    birds = mix_at(items, int(dur * sr))
    # A faint breeze under the birds.
    breeze = noise(dur, 0.06, 0, 30)
    write_wav("amb_birds", mix(birds, breeze), sr, 0.5)

    # Crickets: rapid pulses of a high tone that swell and fade.
    dur = 8.0
    n = int(dur * sr)
    out = [0.0] * n
    for i in range(n):
        t = i / sr
        gate = 1.0 if (t * 18.0) % 1.0 < 0.55 else 0.0
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * t / dur * 2)
        out[i] = math.sin(2 * math.pi * 4300 * t) * gate * swell * 0.18
    write_wav("amb_crickets", mix(out, noise(dur, 0.03, 0, 40)), sr, 0.35)

    # Wind: smoothed noise with a slow swell (used in the frozen caves).
    dur = 10.0
    fade = int(0.5 * sr)
    raw = noise(dur + 0.5, 0.5, 0, 24)
    for i in range(len(raw)):
        t = i / sr
        raw[i] *= 0.55 + 0.45 * math.sin(2 * math.pi * t / dur * 1.0)
    write_wav("amb_wind", crossfaded(raw, fade), sr, 0.5)

    # Cave: a low drone with rare drips.
    dur = 10.0
    n = int(dur * sr)
    drone = [0.0] * n
    for i in range(n):
        t = i / sr
        drone[i] = (math.sin(2 * math.pi * 55 * t) * 0.5 + math.sin(2 * math.pi * 82.5 * t) * 0.3) * (0.8 + 0.2 * math.sin(2 * math.pi * t / dur * 2))
    drips = []
    for t in [1.3, 4.2, 6.8, 8.5]:
        f = random.choice([1500, 1900, 2300])
        drips.append((tone(f, 0.18, "sine", 0.5, slide_to=f * 0.6, d=0.15, s=0.0, r=0.02), t))
    write_wav("amb_cave", mix(drone, mix_at(drips, n)), sr, 0.6)


# ---------------------------------------------------------------- music

def render_music(name, bpm, bars, chords, scale, bass_oct, seed, lead="square", mel_density=0.7,
                 drums="", arp_kind="square", arp_vol=0.12, mel_vol=0.2, bass_kind="tri", pad=False,
                 mel_oct=5, arp_oct=4, echo=0.0, drip=False, bell=False, bass_pattern="x.x.", arp_rate=2):
    """Composes one looping track. `chords` has one chord per bar: (root, [chord notes]).
    `scale` is a list of note names the melody wanders through. Beats are quarter notes."""
    random.seed(seed)
    sr = MUSIC_RATE
    beat = 60.0 / bpm
    total = int(bars * 4 * beat * sr)
    items = []

    steps = len(scale)
    pos = steps // 2
    for bar in range(bars):
        root, notes = chords[bar % len(chords)]
        t0 = bar * 4 * beat
        # Bass: one character per step across the bar ("x" plays the root note).
        step = 4 * beat / len(bass_pattern)
        for b, ch in enumerate(bass_pattern):
            if ch == "x":
                items.append((tone(freq(root + str(bass_oct)), step * 0.9, bass_kind, 0.34, d=0.08, s=0.55, r=0.06, sr=sr), t0 + b * step))
        # Arpeggio of the chord tones.
        per_beat = arp_rate
        for k in range(4 * per_beat):
            note = notes[k % len(notes)]
            items.append((tone(freq(note + str(arp_oct + (1 if (k // len(notes)) % 2 else 0))), beat / per_beat * 0.85, arp_kind, arp_vol, d=0.05, s=0.4, r=0.04, duty=0.25, sr=sr), t0 + k * beat / per_beat))
        # Pad: long soft chord.
        if pad:
            for note in notes:
                items.append((tone(freq(note + "3"), beat * 4 * 0.98, "sine", 0.1, a=0.4, d=0.5, s=0.8, r=0.5, sr=sr), t0))
        # Melody: a random walk through the scale, favouring small steps.
        t = 0.0
        while t < 4 * beat - 0.01:
            if random.random() < mel_density:
                move = random.choice([-2, -1, -1, 0, 1, 1, 2])
                pos = max(0, min(steps - 1, pos + move))
                length = random.choice([0.5, 0.5, 1.0, 1.0, 1.5]) * beat
                length = min(length, 4 * beat - t)
                n = scale[pos]
                nm = n[:-1] + str(int(n[-1]) + (mel_oct - 5))
                if bell:
                    items.append((tone(freq(nm), length * 1.4, "sine", mel_vol, a=0.002, d=length * 1.2, s=0.0, r=0.05, sr=sr), t0 + t))
                else:
                    items.append((tone(freq(nm), length * 0.92, lead, mel_vol, d=0.06, s=0.6, r=0.05, duty=0.5, vib=0.004, sr=sr), t0 + t))
                t += length
            else:
                t += 0.5 * beat
        # Drums: one character per eighth note: k kick, s snare, h hat.
        if drums:
            for k in range(8):
                c = drums[k % len(drums)]
                at = t0 + k * beat / 2
                if c == "k":
                    items.append((tone(130, 0.14, "sine", 0.5, slide_to=45, d=0.1, s=0.0, r=0.02, sr=sr), at))
                elif c == "s":
                    items.append((noise(0.12, 0.38, 22, 2, sr=sr), at))
                elif c == "h":
                    items.append((noise(0.04, 0.16, 60, 1, sr=sr, hp=True), at))
        # Cave drips.
        if drip and bar % 3 == 1:
            f = random.choice([1800, 2200, 2600])
            items.append((tone(f, 0.18, "sine", 0.18, slide_to=f * 0.6, d=0.15, s=0.0, r=0.02, sr=sr), t0 + random.uniform(0.5, 3.0) * beat))

    out = mix_at(items, total, sr)
    if echo:
        delay = int(beat * 0.75 * sr)
        echoed = [0.0] * total
        for i in range(total):
            echoed[i] = out[i] + out[(i - delay) % total] * echo + out[(i - 2 * delay) % total] * echo * 0.5
        out = echoed
    write_wav(name, out, sr, 0.8)


def music():
    # Farm: calm, warm C major.
    render_music("mus_farm", 92, 16,
                 [("C", ["C", "E", "G"]), ("G", ["G", "B", "D"]), ("A", ["A", "C", "E"]), ("F", ["F", "A", "C"]),
                  ("C", ["C", "E", "G"]), ("G", ["G", "B", "D"]), ("F", ["F", "A", "C"]), ("G", ["G", "B", "D"]),
                  ("C", ["C", "E", "G"]), ("A", ["A", "C", "E"]), ("F", ["F", "A", "C"]), ("G", ["G", "B", "D"]),
                  ("C", ["C", "E", "G"]), ("G", ["G", "B", "D"]), ("F", ["F", "A", "C"]), ("C", ["C", "E", "G"])],
                 ["C5", "D5", "E5", "G5", "A5", "C6", "G4", "A4"][::1], 2, 3, lead="tri", mel_density=0.75, mel_vol=0.26, arp_vol=0.1)
    # Town: bright and bouncy G major with light drums.
    render_music("mus_town", 118, 16,
                 [("G", ["G", "B", "D"]), ("D", ["D", "F#", "A"]), ("E", ["E", "G", "B"]), ("C", ["C", "E", "G"]),
                  ("G", ["G", "B", "D"]), ("D", ["D", "F#", "A"]), ("C", ["C", "E", "G"]), ("D", ["D", "F#", "A"]),
                  ("G", ["G", "B", "D"]), ("E", ["E", "G", "B"]), ("C", ["C", "E", "G"]), ("D", ["D", "F#", "A"]),
                  ("G", ["G", "B", "D"]), ("D", ["D", "F#", "A"]), ("C", ["C", "E", "G"]), ("G", ["G", "B", "D"])],
                 ["G4", "A4", "B4", "D5", "E5", "G5", "A5", "B5"], 2, 4, lead="square", mel_density=0.85, mel_vol=0.17,
                 arp_vol=0.1, drums="k.hsk.hs", bass_pattern="x.x.")
    # Interior: gentle music box in F major.
    render_music("mus_interior", 78, 16,
                 [("F", ["F", "A", "C"]), ("C", ["C", "E", "G"]), ("D", ["D", "F", "A"]), ("Bb", ["Bb", "D", "F"]),
                  ("F", ["F", "A", "C"]), ("C", ["C", "E", "G"]), ("Bb", ["Bb", "D", "F"]), ("C", ["C", "E", "G"])],
                 ["F5", "G5", "A5", "C6", "D6", "F6", "A5", "G5"], 2, 5, mel_density=0.6, mel_vol=0.3, arp_vol=0.05,
                 bell=True, bass_kind="sine", pad=True, arp_kind="sine", arp_oct=4)
    # Night on the surface: slow and quiet, C minor.
    render_music("mus_night", 66, 12,
                 [("C", ["C", "Eb", "G"]), ("Ab", ["Ab", "C", "Eb"]), ("Bb", ["Bb", "D", "F"]), ("G", ["G", "Bb", "D"])],
                 ["C5", "Eb5", "F5", "G5", "Bb5", "C6", "G4", "Bb4"], 2, 6, mel_density=0.5, mel_vol=0.24, arp_vol=0.05,
                 bell=True, bass_kind="sine", pad=True, arp_kind="sine", arp_rate=1)
    # Cave: dark A minor with echo and drips.
    render_music("mus_cave", 70, 16,
                 [("A", ["A", "C", "E"]), ("A", ["A", "C", "E"]), ("F", ["F", "A", "C"]), ("G", ["G", "B", "D"]),
                  ("A", ["A", "C", "E"]), ("E", ["E", "G", "B"]), ("F", ["F", "A", "C"]), ("E", ["E", "G#", "B"])],
                 ["A4", "C5", "D5", "E5", "G5", "A5", "E4", "G4"], 2, 7, lead="tri", mel_density=0.45, mel_vol=0.22, arp_vol=0.08,
                 pad=True, echo=0.45, drip=True, bass_kind="sine", arp_rate=1)
    # Boss: fast, driving D minor.
    render_music("mus_boss", 152, 16,
                 [("D", ["D", "F", "A"]), ("D", ["D", "F", "A"]), ("Bb", ["Bb", "D", "F"]), ("C", ["C", "E", "G"]),
                  ("D", ["D", "F", "A"]), ("A", ["A", "C#", "E"]), ("Bb", ["Bb", "D", "F"]), ("A", ["A", "C#", "E"])],
                 ["D5", "E5", "F5", "G5", "A5", "Bb5", "C6", "D6"], 2, 8, lead="square", mel_density=0.9, mel_vol=0.17,
                 arp_vol=0.12, drums="k.hsk.hs", bass_kind="saw", bass_pattern="xxxxxxxx", arp_rate=4)
    # Frozen caves: icy, sparse bells over wind-like pads in E minor.
    render_music("mus_frost", 76, 16,
                 [("E", ["E", "G", "B"]), ("C", ["C", "E", "G"]), ("D", ["D", "F#", "A"]), ("B", ["B", "D", "F#"])],
                 ["E5", "G5", "A5", "B5", "D6", "E6", "G6", "B6"], 2, 9, mel_density=0.5, mel_vol=0.26, arp_vol=0.06,
                 bell=True, pad=True, echo=0.4, bass_kind="sine", arp_kind="sine", arp_rate=1)


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    print("Sound effects:")
    if what in ("all", "sfx"):
        sfx()
    print("Ambience:")
    if what in ("all", "amb"):
        ambience()
    print("Music:")
    if what in ("all", "music"):
        music()
