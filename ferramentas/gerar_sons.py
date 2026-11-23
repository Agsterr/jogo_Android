"""Gera os efeitos sonoros do Encaixa (sintetizados, sem licença de terceiros).

Uso: python3 ferramentas/gerar_sons.py   (grava em app/assets/sons/)
"""
import math
import random
import struct
import wave
from pathlib import Path

TAXA = 44100
PASTA = Path(__file__).resolve().parent.parent / "app" / "assets" / "sons"


def nota(freq, dur, volume=0.5, decaimento=8.0, harmonicos=(1.0, 0.3, 0.1)):
    """Tom com harmônicos e queda exponencial (som de "plim" macio)."""
    n = int(TAXA * dur)
    out = []
    for i in range(n):
        t = i / TAXA
        env = math.exp(-decaimento * t) * min(1.0, i / (TAXA * 0.004))  # ataque de 4 ms sem estalo
        s = sum(a * math.sin(2 * math.pi * freq * (h + 1) * t) for h, a in enumerate(harmonicos))
        out.append(volume * env * s / sum(harmonicos))
    return out


def juntar(*partes, atraso=0.0):
    """Soma as partes, cada uma começando [atraso] segundos depois da anterior."""
    total = max(int(i * atraso * TAXA) + len(p) for i, p in enumerate(partes))
    out = [0.0] * total
    for i, p in enumerate(partes):
        ini = int(i * atraso * TAXA)
        for j, v in enumerate(p):
            out[ini + j] += v
    return out


def salvar(nome, amostras):
    pico = max(1e-9, max(abs(v) for v in amostras))
    escala = 0.9 / pico  # normaliza: todos com o mesmo pico
    with wave.open(str(PASTA / nome), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(b"".join(struct.pack("<h", int(v * escala * 32767)) for v in amostras))


def musica():
    """Música de fundo (loop de 24 s, mono 22 kHz): pad suave em Lá menor, Fá, Dó, Sol e um arpejo leve por cima.

    Cada acorde sobe e desce devagar, então o fim do arquivo encosta no começo sem estalo (dá para repetir sem emenda).
    """
    taxa = 22050
    acordes = [  # (notas do acorde em Hz, notas do arpejo em Hz)
        ((220.0, 261.63, 329.63), (440.0, 523.25, 659.25, 523.25)),  # Lá menor
        ((174.61, 220.0, 261.63), (349.23, 440.0, 523.25, 440.0)),  # Fá
        ((196.0, 261.63, 329.63), (392.0, 523.25, 659.25, 523.25)),  # Dó
        ((196.0, 246.94, 293.66), (392.0, 493.88, 587.33, 493.88)),  # Sol
    ]
    dur = 6.0  # segundos por acorde
    n = int(taxa * dur * len(acordes))
    out = [0.0] * n
    for k, (pad, arp) in enumerate(acordes):
        ini = int(k * dur * taxa)
        for i in range(int(dur * taxa)):
            t = i / taxa
            # sobe e desce suave; no último acorde o fim volta a zero, como o começo do primeiro
            env = math.sin(math.pi * min(1.0, t / dur)) ** 0.7
            v = sum(math.sin(2 * math.pi * f * t) + 0.35 * math.sin(2 * math.pi * f * 2 * t) for f in pad)
            v *= 0.12 * env * (0.85 + 0.15 * math.sin(2 * math.pi * 0.25 * t))  # leve ondulação
            out[(ini + i) % n] += v
        for j in range(12):  # arpejo: uma nota a cada 0,5 s
            f = arp[j % len(arp)]
            ini_nota = ini + int(j * 0.5 * taxa)
            for i in range(int(0.9 * taxa)):
                t = i / taxa
                out[(ini_nota + i) % n] += 0.07 * math.exp(-4.5 * t) * min(1.0, i / (taxa * 0.01)) * math.sin(2 * math.pi * f * t)
    pico = max(1e-9, max(abs(v) for v in out))
    with wave.open(str(PASTA / "musica.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(taxa)
        w.writeframes(b"".join(struct.pack("<h", int(v / pico * 0.8 * 32767)) for v in out))


def main():
    PASTA.mkdir(parents=True, exist_ok=True)
    random.seed(1)
    # Encaixe: "toc" curto de madeira (tom grave + um pouco de ruído).
    toc = nota(330, 0.09, 0.6, 45, (1.0, 0.5, 0.2))
    ruido = [random.uniform(-1, 1) * 0.15 * math.exp(-80 * i / TAXA) for i in range(len(toc))]
    salvar("encaixe.wav", [a + b for a, b in zip(toc, ruido)])
    # Linha limpa: acorde brilhante.
    salvar("linha.wav", juntar(nota(880, 0.35), nota(1318.5, 0.35, 0.35), atraso=0.03))
    # Combo: arpejo subindo (dó-mi-sol-dó).
    salvar("combo.wav", juntar(*(nota(f, 0.3, 0.45, 10) for f in (1046.5, 1318.5, 1568, 2093)), atraso=0.06))
    # Incrível: arpejo rápido de cinco notas, uma oitava acima do combo (mais brilhante).
    salvar(
        "incrivel.wav",
        juntar(*(nota(f, 0.32, 0.45, 9) for f in (1318.5, 1568, 1975.5, 2349.3, 2637)), atraso=0.05),
    )
    # Fantástico: acorde cheio com brilho subindo (escala de dó maior até o agudo) e uma nota grave no começo.
    brilho = juntar(*(nota(f, 0.28, 0.35, 11) for f in (1046.5, 1318.5, 1568, 1975.5, 2093, 2637, 3136)), atraso=0.045)
    base = nota(523.25, 0.7, 0.4, 5)
    salvar("fantastico.wav", [(brilho[i] if i < len(brilho) else 0) + (base[i] if i < len(base) else 0) for i in range(len(brilho))])
    # Fim de jogo: duas notas descendo.
    salvar("fim.wav", juntar(nota(523.25, 0.5, 0.5, 5), nota(392, 0.7, 0.5, 4), atraso=0.22))
    musica()


if __name__ == "__main__":
    main()
