# Fontes da skill snes-graficos

Pesquisa feita em 26/10/2026. Cada fato de formato, bit ou registrador foi conferido em pelo menos duas fontes da lista; quando não deu, está marcado "não confirmado" no texto. Nenhum gráfico ou dado de jogo comercial foi usado: os exemplos são sintéticos.

| Nome | Fonte | Autor / ano | Cobre | Confiança |
|---|---|---|---|---|
| [fullsnes] | nocash SNES hardware specifications, https://problemkaputt.de/fullsnes.txt | Martin Korth (nocash) | Formatos de tile, Mode 7, CGRAM, tilemap, OAM, OBSEL, limites por linha, direct color, DMA, header de copiador | Alta. Mesma fonte usada na skill `snes-hardware` |
| [SNESdev wiki: Tiles] | https://snes.nesdev.org/wiki/Tiles | comunidade SNESdev (wiki colaborativa) | 2bpp, 4bpp, 8bpp, Mode 7, direct color, grade de 16 tiles, exemplo $1D/$55 | Alta. Segunda fonte dos formatos de hardware |
| [SNESdev wiki: CGRAM] | https://snes.nesdev.org/wiki/CGRAM | comunidade SNESdev | Formato BGR555, divisão da CGRAM, escrita por $2121/$2122 | Alta |
| [SNESdev wiki: Sprites] | https://snes.nesdev.org/wiki/Sprites | comunidade SNESdev | OAM, tamanhos, limites de 32 OBJs e 34 fatias, X = -256, ordem entre OBJs | Alta |
| [SFC wiki: Sprites] | https://wiki.superfamicom.org/sprites | superfamicom.org (wiki colaborativa) | Limites por linha, X = -256, flip vertical de OBJ retangular, wrap de tiles | Média/alta. Bate com as outras duas nos pontos citados |
| [SNESLab: BGR555] | https://sneslab.net/wiki/BGR555 | SNESLab (wiki colaborativa) | Formato de cor, conversão por truncamento, 3bpp | Média/alta |
| [SNESLab: LZ2] | https://sneslab.net/wiki/LZ2 | SNESLab | Formato LC_LZ2 | Média/alta, conferido com [MushROMs: LC_LZ2] |
| [SNESLab: RLE1] | https://sneslab.net/wiki/RLE1 | SNESLab | Formato LC_RLE1 | Média. Fonte única para o RLE1 além do nome no [Lunar Compress] |
| [MushROMs: LC_LZ2] | https://github.com/bonimy/MushROMs/blob/master/doc/LC_LZ2%20Compression%20Format.md | Nelson Garcia (bonimy) | LC_LZ2 e a diferença de endianness pro LZ1 | Média/alta |
| [Lunar Compress] | https://fusoya.eludevisibility.org/lc/index.html e `LunarDLL.h`/`LunarDLL.def` em https://github.com/kittibyte/lunar-compress | FuSoYa, v2.00 (11/11/2025), primeira versão 23/06/2001 | Catálogo LC_LZ1-20 e LC_RLE1-3, decomp/recomp/sniff, Format2 3bpp → 4bpp | Alta para os nomes e o uso; os números do `.def` vêm de cópia antiga do código |
| [Mesen2] | `Core/Debugger/PpuTools.h`, `Core/Shared/ColorUtilities.h`, `Core/Shared/MemoryType.h`, https://github.com/SourMesen/Mesen2 | Sour (Mesen) | Decodificador de tile (terceira conferência dos formatos), 5 → 8 bits, ferramentas de depuração | Alta (emulador de alta precisão) |
| [superfamiconv] | README e `src/mode/color.rs`, https://github.com/Optiroc/SuperFamiconv | David Lindecrantz (Optiroc), v0.12, MIT | Conversor PNG → SNES, modos, opções, truncar x `--round`, 5 → 8 bits | Alta para a ferramenta |
| [Tile Molester] | `tmspec.xml`, https://github.com/toruzz/TileMolester | SnowBro (original); versões de Central MiB, Lab313, Mewster, toruzz (v0.21) | Editor e lista de formatos (1bpp, 3bpp composite etc.) | Média/alta para os formatos |
| [Klarth] | "Console Graphics Document" (consolegfx) v0.7, cópia do romhacking.net em http://otakon273.duckdns.org/Consoles/RomHacking.net/rhdn_20240801/documents/ | Klarth, 2000 | 1bpp e formatos clássicos | Baixa: o arquivo deu 403; só o trecho visto em resultado de busca |
| [YY-CHR plugins] | https://github.com/gzip/cs-yychr-plugins | gzip | Confirma que o YY-CHR.NET aceita formatos por plugin DLL | Baixa para o YY-CHR em si |
| [Wikipedia: LZSS] | https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Storer%E2%80%93Szymanski | Wikipedia | LZSS (Storer e Szymanski, 1982), bit de flag literal/referência, código de Okumura (1989) | Média |

## Não consultadas

- Página do YY-CHR e documentos do romhacking.net: devolveram 403 nesta rodada.
- Documento do Klarth completo: só o trecho da busca.
- Fontes em japonês (ex.: wikis de ROM hack japonesas, documentação do YY-CHR de YY): não pesquisadas nesta rodada.
- Código do decompressor do Lunar Compress pra LC_LZ11: o formato não está descrito em nenhuma fonte lida.

## Divergências registradas

| Assunto | Diz A | Diz B | Vale |
|---|---|---|---|
| RGB888 → BGR555 | [SNESLab: BGR555], padrão do [superfamiconv]: truncar `>> 3` | `--round` do [superfamiconv]: mais próximo | Depende da origem: dump do jogo trunca, arte nova arredonda (ver `paletas-e-cor.md`) |
| Onde ficam os tiles de Mode 7 | [fullsnes]: "endereços ímpares" | [SNESdev wiki: Tiles]: "byte alto" de cada word | Mesma coisa dita de dois jeitos; [Mesen2] lê em `2x+1` |
| OBJ em X = -256 | [SNESdev wiki: Sprites]: bug, conta todas as fatias | [SFC wiki: Sprites]: tratado como X = 0 | As duas se completam: conta como se estivesse em X = 0, com todas as fatias |
| OBSEL valor 7 (16x32 / 32x32) | [fullsnes] lista | [SNESdev wiki: Sprites] não lista | Fonte única; não confirmado |
| OBJ aparece 1 linha abaixo de Y | [SNESdev wiki: Sprites] | [fullsnes] não comenta | Fonte única |
| Expansão 1bpp → 2bpp/4bpp na carga | nenhuma fonte técnica fixa um jeito | | Varia por jogo; não confirmado |
| Parâmetros do LZSS (janela, flags) | [Wikipedia: LZSS] cita Okumura sem parâmetros de SNES | | Não confirmado; ler na rotina do jogo |
| Números dos formatos do Lunar | `LunarDLL.def` do fork kittibyte | versão atual não conferida | Conferir no `.def` da versão baixada |
