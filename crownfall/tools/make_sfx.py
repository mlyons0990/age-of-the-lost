"""Synthesizes the game's sound effects into assets/sfx/*.wav.

Every sound is generated from noise, sine waves and simple filters, so they are
original and can be regenerated or tweaked here. Needs Python 3 with numpy.
usage: python make_sfx.py <output folder>
"""
import sys, os, wave
import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def env(dur, attack=0.005, decay=None, curve=4.0):
    """Fast attack, exponential-ish decay to silence at the end."""
    n = int(SR * dur)
    x = np.linspace(0, 1, n)
    a = np.clip(x * dur / max(attack, 1e-4), 0, 1)
    d = (1 - x) ** curve if decay is None else np.exp(-x * dur / decay)
    return a * d


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be a number or an array (sweeps)."""
    c = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * c / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def sine(freq, dur, phase=0.0):
    f = np.broadcast_to(np.asarray(freq, dtype=float), (int(SR * dur),))
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def bell(freq, dur, decay=0.25):
    """Inharmonic partials make a metallic, bell-like ring."""
    out = np.zeros(int(SR * dur))
    for ratio, amp in [(1.0, 1.0), (2.76, 0.5), (5.4, 0.28), (8.93, 0.14)]:
        out += amp * sine(freq * ratio, dur) * env(dur, 0.002, decay / ratio ** 0.5)
    return out


def at(sig, total, start):
    """Places a sound at a start time inside a buffer `total` seconds long."""
    out = np.zeros(int(SR * total))
    i = int(SR * start)
    n = min(len(sig), len(out) - i)
    out[i:i + n] += sig[:n]
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def save(folder, name, x, gain=0.9):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    fade = min(len(x), int(SR * 0.004))
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(folder, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def build(folder):
    os.makedirs(folder, exist_ok=True)
    # --- sword and combat
    d = 0.26
    sweep = np.interp(t(d), [0, d * 0.45, d], [700, 3800, 900])
    save(folder, "swing", bandpass(noise(d), sweep * 0.5, sweep) * env(d, 0.06, curve=2.2), 0.7)

    d = 0.18
    thump = sine(np.interp(t(d), [0, d], [150, 55]), d) * env(d, 0.002, curve=3)
    click = highpass(noise(d), 1800) * env(d, 0.001, 0.012)
    save(folder, "hit", mix(thump, click * 0.6, lowpass(noise(d), 900) * env(d, 0.001, 0.03) * 0.6))

    d = 0.5
    save(folder, "crit", mix(at(sine(np.interp(t(0.2), [0, 0.2], [170, 50]), 0.2) * env(0.2, 0.002, curve=3), d, 0),
                             highpass(noise(0.05), 2500) * env(0.05, 0.001, 0.01) * 0.8,
                             bell(1180, d, 0.18) * 0.45), 0.85)

    d = 0.22
    save(folder, "hurt", mix(sine(np.interp(t(d), [0, d], [110, 45]), d) * env(d, 0.003, curve=2.5),
                             lowpass(noise(d), 600) * env(d, 0.002, 0.05) * 0.8), 0.8)

    d = 0.17
    s2 = np.interp(t(d), [0, d], [5000, 1800])
    save(folder, "dodge", bandpass(noise(d), s2 * 0.6, s2) * env(d, 0.02, curve=2), 0.5)

    d = 0.3
    s3 = np.interp(t(d), [0, d * 0.5, d], [400, 1800, 500])
    save(folder, "enemy_swing", bandpass(noise(d), s3 * 0.5, s3) * env(d, 0.05, curve=2), 0.55)

    d = 0.7
    poof = lowpass(noise(d), np.interp(t(d), [0, d], [3000, 200])) * env(d, 0.004, curve=2.2)
    sink = sine(np.interp(t(d), [0, d], [260, 70]), d) * env(d, 0.01, curve=3) * 0.6
    save(folder, "enemy_die", mix(poof, sink), 0.75)

    # --- skills
    d = 1.1
    boom = sine(np.interp(t(d), [0, 0.3, d], [90, 45, 30]), d) * env(d, 0.004, curve=2.5)
    crack = lowpass(noise(d), np.interp(t(d), [0, d], [6000, 300])) * env(d, 0.002, 0.25)
    save(folder, "boom", mix(boom, crack * 0.8, at(bell(520, 0.9, 0.3) * 0.25, d, 0.0)), 0.95)

    d = 0.8
    roar = bandpass(noise(d), 300, np.interp(t(d), [0, 0.15, d], [1500, 4200, 1200])) * env(d, 0.06, curve=1.6)
    crackle = (rng.random(int(SR * d)) > 0.9965) * rng.uniform(-1, 1, int(SR * d))
    save(folder, "fire", mix(roar, lowpass(crackle, 5000) * 2.5), 0.8)

    d = 0.9
    choir = sum(sine(np.interp(t(d), [0, d], [f, f * 0.62]), d) for f in (330, 392, 494, 587)) / 4
    save(folder, "harvest", mix(choir * env(d, 0.08, curve=1.5), lowpass(noise(d), 700) * env(d, 0.2, curve=2) * 0.4), 0.7)

    d = 0.4
    s4 = np.interp(t(d), [0, d], [800, 3000])
    save(folder, "charge", mix(bandpass(noise(d), s4 * 0.5, s4) * env(d, 0.02, curve=1.2),
                               at(sine(np.interp(t(0.15), [0, 0.15], [140, 60]), 0.15) * env(0.15, 0.002, curve=3), d, 0.25)), 0.8)

    d = 1.0
    chord = sum(sine(f, d) * env(d, 0.12, curve=1.8) for f in (523.25, 659.25, 783.99, 1046.5)) / 4
    save(folder, "rally", mix(chord, bell(1567, d, 0.3) * 0.2), 0.7)

    # --- loot and items
    d = 0.32
    coins = mix(*[at(bell(f, 0.2, 0.05), d, s) for f, s in [(2350, 0.0), (2900, 0.06), (2600, 0.12)]])
    save(folder, "gold", coins, 0.55)

    d = 0.22
    save(folder, "pickup", mix(at(sine(660, 0.1) * env(0.1, 0.003, 0.04), d, 0), at(sine(990, 0.12) * env(0.12, 0.003, 0.05), d, 0.07)), 0.5)

    d = 0.6
    save(folder, "drop_rare", mix(at(bell(1320, 0.5, 0.18), d, 0), at(bell(1980, 0.5, 0.18) * 0.6, d, 0.09)), 0.6)

    d = 0.45
    wob = 300 + 140 * np.sin(2 * np.pi * 18 * t(d)) + np.interp(t(d), [0, d], [0, 500])
    save(folder, "potion", sine(wob, d) * env(d, 0.01, curve=1.5), 0.5)

    d = 1.4
    notes = [523.25, 659.25, 783.99, 1046.5]
    arp = mix(*[at(bell(f, 0.9, 0.35), d, i * 0.1) for i, f in enumerate(notes)])
    pad = sum(sine(f / 2, d) for f in notes) / 4 * env(d, 0.3, curve=1.2) * 0.4
    save(folder, "level_up", mix(arp, pad), 0.8)

    # --- the Reality Scar
    d = 1.8
    drone = sum(sine(f * (1 + 0.004 * np.sin(2 * np.pi * 0.7 * t(d))), d) for f in (55, 82.4, 110)) / 3
    shimmer = highpass(noise(d), 3000) * (np.linspace(0, 1, int(SR * d)) ** 3)
    save(folder, "rift_open", mix(drone * env(d, 0.6, curve=1.2), shimmer * 0.25 * env(d, 1.2, curve=0.3)), 0.8)

    d = 0.9
    horn = lowpass(np.sign(sine(110, d)) * 0.5 + sine(220, d) * 0.5, 900) * env(d, 0.08, curve=1.4)
    save(folder, "wave", horn, 0.6)

    d = 0.8
    save(folder, "rift_close", sum(sine(np.interp(t(d), [0, d], [f, f * 0.5]), d) for f in (220, 330)) / 2 * env(d, 0.01, curve=2), 0.55)

    # --- Lorecasting: a rising shimmer with a soft, distant chord underneath
    d = 2.0
    rise = mix(*[at(bell(f, 1.4, 0.5) * 0.5, d, i * 0.12) for i, f in enumerate([587.3, 739.99, 880.0, 1108.7, 1318.5])])
    hush = sum(sine(f, d) for f in (146.8, 220.0, 293.7)) / 3 * env(d, 0.6, curve=1.4) * 0.5
    sparkle = highpass(noise(d), 5000) * env(d, 0.4, curve=1.8) * 0.12
    save(folder, "lorecast", mix(rise, hush, sparkle), 0.7)

    # --- interface
    save(folder, "ui_pick", highpass(noise(0.05), 2000) * env(0.05, 0.001, 0.008) + sine(1400, 0.05) * env(0.05, 0.001, 0.01) * 0.4, 0.4)
    save(folder, "ui_drop", lowpass(noise(0.08), 900) * env(0.08, 0.001, 0.02) + sine(300, 0.08) * env(0.08, 0.001, 0.02) * 0.5, 0.45)
    save(folder, "equip", mix(bell(880, 0.35, 0.08) * 0.5, highpass(noise(0.06), 1500) * env(0.06, 0.001, 0.01)), 0.5)
    d = 0.5
    save(folder, "sell", mix(*[at(bell(f, 0.25, 0.06), d, s) for f, s in [(2100, 0), (2600, 0.05), (2350, 0.1), (3100, 0.16), (2800, 0.22)]]), 0.55)
    save(folder, "error", sine(150, 0.16) * env(0.16, 0.003, curve=1.5) + sine(143, 0.16) * env(0.16, 0.003, curve=1.5), 0.4)
    save(folder, "click", sine(1000, 0.03) * env(0.03, 0.001, 0.006), 0.3)

    # --- enemy casters (added after everything else so the earlier sounds stay identical)
    d = 0.55
    whoosh = bandpass(noise(d), 600, np.interp(t(d), [0, d], [900, 4200])) * env(d, 0.12, curve=1.6)
    hum = sine(np.interp(t(d), [0, d], [220, 440]), d) * env(d, 0.08, curve=1.5) * 0.5
    save(folder, "bolt_cast", mix(whoosh, hum, bell(1320, d, 0.12) * 0.25), 0.6)
    d = 0.35
    zap = highpass(noise(d), 1500) * env(d, 0.002, 0.05)
    thud = sine(np.interp(t(d), [0, d], [300, 90]), d) * env(d, 0.002, curve=3) * 0.7
    save(folder, "bolt_hit", mix(zap, thud), 0.6)


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "assets/sfx")
    print("done")
