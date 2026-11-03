# Fontes

Documentos usados nas skills, com o que cada um cobre e o quanto é confiável. Cada skill cita as fontes pelo nome entre colchetes, e a lista completa, com URL, autor, ano e as divergências encontradas, fica no `references/fontes.md` de cada uma.

## Principais

| Fonte | Autor | Cobre | Confiança |
|---|---|---|---|
| [Fullsnes](https://problemkaputt.de/fullsnes.htm) | Martin Korth (nocash) | Hardware inteiro: memória, I/O, DMA, PPU, APU, cartucho, timing | Alta |
| [SNESdev wiki](https://snes.nesdev.org/wiki/) | Comunidade NESdev/SNESdev | Registradores, timing, init, vblank, HDMA, color math, janelas, sprites, registradores do DSP e formato BRR | Alta |
| [Documentos do anomie](https://wiki.superfamicom.org/) | anomie | Timing (revisão 1160, de 21/12/2008, conferida na cópia do romhacking.net pelo Internet Archive), mapa de memória, custos de DMA e HDMA | Média: antigos, com um erro conhecido no MEMSEL |
| [Datasheet do W65C816S](https://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf) | Western Design Center | Núcleo 65816: registradores, flags, opcodes, vetores | Alta |
| [Manual do asar](https://github.com/RPGHacker/asar) | RPGHacker e colaboradores | Sintaxe, diretivas e mapeamento do montador; no código da tag v1.91, conta sem precedência, `asar 1.90` e o aviso de depreciação; `arch spc700` | Alta |
| [Mesen 2 / MesenCE](https://github.com/nesdev-org/MesenCE) | Sour e colaboradores | Debugger, CDL, API Lua e modo de teste, lidos no código; callbacks de memória disparando no DMA e HDMA (tag 2.2.1); detecção e portas dos chips de cartucho e decodificação do BRR | Alta |
| [bsnes](https://github.com/bsnes-emu/bsnes) | byuu (Near) e colaboradores | Desempate de comportamento de hardware; temporização de refresh, NMI e IRQ lida no código; janela de escrita na CGRAM; portas dos chips de cartucho e núcleo do DSP (blargg) | Apoio |
| [ares](https://github.com/ares-emulator/ares) | Near e mantenedores do ares | Desempate de comportamento de hardware (HDMA) | Apoio |
| [sd2snes / FXPAK](https://sd2snes.de/blog/compatibility) | ikari_01 (mrehkopf) | Lista oficial de incompatibilidades do flash cart (SPC7110, ST-011, ST-018) | Alta |
| [QUsb2snes](https://github.com/Skarsnik/QUsb2snes) | Skarsnik | Protocolo usb2snes: leitura e escrita de memória pela USB | Alta |
| [Super EverDrive X6](https://krikzz.com/our-products/cartridges/super-everdrive-x6.html) | krikzz | Chips suportados pelo flash cart | Alta |
| [TASVideos SNES Accuracy Tests](https://tasvideos.org/EmulatorResources/SNESAccuracyTests) | comunidade TASVideos | Placar antigo (2014) de testes de precisão por emulador | Média |
| [Programming the 65816](https://archive.org/details/0893037893ProgrammingThe65816) | David Eyes e Ron Lichty, 1986 | Livro de referência do 65816: MVN/MVP, apelidos de mnemônico | Alta |
| [Investigating 65C816 Interrupts](http://6502.org/tutorials/65c816interrupts.html) | BCS Technology, 6502.org | Ciclos e latência de interrupção, `WAI` | Alta |
| [WLA-DX](https://github.com/vhelin/wla-dx) | Ville Helin e colaboradores | Sintaxe 65816 do WLA-DX, lida na documentação, no código e nos testes | Alta |
| [Snes9x](https://github.com/snes9xgit/snes9x) | equipe do Snes9x | Checksum espelhado, mapa ExLoROM e SRAM, lidos no `memmap.cpp` | Alta |
| [Código do sd2snes / FXPAK](https://github.com/mrehkopf/sd2snes) | ikari_01 (mrehkopf) | Detecção de mapeamento no firmware, mapa de ROM e SRAM na FPGA | Alta pro que o código faz; sem teste em hardware |
| [Lunar Expand](https://fusoya.eludevisibility.org/le/) | FuSoYa | Suporte a ExLoROM por versão do Snes9x e do ZSNES | Média-alta |
| [Regras de envio do SMW Central](https://web.archive.org/web/20250725214811/https://www.smwcentral.net/?p=guidelines&page=1633980-all-hacks) | SMW Central | Formato e regras de envio de hack, lidos em cópia do Internet Archive | Alta |
| [DiztinGUIsh](https://github.com/DizTools/DiztinGUIsh) | IsoFrieze, DizTools e colaboradores | Importadores do desmontador e formato do CDL do BizHawk, lidos no código | Alta |
| [Capstone](https://github.com/capstone-engine/capstone) | equipe do Capstone | Desmontagem 65816 por script, modos de M e X, lida no código e rodada na 5.0.7 | Alta |
| [sm_disassembly](https://github.com/InsaneFirebat/sm_disassembly) | InsaneFirebat | Organização da desmontagem do Super Metroid que monta no asar (só a estrutura) | Média |
| [z3randomizer](https://github.com/KatDevsGames/z3randomizer) | KatDevsGames e colaboradores | Organização de um hack grande aberto em asar (só a estrutura) | Média |
| [Lunar Compress](https://fusoya.eludevisibility.org/lc/index.html) | FuSoYa | Catálogo de formatos de compressão e os números da DLL, conferidos no pacote oficial v2.00 | Alta |
| [sfc-comp](https://github.com/sfc-comp/sfc-comp) | sfc-comp (MIT) | Compressores de jogos de SNES reimplementados: LC_LZ11 e variantes de LZSS | Média/alta |
| [ff6tools](https://github.com/everything8215/ff6tools) | everything8215 (GPL-3.0) | Compressor e descompressor do LZSS do FF5 e do FF6, segunda fonte desses formatos, rodado com dados sintéticos | Média/alta |
| [Okumura 1988](https://web.archive.org/web/2005/http://oku.edu.mie-u.ac.jp:80/~okumura/compression/1988.html) | Haruhiko Okumura | Página do autor, em japonês, sobre a publicação do LZSS em 1988 e o preenchimento inicial do anel | Alta |
| [YY-CHR @wiki](https://w.atwiki.jp/yychr/) | YY | Página oficial do YY-CHR, em japonês: versão e formatos | Alta |
| [Entrevistas de 2017 da Nintendo JP](https://web.archive.org/web/20191213044242/https://topics.nintendo.co.jp/c/article/0e9c42d3-7d8a-11e7-8cda-063b7ac45a6d.html) | Nintendo | Relato em japonês das equipes de F-ZERO e Super Mario Kart sobre o Mode 7, lido em cópia do Internet Archive | Alta pro relato |
| [SNES CPU usage meter](https://nesdev.nes.science/f12/t12419.xhtml) | fórum NESdev, 2015 | Medir o tempo do quadro pela cor de fundo ou pela linha atual | Média |
| [OpenSNES: profile.h](https://k0b3n4irb.github.io/opensnes/profile_8h.html) | projeto OpenSNES | Medidor de quadro com a cor fixa no backdrop | Média |
| [sneslab](https://sneslab.net/wiki/) | comunidade sneslab | Uso dos canais de DMA em Super Mario World e gráficos dinâmicos | Média |
| [Using DMA effectively](https://wiki.superfamicom.org/using-dma-effectively) | comunidade superfamicom.org | Streaming de quadros de animação com limite por quadro | Média |
| [HM-Decomp](https://github.com/ElisaS-Codes/HM-Decomp) | ElisaS-Codes e DasK | Mapa de bancos e de RAM da desmontagem do Harvest Moon: rotinas e tabela da paleta por hora do dia (só os nomes e endereços) | Média |
| [HarvestMoonSnesDecomp](https://github.com/RodoLy/HarvestMoonSnesDecomp) | Rodrigo (RodriLoy) | Guia da reimplementação em C do Harvest Moon: como o jogo troca a paleta com a hora e a estação (só o texto do guia) | Média/alta |

## Por skill

- [snes-hardware](../skills/snes-hardware/references/fontes.md)
- [snes-assembly](../skills/snes-assembly/references/fontes.md)
- [snes-rom-hack](../skills/snes-rom-hack/references/fontes.md)
- [snes-desmontagem](../skills/snes-desmontagem/references/fontes.md)
- [snes-graficos](../skills/snes-graficos/references/fontes.md)
- [snes-testes](../skills/snes-testes/references/fontes.md)
- [snes-tecnicas](../skills/snes-tecnicas/references/fontes.md)
