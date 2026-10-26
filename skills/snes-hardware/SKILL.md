---
name: snes-hardware
description: Referência do hardware do Super Nintendo (SNES / Super Famicom) para programar em assembly 65816 ou depurar ROM. Use quando a tarefa envolver mapa de memória (LoROM, HiROM, ExHiROM, SRAM, header do cartucho, vetores), a CPU 5A22 e os registradores $42xx (NMITIMEN, MEMSEL, multiplicação e divisão), o PPU e os registradores $21xx (modos 0 a 7, BGs, tiles, tilemap, OAM e sprites, VRAM, CGRAM e paleta, scroll, janelas, color math, mosaico, Mode 7), DMA e HDMA ($43xx, tabelas de HDMA, quanto cabe no vblank), NMI, IRQ de H/V e timing de quadro (NTSC e PAL, vblank, hblank, ciclos por linha, FastROM e SlowROM), leitura de controle com auto-joypad ($4218) ou a comunicação com o APU (SPC700, DSP, portas $2140-$2143, upload pela IPL). Também serve para perguntas como "qual bit liga o force blank", "por que minha escrita na VRAM sumiu", "quanto DMA cabe no vblank" ou "como faço um gradiente com HDMA".
---

# snes-hardware

Mapa do hardware do SNES para quem escreve código 65816. Este arquivo dá a visão geral, as regras que mais evitam bug e o índice; as tabelas completas de registradores, com o que cada bit faz e quando pode ser escrito, ficam em `references/`.

Toda afirmação técnica dos references tem fonte entre colchetes (`[fullsnes]`, `[SNESdev wiki]`...), listadas em [references/fontes.md](references/fontes.md) com as divergências encontradas.

## Visão geral

- **CPU:** Ricoh 5A22, núcleo 65C816 (A, X, Y de 8 ou 16 bits, endereço de 24 bits) com DMA, multiplicador, divisor, timer de H/V e auto-joypad embutidos. Acesso de memória a 6, 8 ou 12 master clocks (3,58 / 2,68 / 1,79 MHz) conforme a região.
- **Memória:** 128K de WRAM em $7E-$7F (os primeiros 8K espelhados em $0000-$1FFF dos bancos baixos), ROM do cartucho em LoROM ou HiROM, SRAM opcional.
- **PPU:** dois chips que formam a imagem a partir de VRAM (64K), OAM (544 bytes) e CGRAM (512 bytes). Nenhuma dessas memórias está no barramento da CPU: só por porta ($2104, $2118, $2122) ou DMA.
- **DMA/HDMA:** 8 canais. DMA geral para a CPU e copia blocos; HDMA escreve de 1 a 4 bytes por linha no hblank.
- **APU:** SPC700 + DSP com 64K de RAM própria, relógio próprio e só 4 portas de comunicação ($2140-$2143).
- **Quadro:** NTSC 262 linhas a ~60 Hz, PAL 312 a ~50 Hz; 224 (ou 239) linhas visíveis; o resto é vblank, a janela para mexer em VRAM, OAM e CGRAM.

## Regras de ouro

1. **VRAM, OAM e CGRAM só se escrevem em vblank ou force blank.** Fora disso a escrita na VRAM é ignorada, mas o endereço avança, e o resto do upload sai deslocado.
2. **Force blank é `$8F` em $2100, não `$80`.** Sai com `$0F`. Mudar o force blank no meio da tela pode corromper sprites.
3. **Faça o trabalho pesado do vblank com DMA.** No NTSC de 224 linhas cabem cerca de 6 KB por quadro; planeje o que sobe em cada quadro.
4. **Reconheça as interrupções:** leia `$4210` na NMI e `$4211` na IRQ. Sem ler $4211 a IRQ entra de novo.
5. **Endereços da VRAM são em words.** Bases de tilemap andam de 1K words, de tiles de BG de 4K words, de tiles de OBJ de 8K words.
6. **Registradores de escrita dupla** (scroll, Mode 7, CGDATA, OAMDATA): byte baixo e depois alto, sem intercalar outro registrador que use o mesmo latch.
7. **Controle:** espere `$4212` bit0 = 0 antes de ler `$4218`.
8. **Reset começa em modo emulação, banco 00,** com A, X, Y e S parcialmente indefinidos. Inicialize tudo; não confie em zero.
9. **Mesmo canal não serve a DMA e HDMA ao mesmo tempo.** Reserve canais para cada uso.
10. **FastROM só vale com $420D bit0 = 1, ROM rápida e código rodando nos bancos $80+.**

## Armadilhas frequentes

| Sintoma | Causa provável | Ver |
|---|---|---|
| Gráfico some ou aparece deslocado | Escrita na VRAM fora do vblank, ou endereço em bytes em vez de words | [ppu-registradores.md](references/ppu-registradores.md) |
| VRAM inteira apagada | DMA com contagem 0 (vale 64K) | [dma-hdma.md](references/dma-hdma.md) |
| Leitura da VRAM devolve valor anterior | Prefetch de $2139: regrave VMADD antes de ler | [ppu-registradores.md](references/ppu-registradores.md) |
| Sprites piscando ou faltando | Mais de 32 OBJs ou 34 tiles na linha (STAT77) | [ppu-formatos.md](references/ppu-formatos.md) |
| OBJ aparece no topo da tela | OBJ alto com Y perto do fim dá a volta | [ppu-formatos.md](references/ppu-formatos.md) |
| Travamento em IRQ | Handler não lê $4211 | [interrupcoes-e-timing.md](references/interrupcoes-e-timing.md) |
| Controle com leitura errada | Leu $4218 com o auto-joypad em andamento | [controles.md](references/controles.md) |
| Multiplicação com resultado parcial | Leu $4216 antes de 8 ciclos (16 na divisão) | [cpu-5a22.md](references/cpu-5a22.md) |
| Upload para o SPC700 trava | NMI/IRQ durante o upload perdeu o eco | [apu.md](references/apu.md) |
| Glitch ao escrever $2100 | Bug do INIDISP; escrever com endereço longo | [ppu-registradores.md](references/ppu-registradores.md) |
| Cor errada em sprite semitransparente | Só OBJs com paleta 4-7 entram no color math | [ppu-formatos.md](references/ppu-formatos.md) |
| ROM roda lenta mesmo marcada FastROM | Código rodando no banco 00 ou $420D zerado | [interrupcoes-e-timing.md](references/interrupcoes-e-timing.md) |

## Índice dos references

| Arquivo | Conteúdo |
|---|---|
| [mapa-de-memoria.md](references/mapa-de-memoria.md) | Bancos e velocidades, LoROM, HiROM, ExHiROM, SRAM, header do cartucho, vetores, chips especiais (visão geral) |
| [cpu-5a22.md](references/cpu-5a22.md) | Núcleo 65C816 em resumo, estado no reset, tabela $4016-$421F, porta da WRAM, matemática |
| [ppu-registradores.md](references/ppu-registradores.md) | Tabela completa $2100-$213F com bits e quando escrever, fórmula do Mode 7, armadilhas do PPU |
| [ppu-formatos.md](references/ppu-formatos.md) | Modos de BG, formato de tile, tilemap, Mode 7 na VRAM, OAM, limites por linha, CGRAM, prioridade entre camadas |
| [dma-hdma.md](references/dma-hdma.md) | Registradores $43x0-$43xF, padrões, DMA geral, orçamento do vblank, tabela de HDMA, custos e bugs |
| [interrupcoes-e-timing.md](references/interrupcoes-e-timing.md) | Relógios, linha do tempo do quadro, NMI, IRQ de H/V, FastROM e SlowROM |
| [controles.md](references/controles.md) | Auto-joypad, formato de JOYn, leitura manual |
| [apu.md](references/apu.md) | SPC700, DSP, mapa da ARAM, portas $2140-$2143, protocolo de upload da IPL |
| [exemplos.md](references/exemplos.md) | Esqueleto LoROM em asar (init, DMA, NMI, controle) e tabela de HDMA |
| [fontes.md](references/fontes.md) | Fontes com URL, autor, ano e confiança; divergências; o que ficou não confirmado |

## Fora do escopo

Detalhe dos chips de cartucho (SA-1, SuperFX, DSP-n), programação do driver de som no SPC700, formato BRR em detalhe, offset-per-tile em detalhe e HDMA ligado no meio do quadro. O que não tem fonte confirmada está listado em [fontes.md](references/fontes.md).
