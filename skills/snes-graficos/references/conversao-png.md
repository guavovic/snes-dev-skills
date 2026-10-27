# PNG ↔ SNES: ferramentas e fluxo

## superfamiconv (principal)

Conversor de linha de comando de David Lindecrantz (Optiroc), MIT, desde a v0.12 reescrito em Rust [superfamiconv]. Divide o trabalho em três etapas, cada uma com subcomando:

| Subcomando | Faz |
|---|---|
| `palette` | Reduz as cores pra 5 bits e empacota em subpaletas |
| `tiles` | Corta em 8x8, remapeia pra paleta e deduplica (inclusive por flip) |
| `map` | Gera o tilemap (tile + paleta + flip) |
| `convert` | As três de uma vez |

Modos: `-M snes` (padrão: 8x8, 1024 tiles, 8 subpaletas, 4bpp, com flip) e `-M snes_mode7` (256 tiles, 1 paleta, 8bpp, sem flip) [superfamiconv].

```sh
# BG 4bpp: paleta, tiles e mapa
superfamiconv convert -M snes -i fundo.png -p fundo.pal -t fundo.chr -m fundo.map -v

# BG 2bpp com no máximo 8 paletas de 4 cores
superfamiconv convert -M snes -B 2 -i hud.png -p hud.pal -t hud.chr -m hud.map

# Sprite: sem deduplicar, ordem de folha de sprites
superfamiconv tiles -M snes -S -D -i heroi.png -p heroi.pal -d heroi.chr

# Mode 7 já intercalado (mapa nos bytes baixos, tiles nos altos)
superfamiconv convert -M snes_mode7 -i chao.png --m7 chao.m7

# PNG indexado: usa os índices como estão, sem reordenar cores
superfamiconv convert -M snes -R -i arte_indexada.png -p a.pal -t a.chr -m a.map
```

Opções que mais importam [superfamiconv]: `-B` bpp, `-R` não remapear (exige PNG indexado), `-D` não deduplicar, `-F` não deduplicar por flip, `-Z` cor zero, `--round` arredondar em vez de truncar (ver [paletas-e-cor.md](paletas-e-cor.md)), `--tile-base-offset` e `--palette-base-offset` pra quando os tiles não começam no 0 da VRAM, `-Q` quantizar arte com cor demais. Ao rodar `map` separado, passe os mesmos `-Q`, `--dither` e `--round` usados em `palette` e `tiles`.

A v0.12 mudou a interface em relação às versões em C++ (v0.3-v0.11). Exemplo antigo da internet pode ter opção diferente: confira `superfamiconv <comando> --help` da versão instalada.

## Script próprio: `png_snes.py`

`references/png_snes.py` (Python 3 + Pillow, código original deste repositório) faz a conversão direta, útil em ROM hack quando você quer reinserir na mesma ordem e com os mesmos índices:

```sh
python png_snes.py snes2png tiles.bin tiles.png --bpp 4 --pal paleta.bin --largura 16
python png_snes.py png2snes tiles.png tiles.bin --bpp 4
python png_snes.py png2snes arte_nova.png arte.bin --bpp 4 --pal arte.pal --round
```

- Suporta 1, 2, 3, 4 e 8bpp planares; não faz Mode 7 nem tilemap.
- Exige PNG indexado e não remapeia: índice do PNG = valor do pixel. Por isso a volta é exata.
- Testado nesta pesquisa: ida e volta bit a bit, e o layout 2/4/8bpp conferido contra a fórmula do [Mesen2] e o exemplo do [SNESdev wiki: Tiles].

## Editores de tile

| Ferramenta | O que é | Fonte |
|---|---|---|
| YY-CHR (.NET) | Editor de tiles de YY, muito usado em ROM hack; formatos por plugin (há plugins de terceiros em DLL) | [YY-CHR plugins] |
| Tile Molester | Editor de gráficos em Java, multiformato e extensível por `tmspec.xml`; original de SnowBro, com versões de Central MiB, Lab313, Mewster e toruzz (v0.21) | [Tile Molester] |
| Mesen2 | Tile Viewer, Tilemap Viewer, Sprite Viewer, Palette Viewer e Tile Editor ao vivo, sobre a VRAM/CGRAM/OAM do jogo rodando | [Mesen2] |

Lista de formatos do Tile Molester que interessa ao SNES: 1bpp, 2bpp, "3bpp planar composite (2bpp+1bpp)", "4bpp planar composite (2x2bpp)" e "8bpp planar composite (4x2bpp)"; o filtro de arquivo `.sfc/.smc/.fig` abre em 4bpp por padrão [Tile Molester]. Detalhes de menu e versão atual do YY-CHR **não confirmados** nesta pesquisa (página do romhacking.net bloqueada).

## Fluxo de ROM hack: extrair, editar, reinserir

1. **Achar** o gráfico: Tile Viewer do Mesen2 mostra a VRAM; descubra formato (bpp) e paleta olhando o Tilemap/Sprite Viewer.
2. **Achar a origem na ROM**: breakpoint de escrita na VRAM no endereço do tile → cai no DMA → registradores $43x2-$43x4 dão o endereço de origem. Se a origem é WRAM, o gráfico foi descomprimido antes: ver [compressao.md](compressao.md).
3. **Extrair**: não comprimido, recorte direto da ROM. Se o arquivo tem tamanho N·1024 + 512, há um header de copiador de 512 bytes antes da ROM e todo offset de arquivo anda 512 [fullsnes]. Comprimido, descomprima (Lunar Compress ou rotina própria).
4. **Converter pra PNG** indexado com a paleta real do jogo (dump da CGRAM pelo Mesen2), com `png_snes.py snes2png`.
5. **Editar** sem mudar o modo indexado nem usar índice acima do limite do bpp (3bpp: só 0-7).
6. **Voltar**: `png2snes` com o mesmo bpp; se era comprimido, recomprima e confira se cabe no espaço original. Não coube: mova pra espaço livre e repasse o ponteiro (ponteiro e espaço livre: skill `snes-assembly`).
7. **Testar** no emulador e comparar a VRAM antes/depois.

Nada de distribuir gráfico extraído de jogo comercial: o patch (IPS/BPS) distribui só a diferença.
