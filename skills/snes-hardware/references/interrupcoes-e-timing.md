# Interrupções (NMI e IRQ) e timing de quadro

Fontes: [fullsnes: Timings] [SNESdev wiki: Timing] [anomie timing]. H é medido em dots (1 dot = 4 master clocks), V em linhas.

## Relógios

| Item | NTSC | PAL |
|---|---|---|
| Master clock | 21,47727 MHz | 21,28137 MHz |
| Linhas por quadro | 262 | 312 |
| Linhas visíveis | 224 (ou 239 com overscan) | 224 ou 239 |
| Taxa de quadro | ~60,099 Hz | ~50,007 Hz |

- CPU: cada acesso leva 6, 8 ou 12 master clocks (3,58 / 2,68 / 1,79 MHz), conforme a região do mapa (ver [mapa-de-memoria.md](mapa-de-memoria.md)).
- Linha normal: 1364 master clocks = 340 dots (341 posições, com 4 dots "longos" de 5 clocks).
- Exceções: em NTSC sem interlace, a linha 240 do campo ímpar tem 1360 clocks; em PAL com interlace, a linha 311 do campo ímpar tem 1368 [fullsnes] [SNESdev wiki].
- Refresh da DRAM: a CPU para 40 master clocks por linha, perto de H = 133 [fullsnes] [anomie timing].
- Interlace soma uma linha nos quadros alternados.

## Linha do tempo de um quadro (NTSC, 224 linhas)

| Evento | Posição |
|---|---|
| Recarga dos canais de HDMA | V = 0, H ≈ 6 |
| Linhas visíveis | V = 1 a 224 (imagem entre H ≈ 22 e 277) |
| Flag de hblank ($4212 bit6) liga | H ≈ 274 de cada linha |
| HDMA da linha | H ≈ 278 |
| Início do vblank, flag de NMI e NMI | V = 225, H ≈ 0,5 |
| Recarga de OAMADD | V = 225, H ≈ 10 |
| Início do auto-joypad | V = 225, entre H ≈ 32,5 e 95,5 |
| Fim do auto-joypad | ~4224 master clocks depois (~3 linhas) |
| Fim do vblank | V = 261 (última linha), volta a V = 0 |

Com overscan (239 linhas), o vblank começa em V = 240. Fontes: [fullsnes] [SNESdev wiki] [anomie timing].

## NMI (vblank)

- Ligada por `NMITIMEN` ($4200) bit7. Dispara uma vez por quadro no início do vblank.
- A flag de `RDNMI` ($4210) liga no início do vblank mesmo com a NMI desligada, e zera sozinha no fim do vblank ou na leitura. A CPU dispara a NMI quando `$4200.7 AND $4210.7` passa de 0 para 1: por isso ligar a NMI no meio do vblank dispara na hora, e desligar e religar pode repetir uma NMI velha. Ler $4210 no handler evita isso [fullsnes] [SNESdev wiki].
- Se um DMA geral estiver rodando, a NMI espera ele acabar e pode cair já fora do vblank [fullsnes].
- Vetor nativo em $00:FFEA. O handler precisa salvar e restaurar o que usa (A, X, Y, DBR, D e o estado de M/X).
- Trabalho típico do vblank: DMA de gráficos e OAM, escrita de scroll e registradores, leitura do controle depois do auto-joypad.

## IRQ (timer de H/V)

`NMITIMEN` bits 5-4 [fullsnes] [SNESdev wiki]:

| Valor | Dispara |
|---|---|
| 0 | Nunca |
| 1 | Em toda linha, quando H = HTIME |
| 2 | Uma vez por quadro, em V = VTIME, H ≈ 0 |
| 3 | Uma vez por quadro, em V = VTIME e H = HTIME |

- HTIME em $4207/8, VTIME em $4209/A (9 bits). O disparo real acontece um pouco depois do ponto pedido: H-IRQ em HTIME + ~3,5 dots, V-IRQ em H ≈ 2,5 [fullsnes].
- O handler lê `TIMEUP` ($4211) para reconhecer; sem isso a IRQ fica ativa e entra de novo.
- A IRQ do cartucho (SA-1, GSU) chega pelo mesmo vetor; o handler distingue pela flag de cada fonte.
- `cli` libera a IRQ na CPU; a NMI não depende do flag I.
- Uso típico: trocar de modo ou de registradores numa linha fixa (status bar com outro modo de BG), quando HDMA não basta.

## FastROM e SlowROM

- SlowROM: toda a ROM a 8 clocks por acesso (2,68 MHz).
- FastROM: ROM em 80-BF:8000-FFFF e C0-FF a 6 clocks, só se `MEMSEL` ($420D) bit0 = 1 e o cartucho tiver ROM rápida. O header marca isso em $FFD5 bit4 [fullsnes] [SNESdev wiki].
- Para o código aproveitar, ele precisa rodar nos bancos altos: depois do reset (que começa em banco 00) faça `jml` para o espelho em $80:xxxx.
- Ganho real fica entre 0 e 33%, conforme quanto do tempo o código passa lendo ROM versus WRAM e registradores.

## Orçamento por quadro (ordem de grandeza)

- Quadro NTSC: 262 × 1364 ≈ 357 mil master clocks, menos o refresh (~10 mil). Com acessos de 8 clocks dá algo perto de 43 mil ciclos de memória por quadro; com 6 clocks, cerca de 58 mil. Conta derivada dos números acima, não medição.
- O vblank NTSC de 224 linhas tem 37 linhas: cerca de 6 KB de DMA ou pouco mais de 6 mil acessos de CPU.

## Armadilhas

- Esperar o vblank por polling em $4212 bit7 em vez da NMI é aceitável no boot, mas no jogo use a NMI e uma flag em RAM.
- Ler `$4218-$421F` antes de o auto-joypad terminar ($4212 bit0 = 0) dá valor errado.
- HTIME acima de 339 ou VTIME acima da última linha nunca dispara: a IRQ simplesmente não acontece.
- O H do latch ($213C) vai de 0 a 339; posições em dots não são pixels: o pixel 0 visível fica perto de H = 22.
