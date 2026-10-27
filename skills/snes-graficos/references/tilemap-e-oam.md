# Tilemap e OAM

Tabelas completas e prioridade entre camadas estão em `snes-hardware/references/ppu-formatos.md` (fonte lá: [fullsnes]). Aqui fica o que importa pra extrair e reinserir gráfico, com a segunda fonte que faltava lá.

## Entrada do tilemap (BG modos 0-6)

Uma word little endian por tile [fullsnes], igual em [SNESdev wiki: Tiles] e na skill `snes-hardware`:

| Bits | Campo |
|---|---|
| 15 | flip vertical |
| 14 | flip horizontal |
| 13 | prioridade |
| 12-10 | paleta (0-7) |
| 9-0 | número do tile (0-1023), relativo à base do BG ($210B/$210C, passos de 4K words) |

Montar a word: `tile | (paleta << 10) | (prioridade << 13) | (flipX << 14) | (flipY << 15)`.

- Um bloco de mapa = 32x32 entradas = 2 KB. Mapa de 64x32 são dois blocos lado a lado (o segundo bloco inteiro depois do primeiro), não linhas de 64 [fullsnes]. Na hora de reconstruir um PNG do mapa, leia bloco por bloco.
- Base do mapa: $2107-$210A bits 7-2, em passos de 1K word (2 KB) [fullsnes].
- Nos modos 2, 4 e 6 o BG3 é tabela de offset-per-tile, não imagem [fullsnes].
- Modo 7: mapa de 128x128, 1 byte por entrada só com o número do tile [fullsnes].

## OAM

544 bytes: tabela baixa de 512 (128 OBJs × 4 bytes) e tabela alta de 32 (2 bits por OBJ) [fullsnes] [SNESdev wiki: Sprites].

| Byte | Conteúdo |
|---|---|
| 0 | X, bits 7-0 |
| 1 | Y |
| 2 | tile, bits 7-0 |
| 3 | `VHPPCCCt`: V flip vertical, H flip horizontal, PP prioridade frente aos BGs, CCC paleta (CGRAM $80 + 16·CCC), t bit 8 do tile (2ª tabela de tiles) |

Tabela alta: byte `n/4`, bits `2·(n%4)` = bit 8 de X (vale -256) e `2·(n%4)+1` = tamanho (0 pequeno, 1 grande) [fullsnes] [SNESdev wiki: Sprites].

OBJ é sempre 4bpp [fullsnes] [SNESdev wiki: Sprites].

## Tamanhos ($2101 OBSEL, bits 7-5)

| Valor | Pequeno | Grande |
|---|---|---|
| 0 | 8x8 | 16x16 |
| 1 | 8x8 | 32x32 |
| 2 | 8x8 | 64x64 |
| 3 | 16x16 | 32x32 |
| 4 | 16x16 | 64x64 |
| 5 | 32x32 | 64x64 |
| 6 | 16x32 | 32x64 (não documentado pela Nintendo) |
| 7 | 16x32 | 32x32 (não documentado) |

Fonte: [fullsnes]. O [SNESdev wiki: Sprites] confirma os tamanhos possíveis (8x8, 16x16, 32x32, 64x64, 16x32 e 32x64) e que não existe 8x16. O valor 7 só aparece no [fullsnes].

OBSEL bits 2-0 = base dos tiles de OBJ (passos de 8K words); bits 4-3 = distância entre a 1ª e a 2ª tabela (passos de 4K words) [fullsnes]. A 2ª tabela não precisa ser contígua [SNESdev wiki: Sprites].

OBJ retangular com flip vertical: cada metade quadrada é invertida separadamente (linhas "01234567" viram "32107654") [SFC wiki: Sprites].

## Limites por linha

| Limite | O que estoura | Flag | Fonte |
|---|---|---|---|
| 32 OBJs por linha | Ficam os 32 de menor índice (a partir do primeiro, contando a rotação de prioridade) | $213E bit 6 | [fullsnes] [SNESdev wiki: Sprites] [SFC wiki: Sprites] |
| 34 fatias de 8 px por linha | Avaliadas do maior índice pro menor entre os 32; as de menor índice somem primeiro; dentro do OBJ, da esquerda pra direita | $213E bit 7 | [fullsnes] [SNESdev wiki: Sprites] [SFC wiki: Sprites] |

- OBJ fora da tela não conta, **exceto** com X = -256 ($100): conta como se estivesse em X = 0 e, no limite de fatias, contam todas as fatias dele [SNESdev wiki: Sprites] [SFC wiki: Sprites]. Pra esconder OBJ use Y fora da tela, não X = $100.
- Entre OBJs, o de menor índice fica na frente, qualquer que seja o PP [SNESdev wiki: Sprites].
- Y: no modo de 224 linhas, OBJ de 64 de altura pode reaparecer no topo [fullsnes]. O [SNESdev wiki: Sprites] diz que o OBJ aparece uma linha abaixo de Y, mas como a linha 0 é escondida, Y = 0 cai na primeira linha visível; o [fullsnes] não comenta isso.
