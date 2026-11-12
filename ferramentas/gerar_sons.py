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
    # Fim de jogo: duas notas descendo.
    salvar("fim.wav", juntar(nota(523.25, 0.5, 0.5, 5), nota(392, 0.7, 0.5, 4), atraso=0.22))


if __name__ == "__main__":
    main()
