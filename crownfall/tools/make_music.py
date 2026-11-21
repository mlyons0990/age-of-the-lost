"""Synthesizes the game's two music loops into assets/music/*.ogg.

  plaza.ogg - calm loop for Crownsfall: pad, harp arpeggios, a soft flute melody.
  scar.ogg  - battle loop for the Reality Scar: war drums, low string ostinato, choir.

Everything is built from sine waves, filtered saws and noise, so the music is
original and can be changed here. Needs Python 3 with numpy, and ffmpeg for the
Ogg Vorbis encode. usage: python make_music.py <output folder>
"""
import sys, os, wave, subprocess, tempfile
import numpy as np

SR = 44100
rng = np.random.default_rng(11)


def note_hz(n):
    """MIDI note number to frequency."""
    return 440.0 * 2 ** ((n - 69) / 12)


def adsr(n, a, d, s, r, sr=SR):
    a, d, r = int(a * sr), int(d * sr), int(r * sr)
    a = max(a, 1)
    env = np.full(n, s, dtype=float)
    env[:a] = np.linspace(0, 1, a)
    d_end = min(n, a + d)
    if d_end > a:
        env[a:d_end] = np.linspace(1, s, d_end - a)
    if r > 0 and r < n:
        env[-r:] *= np.linspace(1, 0, r)
    return env


def lowpass(x, cutoff):
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def saw(freq, n, detune=0.0):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for d in (-detune, 0.0, detune):
        ph = (freq * (1 + d) * t) % 1.0
        out += 2 * ph - 1
    return out / 3


def pad(notes, dur, bright=1400.0):
    n = int(dur * SR)
    x = sum(saw(note_hz(m), n, 0.004) for m in notes) / len(notes)
    return lowpass(x, bright) * adsr(n, 0.8, 0.5, 0.8, 0.9)


def harp(m, dur, vol=1.0):
    """Plucked string from decaying harmonics."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note_hz(m)
    out = np.zeros(n)
    for k in range(1, 9):
        out += np.sin(2 * np.pi * f * k * t) * np.exp(-t * (2.0 + 1.6 * k)) / k ** 1.1
    out *= np.minimum(1, t / 0.004)
    return out * vol


def flute(m, dur, vol=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note_hz(m) * (1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1, t / 0.4))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = lowpass(rng.uniform(-1, 1, n), 2500) * 0.04
    return (x + breath) * adsr(n, 0.08, 0.1, 0.85, 0.18) * vol


def bell(m, dur, vol=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note_hz(m)
    out = np.zeros(n)
    for ratio, amp in [(1.0, 1.0), (2.76, 0.4), (5.4, 0.2)]:
        out += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t * (1.5 * ratio))
    return out * np.minimum(1, t / 0.002) * vol


def strings(m, dur, vol=1.0, bright=900.0):
    n = int(dur * SR)
    return lowpass(saw(note_hz(m), n, 0.006), bright) * adsr(n, 0.01, 0.06, 0.7, 0.05) * vol


def choir(notes, dur, vol=1.0):
    """Vowel-like 'ah': filtered saws with a slow swell."""
    n = int(dur * SR)
    x = sum(saw(note_hz(m), n, 0.008) for m in notes) / len(notes)
    x = lowpass(x, 1100) * 0.7 + lowpass(x, 700) * 0.3
    return x * adsr(n, 1.2, 0.3, 0.9, 1.0) * vol


def drum(dur, low=55.0, vol=1.0, noise_amt=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * np.cumsum(low * (1 + 1.5 * np.exp(-t * 30))) / SR) * np.exp(-t * 7)
    hit = lowpass(rng.uniform(-1, 1, n), 1800) * np.exp(-t * 35) * noise_amt
    return (body + hit) * vol


def place(buf, sig, start, pan=0.0):
    """Adds a mono signal into a stereo buffer at start seconds, wrapping past the end so the loop is seamless."""
    i = int(start * SR) % buf.shape[0]
    l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
    n = len(sig)
    end = i + n
    first = min(n, buf.shape[0] - i)
    buf[i:i + first, 0] += sig[:first] * l
    buf[i:i + first, 1] += sig[:first] * r
    if end > buf.shape[0]:
        rest = n - first
        buf[:rest, 0] += sig[first:] * l
        buf[:rest, 1] += sig[first:] * r


def reverb(buf, mix=0.25):
    """A few feedback delays for a sense of space."""
    out = buf.copy()
    for delay, gain in [(0.031, 0.5), (0.047, 0.42), (0.071, 0.35), (0.113, 0.28), (0.167, 0.2)]:
        d = int(delay * SR)
        wet = np.roll(buf, d, axis=0) * gain
        wet[:, [0, 1]] = wet[:, [1, 0]]
        out += wet * mix
    return out


def plaza():
    bpm, beats = 76, 4
    bar = 60 / bpm * beats
    # D major: D - Bm - G - A, then D - F#m - G - A
    prog = [[50, 57, 62, 66], [47, 54, 62, 66], [43, 55, 59, 62], [45, 57, 61, 64],
            [50, 57, 62, 66], [42, 54, 61, 66], [43, 55, 59, 62], [45, 57, 61, 64]]
    total = bar * len(prog)
    buf = np.zeros((int(total * SR), 2))
    beat = 60 / bpm
    for b, chord in enumerate(prog):
        t0 = b * bar
        place(buf, pad(chord[1:], bar + 0.9) * 0.22, t0, 0.0)
        place(buf, harp(chord[0] - 12, 3.0, 0.5), t0, -0.1)
        # harp arpeggio in eighths
        arp = [chord[1], chord[2], chord[3], chord[2] + 12, chord[3], chord[2], chord[1] + 12, chord[2]]
        for k, m in enumerate(arp):
            place(buf, harp(m + 12, 2.2, 0.32 if k % 2 == 0 else 0.24), t0 + k * beat / 2, 0.35)
    melody = [(74, 0, 2), (76, 2, 1), (78, 3, 1), (79, 4, 3), (78, 7, 1), (76, 8, 2), (74, 10, 2), (73, 12, 4),
              (74, 16, 2), (78, 18, 2), (81, 20, 3), (79, 23, 1), (78, 24, 2), (76, 26, 1), (74, 27, 1), (76, 28, 4)]
    for m, start, length in melody:
        place(buf, flute(m, length * beat + 0.15, 0.3), start * beat, -0.25)
    for b in (0, 4):
        place(buf, bell(86, 3.0, 0.12), b * bar, 0.5)
    return reverb(buf, 0.35)


def scar():
    bpm = 116
    beat = 60 / bpm
    bar = beat * 4
    # D minor: Dm - Bb - C - Am, twice with a darker turn
    prog = [(38, [50, 53, 57]), (34, [46, 50, 53]), (36, [48, 52, 55]), (33, [45, 48, 52]),
            (38, [50, 53, 57]), (34, [46, 50, 53]), (31, [43, 46, 50]), (33, [45, 49, 52])]
    total = bar * len(prog)
    buf = np.zeros((int(total * SR), 2))
    for b, (root, chord) in enumerate(prog):
        t0 = b * bar
        place(buf, choir([m + 12 for m in chord], bar + 1.0) * 0.18, t0, 0.0)
        # driving low strings in eighths
        for k in range(8):
            m = root + (12 if k in (2, 6) else 0)
            place(buf, strings(m, beat / 2 * 0.95, 0.3 if k % 2 == 0 else 0.22), t0 + k * beat / 2, -0.2)
        # war drums: big hits on 1 and 3, smaller on the "and" of 4
        place(buf, drum(0.9, 50, 0.9, 0.6), t0, 0.0)
        place(buf, drum(0.9, 50, 0.75, 0.6), t0 + 2 * beat, 0.0)
        place(buf, drum(0.4, 90, 0.4, 0.8), t0 + 3.5 * beat, 0.3)
        place(buf, drum(0.4, 110, 0.35, 0.8), t0 + 3.75 * beat, -0.3)
        if b % 2 == 1:
            place(buf, bell(chord[2] + 24, 2.0, 0.1), t0 + 1.5 * beat, 0.5)
    return reverb(buf, 0.22)


def write_ogg(folder, name, buf, peak=0.8):
    buf = buf / (np.max(np.abs(buf)) or 1.0) * peak
    data = (np.clip(buf, -1, 1) * 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + ".wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(data.tobytes())
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5",
                        os.path.join(folder, name + ".ogg")], check=True)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/music"
    os.makedirs(out, exist_ok=True)
    write_ogg(out, "plaza", plaza())
    write_ogg(out, "scar", scar())
    print("done")
