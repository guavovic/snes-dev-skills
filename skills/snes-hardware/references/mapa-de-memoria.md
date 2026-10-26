# Mapa de memória do SNES

Endereços em 24 bits (`BB:AAAA`, banco e endereço). Velocidade em master clocks por acesso: 6 = 3.58 MHz, 8 = 2.68 MHz, 12 = 1.79 MHz. Fontes: [fullsnes], [SNESdev wiki: Memory map], [anomie memmap].

## Visão por banco

| Bancos | Endereço | Conteúdo | Clocks |
|---|---|---|---|
| 00-3F, 80-BF | 0000-1FFF | Espelho dos primeiros 8K da WRAM (7E:0000-1FFF) | 8 |
| 00-3F, 80-BF | 2000-20FF | Sem uso (open bus) | 6 |
| 00-3F, 80-BF | 2100-21FF | B-bus: PPU, APU, WRAM port | 6 |
| 00-3F, 80-BF | 2200-3FFF | Sem uso, ou chip do cartucho (SA-1, GSU) | 6 |
| 00-3F, 80-BF | 4000-41FF | Joypad manual ($4016/$4017) | 12 |
| 00-3F, 80-BF | 4200-5FFF | Registradores da CPU ($42xx, $43xx) | 6 |
| 00-3F, 80-BF | 6000-7FFF | Expansão (SRAM no HiROM, DSP-n etc.) | 8 |
| 00-3F | 8000-FFFF | ROM (WS1) | 8 |
| 40-7D | 0000-FFFF | ROM (WS1, área HiROM) | 8 |
| 7E-7F | 0000-FFFF | WRAM, 128K | 8 |
| 80-BF | 8000-FFFF | ROM (WS2) | 6 ou 8 |
| C0-FF | 0000-FFFF | ROM (WS2, área HiROM) | 6 ou 8 |

- WS2 roda a 6 clocks só com `MEMSEL` ($420D) bit0 = 1 e cartucho FastROM (ROM de 120 ns). Com bit0 = 0 vale 8 [fullsnes] [SNESdev wiki].
- Divergência: o [anomie memmap] trata 4200-43FF como registradores e 4400-5FFF como área rápida livre; o [fullsnes] dá 4200-5FFF inteiro como 6 clocks. A velocidade é a mesma, muda só o nome da faixa.
- Divergência: o [anomie memmap] (v1.1, 2003) diz que FastROM é o bit 1 de $420D. [fullsnes], [SNESdev wiki] e o código do bsnes (`sfc/cpu/io.cpp`, `fastROM = data & 1`) dizem bit 0. **Vale o bit 0.**

## Memórias fora do barramento da CPU

Só se alcançam por porta de registrador [fullsnes]:

| Memória | Tamanho | Porta |
|---|---|---|
| VRAM | 64K (32K words) | $2116-$2119, leitura $2139/$213A |
| OAM | 544 bytes | $2102-$2104, leitura $2138 |
| CGRAM | 512 bytes (256 cores) | $2121-$2122, leitura $213B |
| Sound RAM (ARAM) | 64K | só pelo SPC700; a CPU fala pelas portas $2140-$2143 |
| Boot ROM do SPC700 (IPL) | 64 bytes | interna ao SPC700 |

A WRAM também tem porta própria no B-bus: `WMDATA` $2180 e endereço de 17 bits em `WMADD` $2181-$2183. É por ela que o DMA preenche a WRAM a partir da ROM. DMA de WRAM para WRAM não funciona [fullsnes] [SNESdev wiki].

## LoROM ("Mode 20")

- A ROM aparece em blocos de 32K na metade alta (8000-FFFF) dos bancos 00-7D e 80-FF. A linha A15 do SNES fica desligada; A16-A22 do SNES vão para A15-A21 da ROM [SNESdev wiki].
- Offset de arquivo para endereço: `banco = offset / $8000`, `endereço = $8000 + offset % $8000` (somar $80 no banco para a área FastROM).
- Header interno em offset de arquivo $007FC0 (aparece em 00:FFC0).
- Tamanho: o [fullsnes] descreve o LoROM comum como até 2MB em 00-3F com espelho em 80-BF; o [SNESdev wiki] fala em até 4 MiB. Não é divergência: o 4 MiB é o arranjo estendido (o fullsnes chama de BigLoROM/SpecialLoROM) que usa também 40-7D.
- SRAM: 70-7D/F0-FF. Placas antigas mapeiam o banco de 64K inteiro, as novas só 0000-7FFF; usar 70:0000-7FFF funciona nas duas. SRAM de 64K ou 128K se divide em blocos de 32K a partir do banco 70 [fullsnes] [SNESdev wiki].

## HiROM ("Mode 21")

- ROM linear em blocos de 64K em C0-FF (e 40-7D). A metade alta de cada banco também aparece em 00-3F/80-BF:8000-FFFF [fullsnes] [SNESdev wiki].
- Header interno em offset $00FFC0 (aparece em 00:FFC0 e C0:FFC0).
- SRAM em 6000-7FFF, mas os bancos variam por placa: a tabela de placas do [fullsnes] dá 20-3F/A0-BF na maioria e 10-1F/30-3F/90-9F/B0-BF em outras; o [SNESdev wiki] cita 30-3F/B0-BF. Usar 30-3F (ou B0-BF) funciona nos dois casos, e emuladores seguem esse arranjo.
- Vantagem: dado de 64K contínuo sem quebrar em 32K. Os vetores continuam em 00:FFxx, que é o fim do primeiro banco de 64K.

## ExHiROM ("Mode 25")

- Até 8MB. 80-FF mapeiam os primeiros 4MB como HiROM; 00-7D mapeiam os 4MB seguintes (menos 64K, que caem em 7E-7F da WRAM). A23 do SNES vai para A22 da ROM invertido [SNESdev wiki].
- Header em offset $40FFC0 [SNESdev wiki] [fullsnes].
- Raro: o [SNESdev wiki] cita só dois jogos que usam. Para projeto novo, prefira LoROM ou HiROM.

## Header interno do cartucho (00:FFC0)

| Endereço | Tamanho | Campo |
|---|---|---|
| FFC0 | 21 | Título, ASCII, completado com espaço |
| FFD5 | 1 | Velocidade e mapa: bit4 = FastROM; bits 3-0: 0 LoROM, 1 HiROM, 2 S-DD1 LoROM, 3 SA-1, 5 ExHiROM, A SPC7110 |
| FFD6 | 1 | Chipset (só ROM, ROM+RAM, ROM+RAM+bateria, coprocessador no nibble alto) |
| FFD7 | 1 | Tamanho da ROM: `1 << n` KB |
| FFD8 | 1 | Tamanho da RAM do cartucho: `1 << n` KB, 0 = sem RAM |
| FFD9 | 1 | País/região (define NTSC ou PAL no emulador) |
| FFDA | 1 | Código do desenvolvedor ($33 = existe header estendido em FFB0-FFBF, com código de 2 letras e tamanho de RAM de expansão) |
| FFDB | 1 | Versão |
| FFDC | 2 | Complemento do checksum |
| FFDE | 2 | Checksum (soma de todos os bytes da ROM, 16 bits) |
| FFE0 | 32 | Vetores (ver abaixo) |

Fontes: [fullsnes: ROM header]; os offsets do header por mapa ($7FC0, $FFC0, $40FFC0) também em [SNESdev wiki: Memory map]. Checksum + complemento tem de dar $FFFF. Como emuladores e copiadores leem o header para deduzir o mapa, deixe o byte FFD5 coerente com o mapa real.

## Vetores de interrupção

O banco do vetor é sempre 00 e o reset sempre entra em modo emulação [fullsnes] [SNESdev wiki: CPU vectors] [WDC datasheet].

| Vetor | Modo nativo | Modo emulação |
|---|---|---|
| COP | FFE4 | FFF4 |
| BRK | FFE6 | (divide com IRQ) FFFE |
| ABORT | FFE8 | FFF8 |
| NMI | FFEA | FFFA |
| RESET | - | FFFC |
| IRQ | FFEE | FFFE |

ABORT não tem fonte de sinal no SNES [fullsnes]. Os handlers precisam estar no banco 00 (ou em um banco que espelha a ROM em 00:8000-FFFF).

## Chips especiais do cartucho (visão geral)

Detalhe fica fora desta skill. Contagens de jogo segundo o [fullsnes].

| Chip | O que é | Onde aparece |
|---|---|---|
| SA-1 | Segundo 65C816 a ~10.74 MHz, com DMA, multiplicador e mapeador próprios | I/O em $2200-$230E, I-RAM em 00-3F:3000-37FF; mapeia a ROM em blocos de 1MB; cerca de 35 jogos |
| GSU (SuperFX) | Processador RISC para polígonos e escala, desenha num framebuffer de RAM que a CPU copia por DMA | I/O em $3000-$32FF; cerca de 10 jogos |
| DSP-n (NEC uPD77C25) | DSP de ponto fixo para matemática (DSP-1 faz projeção e rotação) | 6000-7FFF no HiROM, bancos altos em LoROM; cerca de 23 jogos |
| CX4, S-DD1, SPC7110, OBC1, ST010/011/018, S-RTC | Coprocessadores, descompressores e relógio | Poucos jogos cada |

SA-1 e GSU podem gerar IRQ para a CPU principal pelo pino de IRQ do cartucho [fullsnes].

## Truques úteis

- Os registradores $43x0-$43xA de canais de DMA sem uso funcionam como RAM rápida (6 clocks) [fullsnes].
- Código em WRAM roda a 8 clocks por acesso; código em ROM FastROM roda a 6. Para laço crítico, FastROM é mais rápido que WRAM [fullsnes].
