# Paletas, cor BGR555 e CGRAM

## Formato da cor

Cada cor é uma word de 15 bits, little endian na ROM e na CGRAM [fullsnes] [SNESdev wiki: CGRAM]:

| Bits | Campo |
|---|---|
| 15 | sem uso (grave 0) |
| 14-10 | azul |
| 9-5 | verde |
| 4-0 | vermelho |

Byte baixo `GGGRRRRR`, byte alto `0BBBBBGG` [SNESdev wiki: CGRAM]. Exemplos: vermelho puro = `$001F` (bytes `1F 00`), verde = `$03E0`, azul = `$7C00`, branco = `$7FFF`.

Reconhecer paleta na ROM: blocos de 32 bytes (16 cores) em que todo byte de posição ímpar é menor que $80. Paletas de 4bpp costumam começar com uma cor "qualquer" (a transparente).

## Conversão RGB888 → BGR555 (o arredondamento certo)

Há dois jeitos, e a escolha depende de onde a cor veio:

| Método | Fórmula por canal | Quando usar | Fonte |
|---|---|---|---|
| Truncar | `c5 = c8 >> 3` | PNG que veio de dump do SNES (emulador, editor de tiles) | [SNESLab: BGR555], padrão do [superfamiconv] |
| Mais próximo | `c5 = (c8 * 31 + 127) / 255` (divisão inteira) | Arte nova desenhada em 24 bits | `--round` do [superfamiconv] |

Por que importa: emulador e editor expandem 5 → 8 bits de dois jeitos, `c << 3` ou `(c << 3) | (c >> 2)`. Truncar recupera o valor original nos dois casos. O "mais próximo" recupera só o segundo: com `c << 3` ele erra os valores 19 a 31 (ex.: 31 << 3 = 248 vira 30). Conferido por enumeração dos 32 valores nesta pesquisa. Regra: **ida e volta de gráfico do jogo, trunque; arte nova, arredonde**.

## Conversão BGR555 → RGB888

Replicação de bits: `c8 = (c5 << 3) | (c5 >> 2)`, que leva 0 → 0 e 31 → 255 [superfamiconv] (`scale_up`) [Mesen2] (`Convert5BitTo8Bit`). `c5 << 3` sozinho deixa o branco em 248.

Isso é conversão numérica, não a cor que a TV mostrava: o [superfamiconv] avisa que não faz transformação de espaço de cor. Correção de gama de TV fica de fora desta skill.

## CGRAM: 256 cores, como são divididas

Índices em CGRAM (cada índice = 1 cor = 2 bytes) [fullsnes]:

| Índices | Uso |
|---|---|
| $00 | backdrop (cor de fundo quando nenhuma camada desenha) |
| $00-$FF | paleta única de BG 8bpp (modos 3, 4 e 7, sem direct color) |
| $00-$7F | BG2 EXTBG do modo 7 (128 cores) |
| $00-$7F | 8 paletas de 16 cores pra BG 4bpp |
| $00-$1F | 8 paletas de 4 cores pra BG 2bpp (todos os modos, exceto BG2-4 no modo 0) |
| $20-$3F | BG2 no modo 0 |
| $40-$5F | BG3 no modo 0 |
| $60-$7F | BG4 no modo 0 |
| $80-$FF | 8 paletas de 16 cores dos OBJs |

Conferido também em [SNESdev wiki: CGRAM] (BG 4bpp nos grupos 0-7, OBJ nos grupos 8-15, 2bpp em grupos de 4, 8bpp usa tudo) e na skill `snes-hardware`.

Endereço da cor: `índice = base_do_BG + paleta * cores_por_paleta + valor_do_pixel`. A paleta vem do tilemap (bits 10-12) ou da OAM (bits 1-3 do byte 3, somando $80) [fullsnes].

Pontos práticos:
- A cor 0 de cada paleta nunca aparece (pixel 0 é transparente), mas a entrada $00 é o backdrop [SNESdev wiki: CGRAM].
- Num BG 8bpp a paleta de BG ocupa a CGRAM inteira, inclusive $80-$FF: os OBJs dividem essas cores.
- Só as paletas de OBJ 4-7 ($C0-$FF) participam do color math na tela principal [fullsnes] [SNESdev wiki: Sprites].

## Direct color

Liga com $2130 (CGWSEL) bit 0, vale pra BG de 256 cores (BG1 nos modos 3, 4 e 7) [fullsnes] [SNESdev wiki: Tiles]. O índice `BBGGGRRR` vira a cor `BBb00 GGGg0 RRRr0`, onde `bgr` são os 3 bits de paleta do tilemap (só modos 3 e 4; no modo 7 ficam 0). Índice 0 continua transparente, então preto puro não sai direto [fullsnes] [SNESdev wiki: Tiles] [Mesen2].

## Escrever na CGRAM

`$2121` (CGADD) recebe o índice; `$2122` (CGDATA) recebe dois bytes, baixo primeiro, e o índice avança sozinho [fullsnes] [SNESdev wiki: CGRAM]. A word só é gravada na segunda escrita. Fora de VBlank ou forced blank a escrita não é segura [fullsnes]. Na prática a paleta vai por DMA (modo 2 bytes no mesmo registrador, destino $22): ver `snes-hardware/references/dma-hdma.md`.
