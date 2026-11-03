# Fontes

Documentos usados nas skills, com o que cada um cobre e o quanto é confiável. Cada skill cita as fontes pelo nome entre colchetes, e a lista completa, com URL, autor, ano e as divergências encontradas, fica no `references/fontes.md` de cada uma.

## Principais

| Fonte | Autor | Cobre | Confiança |
|---|---|---|---|
| [Fullsnes](https://problemkaputt.de/fullsnes.htm) | Martin Korth (nocash) | Hardware inteiro: memória, I/O, DMA, PPU, APU, cartucho, timing | Alta |
| [SNESdev wiki](https://snes.nesdev.org/wiki/) | Comunidade NESdev/SNESdev | Registradores, timing, init, vblank, HDMA, color math, janelas, sprites | Alta |
| [Documentos do anomie](https://wiki.superfamicom.org/) | anomie | Timing, mapa de memória, custos de DMA e HDMA | Média: antigos, com um erro conhecido no MEMSEL |
| [Datasheet do W65C816S](https://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf) | Western Design Center | Núcleo 65816: registradores, flags, opcodes, vetores | Alta |
| [Manual do asar](https://github.com/RPGHacker/asar) | RPGHacker e colaboradores | Sintaxe, diretivas e mapeamento do montador | Alta |
| [Mesen 2 / MesenCE](https://github.com/nesdev-org/MesenCE) | Sour e colaboradores | Debugger, CDL, API Lua e modo de teste, lidos no código | Alta |
| [bsnes](https://github.com/bsnes-emu/bsnes) | byuu (Near) e colaboradores | Desempate de comportamento de hardware; temporização de refresh, NMI e IRQ lida no código | Apoio |
| [sd2snes / FXPAK](https://sd2snes.de/blog/compatibility) | ikari_01 (mrehkopf) | Lista oficial de incompatibilidades do flash cart (SPC7110, ST-011, ST-018) | Alta |
| [QUsb2snes](https://github.com/Skarsnik/QUsb2snes) | Skarsnik | Protocolo usb2snes: leitura e escrita de memória pela USB | Alta |
| [Super EverDrive X6](https://krikzz.com/our-products/cartridges/super-everdrive-x6.html) | krikzz | Chips suportados pelo flash cart | Alta |
| [TASVideos SNES Accuracy Tests](https://tasvideos.org/EmulatorResources/SNESAccuracyTests) | comunidade TASVideos | Placar antigo (2014) de testes de precisão por emulador | Média |
| [Programming the 65816](https://archive.org/details/0893037893ProgrammingThe65816) | David Eyes e Ron Lichty, 1986 | Livro de referência do 65816: MVN/MVP, apelidos de mnemônico | Alta |
| [Investigating 65C816 Interrupts](http://6502.org/tutorials/65c816interrupts.html) | BCS Technology, 6502.org | Ciclos e latência de interrupção, `WAI` | Alta |
| [WLA-DX](https://github.com/vhelin/wla-dx) | Ville Helin e colaboradores | Sintaxe 65816 do WLA-DX, lida na documentação, no código e nos testes | Alta |

## Por skill

- [snes-hardware](../skills/snes-hardware/references/fontes.md)
- [snes-assembly](../skills/snes-assembly/references/fontes.md)
- [snes-rom-hack](../skills/snes-rom-hack/references/fontes.md)
- [snes-desmontagem](../skills/snes-desmontagem/references/fontes.md)
- [snes-graficos](../skills/snes-graficos/references/fontes.md)
- [snes-testes](../skills/snes-testes/references/fontes.md)
- [snes-tecnicas](../skills/snes-tecnicas/references/fontes.md)
