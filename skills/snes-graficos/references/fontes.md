# Fontes da skill snes-graficos

Pesquisa feita em 26/10/2026 e completada em 02/11/2026 (sobras da issue #15). Cada fato de formato, bit ou registrador foi conferido em pelo menos duas fontes da lista; quando não deu, está marcado "não confirmado" no texto. Nenhum gráfico ou dado de jogo comercial foi usado: os exemplos são sintéticos.

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
| [Lunar Compress] | https://fusoya.eludevisibility.org/lc/index.html, pacote oficial https://fusoya.eludevisibility.org/lc/download/lc200.zip (`LunarDLL.h`, `LunarDLL.def`, readme); cópia antiga em https://github.com/kittibyte/lunar-compress | FuSoYa, v2.00 (11/11/2025), primeira versão 23/06/2001 | Catálogo LC_LZ1-21 e LC_RLE1-4 com os números, decomp/recomp/sniff, Format2 3bpp → 4bpp, `LunarCreatePixelMap`/`LunarCreateBppMap` | Alta. Números conferidos no `.def` oficial da v2.00; o readme diz que a documentação é o `.h` e o `.def` |
| [Mesen2] | `Core/Debugger/PpuTools.h`, `Core/Shared/ColorUtilities.h`, `Core/Shared/MemoryType.h`, https://github.com/SourMesen/Mesen2 | Sour (Mesen) | Decodificador de tile (terceira conferência dos formatos), 5 → 8 bits, ferramentas de depuração | Alta (emulador de alta precisão) |
| [superfamiconv] | README e `src/mode/color.rs`, https://github.com/Optiroc/SuperFamiconv | David Lindecrantz (Optiroc), v0.12, MIT | Conversor PNG → SNES, modos, opções, truncar x `--round`, 5 → 8 bits | Alta para a ferramenta |
| [Tile Molester] | `tmspec.xml`, https://github.com/toruzz/TileMolester | SnowBro (original); versões de Central MiB, Lab313, Mewster, toruzz (v0.21) | Editor e lista de formatos (1bpp, 3bpp composite etc.) | Média/alta para os formatos |
| [Klarth] | "Console Graphics Document" (consolegfx.txt) v0.7, lido na cópia do romhacking.net no Internet Archive: https://web.archive.org/web/20070227125143/http://www.romhacking.net:80/docs/consolegfx.txt | Klarth, 2000 | 1bpp, 2bpp "SNES/Gameboy/GBC", 3bpp (2bpp + plano 2, quarto plano inserido na carga), 4bpp, 8bpp, Mode 7 linear | Média/alta: documento clássico, lido inteiro; bate com [fullsnes] e [Tile Molester] |
| [YY-CHR plugins] | https://github.com/gzip/cs-yychr-plugins | gzip | Confirma que o YY-CHR.NET aceita formatos por plugin DLL | Baixa para o YY-CHR em si |
| [YY-CHR @wiki] | Página oficial do YY-CHR, em japonês, https://w.atwiki.jp/yychr/ (lida no Internet Archive, cópia de 24/10/2026: https://web.archive.org/web/20261024211257/https://w.atwiki.jp/yychr/) | YY (autor do programa), build 2021/06/06 | Versão atual, .NET Framework 4.0, lista de formatos, paleta de estado de emulador e `.pal` de 16 bits, histórico de versões | Alta para o programa (é o autor) |
| [sfc-comp] | https://github.com/sfc-comp/sfc-comp (commit `dd9dc03`), `doc/LunarCompress.md`, `src/bokujou_monogatari_comp.cpp` e os outros compressores em `src/` | sfc-comp, MIT | Reimplementação de compressores de jogos de SNES: correspondência LC_* → função, parâmetros de LZSS por jogo, formato do LC_LZ11 | Média/alta. Código aberto que gera dados aceitos pelos jogos; fonte única pros parâmetros de cada jogo |
| [HM-Decomp] | https://github.com/ElisaS-Codes/HM-Decomp, `tools/TileBankDecompressor.py` | ElisaS-Codes, sem licença declarada (só citado, nada copiado) | Descompressor independente do mesmo formato do LC_LZ11 | Média. Segunda fonte do LC_LZ11 |
| [Okumura LZSS.C] | `LZSS.C` de 06/04/1989, na cópia do `libkern/mkext.c` do xnu: https://github.com/apple-oss-distributions/xnu | Haruhiko Okumura, 1989; mantido pela Apple no xnu | N, F, THRESHOLD, preenchimento com espaço, `r = N - F`, flags e empacotamento da referência | Alta |
| [Okumura lzss.c] | http://oku.edu.mie-u.ac.jp/~okumura/compression/lzss.c (lido no Internet Archive; o site recusou conexão) | Haruhiko Okumura | Versão nova do código, com fluxo de bits (`EI = 11`, `EJ = 4`) | Média. Só pra registrar que não é o mesmo formato do LZSS.C de 1989 |
| [PeterLemon SNES] | https://github.com/PeterLemon/SNES, macro `LoadLOVRAM` em `HelloWorld/LIB/SNES_GFX.INC` | Peter Lemon | Fonte 1bpp carregada por DMA só no byte baixo da VRAM (`stz VMAIN`, destino $2118); há também `LoadHIVRAM` | Alta para a técnica (homebrew que roda) |
| [nesdev: 1bpp] | Fórum do NESdev, tópico sobre gráficos 1bpp no SNES (nov/2020): https://forums.nesdev.org/viewtopic.php?t=21249 | tepples e outros | SNES sem modo 1bpp; escrever só o byte baixo ou o alto com VMAIN; a outra metade tem de estar zerada ou conhecida | Média. Fórum, mas bate com [PeterLemon SNES] e com o [Teste local] |
| [Teste local] | ROM própria montada no asar 1.91 e rodada no MesenCE 2.2.1 (`--testRunner`), 02/11/2026; não está no repositório | este repositório | VRAM limpa por DMA, depois 8 bytes por DMA com VMAIN = `$00` em $2118 (caem nos bytes pares) e com VMAIN = `$80` em $2119 (caem nos ímpares) | Alta para o que foi medido |
| [Wikipedia: LZSS] | https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Storer%E2%80%93Szymanski | Wikipedia | LZSS (Storer e Szymanski, 1982), bit de flag literal/referência, código de Okumura (1989) | Média |

## Não consultadas

- Rotina de descompressão de jogo comercial: de propósito. O LC_LZ11 foi descrito por duas implementações abertas ([sfc-comp], [HM-Decomp]), sem trace nem desmontagem de ROM.
- Fontes em japonês sobre compressão de jogos de SFC: a única achada foi a DQバイナリ改造 @Wiki (https://w.atwiki.jp/dq_binary/), que analisa o formato de um jogo comercial específico; não serve de fonte geral e não foi usada. Fica pendente na issue de sobras da v0.3. Em japonês sobre formatos de tile, a fonte usada é o [YY-CHR @wiki].
- Segunda fonte pros parâmetros de LZSS de cada jogo da tabela de `compressao.md`: só o [sfc-comp] foi lido. Fica pendente na issue de sobras da v0.3.

## Divergências registradas

| Assunto | Diz A | Diz B | Vale |
|---|---|---|---|
| RGB888 → BGR555 | [SNESLab: BGR555], padrão do [superfamiconv]: truncar `>> 3` | `--round` do [superfamiconv]: mais próximo | Depende da origem: dump do jogo trunca, arte nova arredonda (ver `paletas-e-cor.md`) |
| Onde ficam os tiles de Mode 7 | [fullsnes]: "endereços ímpares" | [SNESdev wiki: Tiles]: "byte alto" de cada word | Mesma coisa dita de dois jeitos; [Mesen2] lê em `2x+1` |
| OBJ em X = -256 | [SNESdev wiki: Sprites]: bug, conta todas as fatias | [SFC wiki: Sprites]: tratado como X = 0 | As duas se completam: conta como se estivesse em X = 0, com todas as fatias |
| OBSEL valor 7 (16x32 / 32x32) | [fullsnes] lista | [SNESdev wiki: Sprites] não lista | Fonte única; não confirmado |
| OBJ aparece 1 linha abaixo de Y | [SNESdev wiki: Sprites] | [fullsnes] não comenta | Fonte única |
| Expansão 1bpp → 2bpp/4bpp na carga | [PeterLemon SNES], [nesdev: 1bpp]: DMA só no byte baixo ou só no alto | [nesdev: 1bpp]: cópia nos dois planos por software | Os jeitos estão documentados e o do DMA foi conferido no [Teste local]; qual cada jogo usa, só na rotina dele |
| Parâmetros do LZSS (janela, flags) | [Okumura LZSS.C]: 4096, 3-18, anel com `0x20`, `r = 0xFEE` | [sfc-comp]: cada jogo muda janela, anel, flags ou empacotamento | Não há padrão de SNES; o LZSS.C é o ponto de partida e a tabela do sfc-comp mostra as variações (fonte única por jogo) |
| Tamanho no cabeçalho do LC_LZ11 | [sfc-comp]: grava 4 bytes, limita a `0xFFFF` | [HM-Decomp]: lê 2 bytes e pula 2 | Mesmo arquivo na prática; ao gravar, use 4 bytes |
| Data do documento do [Klarth] | cabeçalho: "Version 0.7 - January 2, 2000" | mesmo arquivo: "Started on July 18, 2000" | Inconsistência do próprio documento; citado como 2000 |
| Números dos formatos do Lunar | `LunarDLL.def` do fork kittibyte | `LunarDLL.def` oficial da v2.00 | Iguais; a v2.00 só acrescentou o LC_LZ21 (20) |
