# Formatos de dados do PPU: tiles, tilemap, OAM, paleta e prioridade

Fonte principal: [fullsnes: PPU]. A tabela de modos, os bits de prioridade e de paleta que aparecem em registradores foram conferidos também em [SNESdev wiki: PPU registers]. Formato de tile, entrada de tilemap e OAM têm segunda fonte na skill `snes-graficos` ([SNESdev wiki: Tiles], [SNESdev wiki: Sprites] e o código do [Mesen2], `PpuTools.h`), sem divergência com o [fullsnes]. A tabela de prioridade entre camadas foi conferida só no [fullsnes].

## Modos de BG

| Modo | BG1 | BG2 | BG3 | BG4 | Observação |
|---|---|---|---|---|---|
| 0 | 4 cores | 4 | 4 | 4 | Cada BG tem seu bloco de 32 cores na CGRAM |
| 1 | 16 | 16 | 4 | - | O mais usado; BG3 pode ir para cima de tudo ($2105 bit3) |
| 2 | 16 | 16 | offset-per-tile | - | |
| 3 | 256 | 16 | - | - | BG1 aceita direct color |
| 4 | 256 | 4 | offset-per-tile | - | BG1 aceita direct color |
| 5 | 16 | 4 | - | - | 512 pixels de largura (hires) |
| 6 | 16 | - | offset-per-tile | - | Hires |
| 7 | 256 | EXTBG | - | - | Rotação e escala, sem flip por tile |

Fonte: [fullsnes] [SNESdev wiki: PPU registers]. Modos 5 e 6 não fazem soma/subtração de cor [fullsnes].

## Offset-per-tile (modos 2, 4 e 6)

Nesses modos o BG3 não aparece: o tilemap dele vira uma tabela de scroll por coluna para o BG1 e o BG2 [SNESdev wiki: Offset-per-tile] [fullsnes]. O [fullsnes] marca a própria seção como incompleta e remete aos documentos do anomie; o detalhe abaixo vem do [SNESdev wiki: Offset-per-tile], e o formato da entrada bate com o [fullsnes].

Entrada da tabela (uma word por coluna):

| Bits | Campo |
|---|---|
| 15 | Só no modo 4: 0 = a entrada é scroll horizontal, 1 = vertical |
| 14 | Aplica no BG2 |
| 13 | Aplica no BG1 |
| 12-10 | Sem uso |
| 9-0 | Valor de scroll |

- **Modos 2 e 6:** o PPU lê duas linhas do tilemap do BG3, de 32 entradas cada. A primeira dá o scroll horizontal de cada coluna e a segunda, o vertical.
- **Modo 4:** lê uma linha só, e o bit 15 de cada entrada escolhe se ela é horizontal ou vertical. Uma coluna não recebe os dois.
- **Horizontal:** substitui o HOFS do BG naquela coluna, mas os 3 bits baixos da entrada são ignorados; o scroll fino (0-7) continua vindo do HOFS do próprio BG.
- **Vertical:** substitui o VOFS inteiro do BG naquela coluna.
- **Colunas:** a primeira coluna visível nunca é afetada; a entrada 0 vale para a segunda coluna. Com o scroll fino, até 33 tiles aparecem por linha. Cada entrada vale para a coluna inteira, em todas as linhas da tela.
- **Qual linha do BG3 é lida:** o HOFS e o VOFS do BG3 escolhem a posição da tabela no tilemap, com os 3 bits baixos ignorados. Com BG3 em tiles de 16x16, a linha do vertical é lida como se o VOFS tivesse 8 a mais; no modo 6, tiles de 8x8 são tratados como 16x8 [SNESdev wiki: Offset-per-tile].

Uso típico: colunas que ondulam na vertical (água, calor) ou chão com perspectiva por coluna.

Teste local no MesenCE 2.2.1, modo 2, ROM própria com BG1 de tiles de cor sólida e scroll zerado, lendo a tela com `emu.getScreenBuffer()` [Teste local]:

- A coluna 0 da tela não mudou; a entrada 0 da tabela agiu na coluna 1 (pixels 8-15).
- Entrada horizontal `$20F5` (BG1, 245): a coluna inteira mostrou o tile da posição 240. Os 3 bits baixos foram ignorados e o scroll fino continuou vindo do BG1HOFS (0).
- Entrada vertical `$2080` (BG1, 128) na posição 2: só a coluna 3 desceu 16 tiles.
- Entrada `$4080` (só bit 14, BG2) na posição 4: o BG1 dessa coluna não mudou.

O resultado bate com o [SNESdev wiki: Offset-per-tile] e o [fullsnes].

## Tiles (formato planar)

- Tile de 8x8. 2bpp = 16 bytes, 4bpp = 32 bytes, 8bpp = 64 bytes [fullsnes] [SNESdev wiki: Tiles].
- 2bpp: para cada linha, 1 byte do plano 0 e 1 byte do plano 1, intercalados (linha 0 plano 0, linha 0 plano 1, linha 1 plano 0...).
- 4bpp: os 16 primeiros bytes são os planos 0 e 1 (como um tile 2bpp); os 16 seguintes são os planos 2 e 3.
- 8bpp: quatro blocos de 2bpp, planos 0-1, 2-3, 4-5 e 6-7.
- Bit 7 de cada byte é o pixel da esquerda.
- Mode 7 é diferente: 1 byte por pixel (chunky), e os tiles ficam nos bytes altos da VRAM (ver abaixo).

## Entrada do tilemap (BG modos 0-6)

Uma word por tile:

| Bits | Campo |
|---|---|
| 15 | Espelho vertical |
| 14 | Espelho horizontal |
| 13 | Prioridade (0 baixa, 1 alta) |
| 12-10 | Paleta (0-7) |
| 9-0 | Número do tile (0-1023), relativo à base de $210B/$210C |

- Um mapa de 32x32 ocupa 1K words. Mapas de 64 de largura são dois blocos de 32x32 lado a lado, não uma linha de 64 [fullsnes].
- Tile de 16x16 (bit de $2105): o tile N é o canto superior esquerdo; N+1 à direita, N+16 abaixo, N+17 na diagonal.
- Cor 0 de cada paleta é transparente nos BGs e nos OBJs.

## Mode 7 na VRAM

- Mapa de 128x128 tiles, 1 byte por entrada, nos **bytes baixos** das primeiras 16K words.
- Até 256 tiles de 8x8 em 8bpp chunky, nos **bytes altos** das mesmas words [fullsnes].
- Por isso o upload usa VMAIN com incremento depois do byte baixo (mapa, $2118) ou depois do alto (tiles, $2119), conforme o que está sendo escrito.
- EXTBG (BG2 do Mode 7, $2133 bit6): mesmos dados do BG1, mas o bit 7 do pixel vira prioridade e sobram 128 cores.

## OAM (sprites)

544 bytes: tabela baixa de 512 bytes (128 OBJs × 4 bytes) e tabela alta de 32 bytes (2 bits por OBJ) [fullsnes] [SNESdev wiki: Sprites].

Tabela baixa, por OBJ:

| Byte | Conteúdo |
|---|---|
| 0 | X, bits 7-0 |
| 1 | Y: o OBJ aparece a partir da linha Y+1 (ver "Esconder um OBJ") |
| 2 | Número do tile, bits 7-0 |
| 3 | bit7 espelho vertical; bit6 espelho horizontal; bits 5-4 prioridade (0-3); bits 3-1 paleta (0-7, usa CGRAM $80-$FF); bit0 tile bit 8 (seleciona a 2ª tabela de tiles) |

Tabela alta: 1 byte para cada 4 OBJs. Para o OBJ n, os bits `2·(n%4)` e `2·(n%4)+1`: o primeiro é o bit 8 de X (X negativo, entra pela esquerda), o segundo escolhe tamanho pequeno (0) ou grande (1).

- OBJ grande feito de vários tiles: o PPU enxerga a área de tiles como uma grade de 16 tiles de largura; N+1 fica à direita e N+$10 abaixo (o número em hexa pode ser lido como linha/coluna) [fullsnes].

### Esconder um OBJ pelo Y

O OBJ ocupa as linhas Y+1 até Y+altura, contadas módulo 256 [SNESdev wiki: Sprites] [Teste local]. Com Y = 0 ele começa na linha 1, e a parte que passa de 255 reaparece no topo. Logo, o OBJ fica todo escondido quando Y é pelo menos a altura visível (224 ou 239) e no máximo 256 menos a altura do OBJ:

| Altura do OBJ | Y seguro, modo de 224 linhas | Y seguro, modo de 239 linhas |
|---|---|---|
| 8 | 224 a 248 | 239 a 248 |
| 16 | 224 a 240 | 239 a 240 |
| 32 | só 224 | nenhum |
| 64 | nenhum | nenhum |

Conferido no MesenCE 2.2.1 com ROM própria [Teste local]: 32x32 em Y = 224 some e em Y = 225 aparece na linha 1; 64x64 em Y = 224 aparece nas linhas 1 a 32; no modo de 239 linhas, 16x16 em Y = 239 some e 32x32 em Y = 239 aparece nas linhas 1 a 15. Bate com o [SNESdev wiki: Sprites], que dá Y = 224 como suficiente para esconder OBJs de até 32x32, e com o aviso do [fullsnes] (64 de altura no modo de 224 e 32 no de 239 dão a volta).

Para OBJ que não tem Y seguro, esconda pelo X: X de -255 a -largura (bit 8 de X ligado na tabela alta) deixa o OBJ todo fora da tela pela esquerda. Evite X = -256 ($100): o [SNESdev wiki: Sprites] avisa que o OBJ nessa posição ainda conta no limite de OBJs por linha. No MesenCE 2.2.1, um 64x64 em X = -64 some e em X = -63 mostra só a coluna 0 [Teste local]. No mesmo teste, OBJs de 32x32 deixados em Y = 240 apareceram nas linhas 1 a 16, como a tabela prevê.

### Limites por linha

- No máximo 32 OBJs por linha; o excedente some e liga STAT77 bit6 [fullsnes].
- No máximo 34 tiles de 8 pixels de OBJ por linha; o excedente some e liga STAT77 bit7.
- Prioridade entre OBJs: menor índice na OAM fica na frente. A rotação de prioridade (bit15 de OAMADD) muda qual OBJ é o primeiro, técnica comum para alternar quem some quando passa do limite ("flicker").

## CGRAM e cor

- 256 cores de 15 bits: `0BBBBBGGGGGRRRRR` [fullsnes].
- Cor 0 = backdrop (fundo quando nenhuma camada tem pixel).
- BGs de 4 cores usam paletas de 4 em 4, de 16 cores de 16 em 16, a partir de 0. No Mode 0 cada BG tem um bloco próprio: BG1 em $00, BG2 em $20, BG3 em $40, BG4 em $60.
- OBJs usam sempre $80-$FF (8 paletas de 16). Só as paletas 4-7 (CGRAM $C0-$FF) entram no color math.
- Direct color ($2130 bit0, BG1 de 256 cores nos modos 3, 4 e 7): o índice de 8 bits vira cor direta `BBGGGRRR` (índice 0 continua transparente). Nos modos 3 e 4 os 3 bits de paleta do tilemap entram como um bit extra logo abaixo de cada canal; no Mode 7 não há esse bit [fullsnes].

## Prioridade entre camadas

Da frente para trás. `.1` = tile com bit de prioridade 1, `.0` = prioridade 0, `OBJ.n` = OBJ com prioridade n [fullsnes].

| Modo 0 | Modo 1 (BG3 normal) | Modos 2-5 | Modo 7 (com EXTBG) |
|---|---|---|---|
| OBJ.3 | BG3.1 se $2105 bit3 = 1 | OBJ.3 | OBJ.3 |
| BG1.1 | OBJ.3 | BG1.1 | OBJ.2 |
| BG2.1 | BG1.1 | OBJ.2 | BG2 pixel alto |
| OBJ.2 | BG2.1 | BG2.1 | OBJ.1 |
| BG1.0 | OBJ.2 | OBJ.1 | BG1 |
| BG2.0 | BG1.0 | BG1.0 | OBJ.0 |
| OBJ.1 | BG2.0 | OBJ.0 | BG2 pixel baixo |
| BG3.1 | OBJ.1 | BG2.0 | backdrop |
| BG4.1 | BG3.1 (se bit3 = 0) | backdrop | |
| OBJ.0 | OBJ.0 | | |
| BG3.0 | BG3.0 | | |
| BG4.0 | backdrop | | |
| backdrop | | | |

O modo 6 segue a coluna 2-5 sem o BG2.

## Color math, em uma frase

O pixel da tela principal (camadas em TM) é somado ou subtraído do pixel da sub-tela (camadas em TS) ou da cor fixa de COLDATA, com opção de dividir por 2, para as camadas marcadas em CGADSUB e dentro da região definida por CGWSEL e pela janela de cor. Usos típicos: transparência (soma com metade), escurecer (subtração da cor fixa), fade colorido [fullsnes]. Tabela de bits em [ppu-registradores.md](ppu-registradores.md).
