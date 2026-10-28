"""
CarbonLife 演示片配乐（原创合成，CC0 级别的"自己写的"）。

为什么自己合成而不是找现成曲子：
- 参赛材料最怕版权争议，自制 = 零风险；
- 剪辑是 120 BPM 的拍点，自己生成可以精确对齐，不用拉伸别人的曲子。

编制（刻意做得克制，像产品片而不是 EDM）：
- 和弦垫：A 小调 Am - F - C - G，低通锯齿，慢起音
- 低音：根音八分音符，正弦
- 底鼓：每小节 1、3 拍，低频正弦扫频，音量压得很低，只提供脉搏
- 琶音：三角波十六分，轻，带延迟
- 母带：tanh 软限幅 + 首尾淡入淡出

用法：python gen_music.py [秒数] [输出文件]
"""
import sys
import wave

import numpy as np

SR = 44100
BPM = 120
BEAT = 60.0 / BPM          # 0.5s


def note_hz(semitones_from_a4: float) -> float:
    return 440.0 * (2.0 ** (semitones_from_a4 / 12.0))


def adsr(n: int, a: float, d: float, s: float, r: float, sr: int = SR) -> np.ndarray:
    a_n, d_n, r_n = int(a * sr), int(d * sr), int(r * sr)
    s_n = max(0, n - a_n - d_n - r_n)
    env = np.concatenate([
        np.linspace(0, 1, a_n, endpoint=False) if a_n else np.array([]),
        np.linspace(1, s, d_n, endpoint=False) if d_n else np.array([]),
        np.full(s_n, s),
        np.linspace(s, 0, r_n) if r_n else np.array([]),
    ])
    if env.size < n:
        env = np.pad(env, (0, n - env.size))
    return env[:n]


def lowpass(x: np.ndarray, cutoff: float, sr: int = SR) -> np.ndarray:
    """一阶低通；cutoff 可以随样本变化。"""
    cutoff = np.asarray(cutoff, dtype=np.float64)
    if cutoff.ndim == 0:
        cutoff = np.full_like(x, float(cutoff))
    a = np.exp(-2.0 * np.pi * cutoff / sr)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc = (1 - a[i]) * x[i] + a[i] * acc
        y[i] = acc
    return y


def saw(freq: float, n: int, detune: float = 0.0) -> np.ndarray:
    t = np.arange(n) / SR
    f = freq * (1.0 + detune)
    phase = (t * f) % 1.0
    return 2.0 * phase - 1.0


def tri(freq: float, n: int) -> np.ndarray:
    t = np.arange(n) / SR
    phase = (t * freq) % 1.0
    return 4.0 * np.abs(phase - 0.5) - 1.0


def kick(n: int, sr: int = SR) -> np.ndarray:
    t = np.arange(n) / sr
    f = 110.0 * np.exp(-t * 28.0) + 42.0
    phase = 2 * np.pi * np.cumsum(f) / sr
    body = np.sin(phase) * np.exp(-t * 9.0)
    click = np.random.default_rng(3).normal(0, 1, n) * np.exp(-t * 220.0) * 0.25
    return body + click


def hat(n: int, rng: np.random.Generator, sr: int = SR) -> np.ndarray:
    t = np.arange(n) / sr
    noise = rng.normal(0, 1, n)
    # 简易高通：一阶差分
    noise = np.diff(np.concatenate([[0.0], noise]))
    return noise * np.exp(-t * 55.0)


def build(seconds: float = 52.0) -> np.ndarray:
    n = int(seconds * SR)
    out = np.zeros((n, 2), dtype=np.float64)

    # Am - F - C - G，每个和弦 2 小节（4 秒）
    chords = [
        ([-12, -9, -5], -24),    # Am: A3 C4 E4 / bass A2
        ([-16, -12, -9], -28),   # F : F3 A3 C4 / bass F2
        ([-9, -5, -2], -21),     # C : C4 E4 G4 / bass C3
        ([-14, -10, -7], -26),   # G : G3 B3 D4 / bass G2
    ]
    bar = 4 * BEAT
    seg = 2 * bar

    rng = np.random.default_rng(7)

    # ---- 和弦垫
    pad = np.zeros(n)
    for i, (ch, _) in enumerate(chords):
        start = int(i * seg * SR)
        length = int(seg * SR)
        if start >= n:
            break
        length = min(length, n - start)
        buf = np.zeros(length)
        for st in ch:
            f = note_hz(st)
            buf += saw(f, length, +0.004) * 0.5
            buf += saw(f, length, -0.004) * 0.5
        env = adsr(length, 0.55, 0.4, 0.85, 0.7)
        pad[start:start + length] += buf * env * 0.22
    # 缓慢打开的低通，让垫子有呼吸
    cutoff = 900 + 700 * np.sin(np.linspace(0, 6 * np.pi, n)) ** 2
    pad = lowpass(pad, cutoff)

    # ---- 低音（八分音符）
    bass = np.zeros(n)
    step = BEAT / 2
    k = 0
    while k * step < seconds:
        i = int(k * step * SR)
        length = min(int(step * SR * 0.95), n - i)
        if length <= 0:
            break
        chord_idx = int((k * step) // seg) % len(chords)
        root = chords[chord_idx][1]
        f = note_hz(root)
        buf = np.sin(2 * np.pi * f * np.arange(length) / SR)
        buf += 0.3 * np.sin(4 * np.pi * f * np.arange(length) / SR)
        env = adsr(length, 0.005, 0.09, 0.55, 0.12)
        bass[i:i + length] += buf * env * 0.30
        k += 1

    # ---- 琶音（十六分，隔一个音省一个，留白）
    arp = np.zeros(n)
    step = BEAT / 4
    k = 0
    while k * step < seconds:
        if k % 2 == 0:
            i = int(k * step * SR)
            length = min(int(step * SR * 0.9), n - i)
            if length > 0:
                chord_idx = int((k * step) // seg) % len(chords)
                ch = chords[chord_idx][0]
                f = note_hz(ch[k % len(ch)] + 12)
                buf = tri(f, length)
                env = adsr(length, 0.004, 0.05, 0.30, 0.10)
                arp[i:i + length] += buf * env * 0.10
        k += 1
    # 简易反馈延迟，制造空间
    d = int(BEAT / 2 * SR)
    arp_d = arp.copy()
    for _ in range(3):
        arp_d[d:] += arp_d[:-d] * 0.32
    arp = arp_d

    # ---- 底鼓（每小节 1、3 拍）
    drums = np.zeros(n)
    b = 0
    while b * BEAT < seconds:
        if b % 4 in (0, 2):
            i = int(b * BEAT * SR)
            ln = min(int(0.35 * SR), n - i)
            if ln > 0:
                drums[i:i + ln] += kick(ln) * 0.30
        b += 1
    # 轻 hi-hat（八分）
    k = 0
    while k * (BEAT / 2) < seconds:
        i = int(k * (BEAT / 2) * SR)
        ln = min(int(0.06 * SR), n - i)
        if ln > 0:
            drums[i:i + ln] += hat(ln, rng) * (0.055 if k % 2 else 0.035)
        k += 1

    mono = pad + bass + arp + drums

    # 轻微立体声：垫子稍宽，低频居中
    out[:, 0] = mono + 0.12 * np.roll(arp, 220)
    out[:, 1] = mono + 0.12 * np.roll(arp, -220)

    # ---- 母带
    fade = int(1.2 * SR)
    out[:fade] *= np.linspace(0, 1, fade)[:, None]
    out[-int(2.0 * SR):] *= np.linspace(1, 0, int(2.0 * SR))[:, None]
    out = np.tanh(out * 1.15)
    peak = np.abs(out).max()
    if peak > 0:
        out *= (10 ** (-1.5 / 20)) / peak
    return out


def main() -> None:
    seconds = float(sys.argv[1]) if len(sys.argv) > 1 else 52.0
    path = sys.argv[2] if len(sys.argv) > 2 else "bed.wav"
    audio = build(seconds)
    pcm = (audio * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    rms = 20 * np.log10(np.sqrt((audio ** 2).mean()) + 1e-9)
    print(f"{path}: {seconds:.1f}s  peak={20*np.log10(np.abs(audio).max()):.1f}dBFS  rms={rms:.1f}dB")


if __name__ == "__main__":
    main()
