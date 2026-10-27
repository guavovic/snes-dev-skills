---
name: snes-graficos
description: Gráficos do Super Nintendo (SNES / Super Famicom) para ROM hack, homebrew ou extração de arte. Use quando a tarefa envolver formato de tile (1bpp, 2bpp, 3bpp, 4bpp, 8bpp, bitplanes, Mode 7 intercalado), paleta e cor (BGR555, converter RGB pra 15 bits, arredondar ou truncar, CGRAM, qual paleta cada BG e sprite usa, direct color), tilemap (número do tile, paleta, prioridade, flip), sprites e OAM (tabela baixa e alta, tamanhos do OBSEL, limite de 32 sprites e 34 fatias por linha, sprite piscando ou sumindo), converter PNG pra SNES e de volta (superfamiconv, script Python), editores de tile (YY-CHR, Tile Molester, Tile Viewer do Mesen2), achar um gráfico dentro da ROM, gráfico que vira ruído no editor, compressão (LZ, LC_LZ2, LZSS, RLE, Lunar Compress, decomp, recomp) ou rastrear a rotina de descompressão no emulador. Também serve para perguntas como "por que meu sprite tem as cores erradas", "em que formato está esse gráfico", "como reinsiro o gráfico editado" ou "esse dado está comprimido?".
---

# snes-graficos

Como os gráficos do SNES ficam guardados (na ROM, na VRAM, na CGRAM e na OAM) e como tirar, editar e devolver. Este arquivo dá a visão geral, as regras que mais evitam erro e o índice; o detalhe com tabelas fica em `references/`.

Toda afirmação técnica dos references tem fonte entre colchetes (`[fullsnes]`, `[SNESdev wiki: Tiles]`...), listadas em [references/fontes.md](references/fontes.md) com as divergências encontradas. Registradores e a parte de hardware do PPU estão na skill `snes-hardware` (`references/ppu-formatos.md`); aqui os formatos são conferidos numa segunda e terceira fonte e não se repetem as tabelas de registrador.

## Visão geral

- **Tile:** bloco de 8x8 em que cada pixel é um índice de paleta, não uma cor. Índice 0 é transparente.
- **Formato planar:** o índice é espalhado em planos de bits. 2bpp = 16 bytes, 4bpp = 32, 8bpp = 64, sempre em pares de planos intercalados por linha. 1bpp e 3bpp só existem na ROM: o jogo expande antes de mandar pra VRAM.
- **Mode 7:** 1 byte por pixel (sem planos), nos bytes altos da VRAM, com o mapa de 128x128 nos bytes baixos.
- **Cor:** 15 bits BGR555 (`0BBBBBGGGGGRRRRR`, little endian). CGRAM tem 256 cores: BGs embaixo ($00-$7F, ou tudo no 8bpp), sprites em cima ($80-$FF).
- **Tilemap:** 1 word por posição com tile (10 bits), paleta (3), prioridade (1) e flip X/Y.
- **OAM:** 128 sprites, 4 bytes cada + 2 bits na tabela alta (bit 8 de X e tamanho). Sprite é sempre 4bpp. Dois tamanhos por vez, escolhidos no OBSEL.
- **Compressão:** feita por software, formato de cada desenvolvedora. O jogo descomprime pra WRAM e copia pra VRAM por DMA.

## Regras de ouro

1. **Descubra o formato pela VRAM, não pela ROM.** Abra o Tile Viewer do Mesen2 com o jogo rodando, veja bpp e paleta, e só depois procure a origem.
2. **Trabalhe com PNG indexado.** Índice do PNG = valor do pixel. PNG em RGB obriga a remapear cor, e a reinserção deixa de ser exata.
3. **Ida e volta de gráfico do jogo: trunque a cor (`>> 3`). Arte nova em 24 bits: arredonde (`--round`).** Truncar recupera o valor original seja qual for a expansão que o emulador usou.
4. **Expanda 5 → 8 bits com `(c << 3) | (c >> 2)`**, senão o branco vira 248.
5. **Respeite o bpp de origem.** Gráfico 3bpp só tem cores 0-7; usar 8-15 no editor some na reinserção.
6. **Gráfico que vira ruído em qualquer formato e offset está comprimido.** Ache a rotina pelo trace (escrita na VRAM → DMA → buffer na WRAM → descompressor) em vez de chutar formato.
7. **Confira o header de 512 bytes** (arquivo com tamanho N·1024 + 512) antes de usar offset de arquivo.
8. **Não distribua gráfico extraído de jogo comercial.** Distribua patch (IPS/BPS).

## Armadilhas

- **Plano 0 é o bit menos significativo** e o bit 7 de cada byte é o pixel da esquerda. Inverter qualquer um dos dois dá desenho espelhado ou cores trocadas.
- **4bpp não é "4 planos seguidos"**: são dois blocos de 2bpp (planos 0-1 nos 16 primeiros bytes, 2-3 nos 16 seguintes).
- **Mapa de 64 de largura** são dois blocos de 32x32 em sequência, não linhas de 64.
- **Sprite grande não tem carry**: o tile à direita de $1FF é $1F0. Monte a folha com 16 tiles por linha.
- **Esconder sprite com X = $100 (-256) não funciona**: ele conta como se estivesse em X = 0 e gasta fatias da linha. Use Y fora da tela.
- **Sprites que piscam ou somem numa linha** batem no limite de 32 OBJs ou de 34 fatias de 8 px; $213E bits 6 e 7 dizem qual.
- **Cor 0 de cada paleta nunca aparece**, mas a entrada $00 da CGRAM é o fundo (backdrop).
- **Num BG 8bpp os sprites dividem as cores** $80-$FF com o BG.
- **Paleta de sprite 0-3 não entra no color math**, só as 4-7.
- **Exemplo antigo de superfamiconv** pode usar opção que mudou na v0.12 (reescrita em Rust): confira `--help`.
- **Nome de formato do Lunar Compress é rótulo de catálogo**, não especificação: confirme na rotina do jogo antes de recomprimir.

## Índice dos references

| Arquivo | Conteúdo |
|---|---|
| [formatos-de-tile.md](references/formatos-de-tile.md) | 1bpp, 2bpp, 3bpp, 4bpp, 8bpp e Mode 7 byte a byte; tiles maiores que 8x8; achar tile na ROM |
| [paletas-e-cor.md](references/paletas-e-cor.md) | BGR555, truncar x arredondar, 5 → 8 bits, divisão da CGRAM por modo, direct color, escrita na CGRAM |
| [tilemap-e-oam.md](references/tilemap-e-oam.md) | Entrada do tilemap, OAM (tabela baixa e alta), tamanhos do OBSEL, limites por linha |
| [conversao-png.md](references/conversao-png.md) | superfamiconv, `png_snes.py`, editores de tile, fluxo de extrair, editar e reinserir |
| [compressao.md](references/compressao.md) | Catálogo do Lunar Compress, LC_LZ2, LC_RLE1, LZSS, reconhecer pelos bytes e pelo trace do Mesen2 |
| [png_snes.py](references/png_snes.py) | Script próprio (Python 3 + Pillow): PNG indexado ↔ tiles 1/2/3/4/8bpp e paleta BGR555 |
| [fontes.md](references/fontes.md) | Fontes, confiança, o que não foi consultado e divergências |
