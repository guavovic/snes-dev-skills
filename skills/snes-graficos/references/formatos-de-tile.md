# Formatos de tile

Tile = bloco de 8x8 pixels. O valor de cada pixel é um índice de cor (não uma cor), e o índice 0 é transparente em BG e OBJ [fullsnes] [SNESdev wiki: CGRAM]. Em todo formato planar, o bit 7 de cada byte é o pixel da esquerda e o plano 0 é o bit menos significativo do índice [fullsnes] [Mesen2].

Conferência: os formatos de hardware (2bpp, 4bpp, 8bpp e Mode 7) batem em [fullsnes], [SNESdev wiki: Tiles] e no decodificador do Tile Viewer do [Mesen2] (`PpuTools.h`, `GetTilePixelColor`). Isso confirma, numa segunda e terceira fonte, o que a skill `snes-hardware` registrou em `references/ppu-formatos.md` só com o fullsnes.

## Resumo

| Formato | Cores | Bytes por tile | Onde aparece | Fonte |
|---|---|---|---|---|
| 1bpp | 2 | 8 | Só em ROM (fonte de texto, máscara); o jogo expande antes de mandar pra VRAM | [Tile Molester] [Klarth] |
| 2bpp | 4 | 16 | BG no modo 0 (todos), BG3 no modo 1, BG2 nos modos 4 e 5 | [fullsnes] [SNESdev wiki: Tiles] |
| 3bpp | 8 | 24 | Só em ROM; o jogo insere o 4º plano (zerado) e grava como 4bpp | [SNESLab: BGR555] [Tile Molester] |
| 4bpp | 16 | 32 | Todos os OBJs; BG nos modos 1, 2, 3 (BG2), 5 e 6 | [fullsnes] [SNESdev wiki: Tiles] |
| 8bpp | 256 | 64 | BG1 nos modos 3 e 4 | [fullsnes] [SNESdev wiki: Tiles] |
| Mode 7 | 256 | 64 (em 128 bytes de VRAM) | BG do modo 7, 1 byte por pixel | [fullsnes] [SNESdev wiki: Tiles] [Mesen2] |

Qual BG tem quantas cores em cada modo: tabela de modos em `snes-hardware/references/ppu-formatos.md`.

## 2bpp (16 bytes)

Duas linhas de bytes por linha de pixels, intercaladas: plano 0 da linha 0, plano 1 da linha 0, plano 0 da linha 1... Na VRAM isso é 1 word por linha: byte baixo ($2118) = plano 0, byte alto ($2119) = plano 1 [SNESdev wiki: Tiles].

| Byte | Conteúdo |
|---|---|
| $00, $02, ..., $0E | plano 0 das linhas 0 a 7 |
| $01, $03, ..., $0F | plano 1 das linhas 0 a 7 |

Exemplo: plano 0 = `$1D` (00011101), plano 1 = `$55` (01010101) dão os pixels `0 2 0 3 1 3 0 3` [SNESdev wiki: Tiles].

## 4bpp (32 bytes)

Dois tiles 2bpp em sequência [fullsnes] [SNESdev wiki: Tiles] [Mesen2]:

| Bytes | Planos |
|---|---|
| $00-$0F | planos 0 e 1, intercalados como no 2bpp |
| $10-$1F | planos 2 e 3, intercalados |

O pixel (x, y) usa os bytes `2y`, `2y+1`, `2y+16`, `2y+17`, bit `7-x` [Mesen2].

## 8bpp (64 bytes)

Quatro blocos de 2bpp: $00-$0F planos 0-1, $10-$1F planos 2-3, $20-$2F planos 4-5, $30-$3F planos 6-7 [fullsnes] [SNESdev wiki: Tiles] [Mesen2]. Com direct color ($2130 bit 0) o índice vira cor; ver [paletas-e-cor.md](paletas-e-cor.md).

## 3bpp (24 bytes, só em ROM)

Os 16 primeiros bytes são um tile 2bpp (planos 0 e 1 intercalados); os 8 seguintes são o plano 2, 1 byte por linha [SNESLab: BGR555]. O [Tile Molester] descreve o mesmo formato como "3bpp planar, composite (2bpp+1bpp)". O PPU não lê 3bpp: a rotina de carga do jogo intercala um plano 3 (normalmente zero) e grava 4bpp na VRAM [SNESLab: BGR555]. O [Lunar Compress] tem uma opção (`Format2=1` nos formatos LC_LZ1 e LC_LZ2) que converte 3bpp em 4bpp ao descomprimir, sinal de que o par "LZ + 3bpp" era comum.

Consequência pra ROM hack: um gráfico 3bpp só usa as cores 0-7 de uma paleta de 16. Se você editar em 4bpp e usar cor 8-15, o plano 3 é perdido na reinserção.

## 1bpp (8 bytes, só em ROM)

1 byte por linha, bit 7 à esquerda [Klarth] [Tile Molester]. Comum pra fonte de texto. O jogo expande pra 2bpp ou 4bpp na carga (às vezes copiando o mesmo byte nos dois planos, às vezes zerando um): confira na rotina de carga antes de supor. **Não confirmado** em fonte técnica qual é o jeito "padrão"; varia por jogo.

## Mode 7 (8bpp chunky, intercalado com o mapa)

- Sem planos: 1 byte = 1 pixel, índice de 8 bits, da esquerda pra direita e de cima pra baixo [fullsnes] [SNESdev wiki: Tiles].
- Os tiles ficam nos **bytes altos** (endereços de byte ímpares) das primeiras 16K words da VRAM; o mapa de 128x128 fica nos bytes baixos [fullsnes] [SNESdev wiki: Tiles]. O [Mesen2] lê o pixel x da linha em `início + 2x + 1`.
- Um tile ocupa os bytes ímpares de uma região de 128 bytes: linha 0 em $01, $03, ..., $0F; linha 1 em $11..$1F; até a linha 7 em $71..$7F [fullsnes].
- Até 256 tiles; o mapa tem 1 byte por entrada (só o número do tile, sem paleta nem flip) [fullsnes].
- EXTBG (BG2 do modo 7, $2133 bit 6): mesmo dado do BG1, com o bit 7 virando prioridade por pixel e 7 bits de cor [fullsnes] [SNESdev wiki: Tiles] [Mesen2].
- Na ROM os dados de Mode 7 costumam estar separados (tiles num bloco, mapa noutro) ou já intercalados; o superfamiconv gera o intercalado com `--out-mode7-data` [superfamiconv]. Pra gravar só os bytes altos, use VMAIN com incremento depois do byte alto e escreva em $2119 [fullsnes].

## Tiles maiores que 8x8

- A VRAM é vista como uma grade de 16 tiles de largura: o tile à direita de N é N+1, o de baixo é N+$10 [fullsnes] [SNESdev wiki: Tiles].
- Em BG de 16x16 há carry entre linhas; em OBJ não há: o tile à direita de $1FF num OBJ é $1F0 (volta dentro da mesma linha de 16), e o de baixo de $1F0 é $100 (volta dentro da tabela) [fullsnes] [SFC wiki: Sprites].
- Ao extrair um sprite grande, monte a folha com 16 tiles por linha (128 px de largura): é como o PPU enxerga, e é o padrão de visualização dos editores.

## Achar tile na ROM sem descomprimir

- Abra a ROM num editor de tiles no formato certo (4bpp SNES pra sprite) e role: gráfico não comprimido aparece reconhecível.
- Se não alinhar, ajuste o offset de 1 em 1 byte; formato certo com offset errado mostra "quase" o desenho, com cores trocadas ou deslocado.
- Se tudo vira ruído em qualquer formato e offset, o gráfico está comprimido: ver [compressao.md](compressao.md).
- Melhor caminho: no [Mesen2], Tile Viewer mostra a VRAM; com o tile achado, use breakpoint de escrita na VRAM pra chegar no DMA e daí na origem (ver [compressao.md](compressao.md), seção trace).
