# DMA e HDMA

8 canais (0-7), cada um com 16 registradores em `$43x0-$43xF` (x = canal). O mesmo canal serve para DMA geral ou HDMA, nunca os dois ao mesmo tempo [fullsnes] [SNESdev wiki: DMA registers].

O DMA liga o **A-bus** (endereço de 24 bits: ROM, WRAM, SRAM) ao **B-bus** (`$21xx`: PPU, APU, porta da WRAM).

## Registradores do canal

| Reg. | Nome | Bits / função |
|---|---|---|
| $43x0 | DMAPx | bit7: direção (0 = A para B, 1 = B para A); bit6: HDMA indireto; bits 4-3: passo do endereço A (0 incrementa, 2 decrementa, 1 e 3 fixo); bits 2-0: padrão de transferência |
| $43x1 | BBADx | Endereço B: o byte baixo de `$21xx` |
| $43x2/3 | A1TxL/H | Endereço A (16 bits); no HDMA, início da tabela |
| $43x4 | A1Bx | Banco do endereço A; o endereço não atravessa o banco (dá a volta dentro dele) |
| $43x5/6 | DASxL/H | DMA: contagem de bytes (0 = 65536; termina em 0). HDMA indireto: endereço atual dos dados |
| $43x7 | DASBx | HDMA indireto: banco dos dados |
| $43x8/9 | A2AxL/H | HDMA: posição atual na tabela (o hardware atualiza) |
| $43xA | NLTRx | HDMA: bit7 = repetir; bits 6-0 = linhas restantes (o hardware atualiza) |
| $43xB, $43xF | - | Byte livre de leitura e escrita, sem efeito |

Padrões (bits 2-0 de DMAP), em offsets somados a BBAD [fullsnes] [SNESdev wiki]:

| Valor | Sequência no B-bus | Uso típico |
|---|---|---|
| 0 | +0 | CGRAM ($22), OAM ($04), WRAM ($80) |
| 1 | +0, +1 | VRAM ($18/$19, word por vez) |
| 2 | +0, +0 | Registradores de escrita dupla (scroll, M7) |
| 3 | +0, +0, +1, +1 | Dois registradores de escrita dupla (par de scroll) |
| 4 | +0, +1, +2, +3 | Quatro registradores (janelas WH0-WH3) |
| 5 | +0, +1, +0, +1 | Pouco usado |
| 6 | igual ao 2 | |
| 7 | igual ao 3 | |

## DMA geral

1. Configurar `$43x0`-`$43x6`.
2. Escrever o bit do canal em `MDMAEN` ($420B). A CPU para até todos os canais marcados terminarem, em ordem do 0 ao 7.

Custo: 8 master clocks por byte, mais 8 por canal e cerca de 8 de entrada, com 2-8 clocks de alinhamento [SNESdev wiki: DMA registers] [anomie timing]. Isso dá cerca de 2,68 MB/s, independente de FastROM.

Quanto cabe no vblank (bytes de DMA, tela inteira em vblank) [SNESdev wiki: Timing]:

| Sistema / linhas visíveis | Linhas de vblank | Bytes aproximados |
|---|---|---|
| NTSC, 224 | 37 | ~6100 |
| NTSC, 239 | 22 | ~3600 |
| PAL, 224 | 87 | ~14400 |
| PAL, 239 | 72 | ~11900 |

Esses números já descontam o refresh da DRAM, mas não o tempo do seu próprio handler de NMI nem do auto-joypad.

## HDMA

Transfere de 1 a 4 bytes por linha, no hblank, para registradores do PPU. Base de todo efeito por linha: gradiente de cor, ondulação de scroll, janela curva, perspectiva do Mode 7.

1. Configurar `$43x0` (direção 0, modo indireto ou não, padrão), `$43x1` (registrador alvo), `$43x2-$43x4` (tabela) e, no indireto, `$43x7` (banco dos dados).
2. Escrever os bits em `HDMAEN` ($420C), de preferência durante o vblank. O HDMA reinicia sozinho a cada quadro (recarga em V = 0) até ser desligado.

Formato da tabela [fullsnes] [SNESdev wiki]:

- Cada entrada começa com um byte de contagem.
  - `$00`: fim da tabela até o próximo quadro.
  - `$01-$80`: escreve o dado **uma vez** e espera essa quantidade de linhas.
  - `$81-$FF`: escreve um dado novo **a cada linha** durante `contagem - $80` linhas (modo repeat).
- Modo direto: depois da contagem vêm os bytes do padrão (1, 2 ou 4), ou, no modo repeat, um bloco por linha.
- Modo indireto: depois da contagem vem um ponteiro de 2 bytes para os dados (no banco de `$43x7`).
- A contagem $80 em modo não repeat vale 128 linhas; para mais linhas, divida em entradas.

Custo [anomie timing, via superfamicom.org]: no começo do quadro, cerca de 18 clocks mais 8 por canal direto ou 24 por indireto; por linha, cerca de 18 clocks mais 8 por canal ativo e 8 por byte transferido, e mais 16 quando um canal indireto carrega novo ponteiro. São valores **aproximados**.

## Prioridade e convivência

- HDMA tem prioridade sobre o DMA geral: se o HDMA precisa rodar no meio de um DMA, o DMA pausa e continua depois [fullsnes] [SNESdev wiki].
- HDMA roda até em force blank.
- O A-bus do DMA não alcança `$2100-$21FF`, `$4000-$41FF`, `$4200-$421F` nem `$4300-$437F`: não dá para usar DMA de A para A nesses registradores [fullsnes].
- DMA de WRAM para WRAM pela porta `$2180` não funciona [fullsnes] [SNESdev wiki].

## Bugs conhecidos de revisão do chip

Fontes: [fullsnes] [SNESdev wiki: DMA registers].

- Em algumas revisões do 5A22, um DMA que termina exatamente quando o HDMA começa pode travar o console. Contorno: não deixar DMA geral rodando perto do hblank com HDMA ativo, ou fazer o DMA só no vblank.
- BBAD = `$00` com padrões de mais de um registrador falha em algumas revisões; o contorno citado é usar `$FF` com padrão 1 para alcançar $21FF e $2100.
- No 5A22 versão 2, HDMA escrevendo em `INIDISP` ($2100) pode fazer um DMA geral simultâneo falhar.
- Ligar um canal de HDMA no meio do quadro exige inicializar `$43x8-$43xA` à mão, e o comportamento completo **não é totalmente conhecido**; esta skill não cobre esse caso.

## Armadilhas

- Esquecer que DAS = 0 significa 64K: um DMA com contagem zerada sobrescreve a VRAM inteira.
- Reusar um canal de HDMA ativo para DMA geral no vblank corrompe a tabela daquele quadro. Reserve canais: por exemplo 0-1 para DMA e 2-7 para HDMA.
- A tabela de HDMA tem de estar num banco alcançável e terminar em `$00`.
