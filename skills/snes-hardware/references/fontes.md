# Fontes da skill snes-hardware

Consultadas em 26/10/2026; as linhas marcadas com 02/11/2026 entraram na revisão da v0.2. Nível de confiança: **alta** = documentação de referência conferida em hardware ou usada por emuladores de precisão; **média** = boa, mas antiga ou com partes declaradas incompletas; **apoio** = usada só para desempatar um ponto.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [fullsnes] | Fullsnes, Nocash SNES Specs. https://problemkaputt.de/fullsnes.htm | Martin Korth (nocash) | Texto extraído do no$sns v1.6; `fullsnes.htm` e `fullsnes.txt` com data de modificação no servidor (HTTP Last-Modified) de 28/01/2021, conferida em 02/11/2026 | Tudo: mapa de memória, I/O, DMA/HDMA, PPU, APU, controles, header, timing, chips de cartucho | Alta. Seções de offset-per-tile e alguns tempos finos são marcados como incompletos pelo próprio autor |
| [SNESdev wiki] | SNESdev Wiki. https://snes.nesdev.org/wiki/ (páginas Memory_map, MMIO_registers, PPU_registers, DMA_registers, Timing, CPU_vectors, Booting_the_SPC700; em 02/11/2026 também HDMA, Offset-per-tile, Sprites e Tiles) | Comunidade NESdev/SNESdev | Mantida continuamente (consulta em 2026) | Registradores, timing, vetores, boot do SPC700 | Alta |
| [anomie timing] | Anomie's SNES Timing Doc, espelho em https://wiki.superfamicom.org/timing e custos de DMA/HDMA em https://wiki.superfamicom.org/dma-and-hdma | anomie, com pequenas contribuições de RadDad772 | Anos 2000. O espelho não traz versão nem data, e a data exata não foi achada (procurada em 02/11/2026) | Timing de linha, refresh, custos de DMA e HDMA | Média: valores de overhead aproximados |
| [anomie memmap] | Anomie's SNES Memory Mapping Doc v1.1, espelho em https://wiki.superfamicom.org/memory-mapping | anomie | 2003 | Mapa por banco, velocidades, LoROM/HiROM | Média: tem o erro do bit do MEMSEL (ver abaixo) |
| [WDC datasheet] | W65C816S 8/16-bit Microprocessor Datasheet. https://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf | The Western Design Center | 2024 (revisão de 13/03/2024) | Núcleo 65C816: registradores, flags, estado no reset, vetores | Alta para o núcleo; não cobre o que é próprio do 5A22 |
| [bsnes] | Código do bsnes, `bsnes/sfc/cpu/io.cpp`, `sfc/cpu/dma.cpp` e `sfc/ppu/io.cpp` (função `writeCGRAM`). https://github.com/bsnes-emu/bsnes | byuu (Near) e colaboradores | Versão atual do repositório (lida em 02/11/2026) | Bit do MEMSEL; janela de escrita na CGRAM; flag interna do HDMA | Apoio |
| [superfamicom.org: registers] | Página de registradores com texto do anomie. https://wiki.superfamicom.org/registers | anomie e editores da wiki | Sem data no espelho; lida em 02/11/2026 | HDMAEN ligado no meio do quadro, INIDISP no meio da linha | Média |
| [ares] | Código do ares, `ares/sfc/cpu/dma.cpp` e `ares/sfc/cpu/timing.cpp`. https://github.com/ares-emulator/ares | Near e mantenedores do ares | Versão atual do repositório (lida em 02/11/2026) | Inicialização e flag interna do HDMA | Apoio: o próprio código marca o trecho como "needs hardware verification" |
| [Mesen2] | Código do Mesen2/MesenCE, `Core/SNES/SnesPpu.cpp` (`CanAccessCgram`, escrita em $2100) e `Core/SNES/SnesDmaController.cpp`. https://github.com/nesdev-org/MesenCE | Sour e colaboradores | Versão atual do repositório (lida em 02/11/2026) | Janela da CGRAM, momento do force blank, flag interna do HDMA | Apoio |
| [Teste local] | ROM de teste própria (sem conteúdo de jogo) montada com o asar 1.91 e rodada no MesenCE 2.2.1 pelo `--testRunner`, lendo a tela com `emu.getScreenBuffer()` | Feito para esta skill | 02/11/2026 | Esconder OBJ por Y e X, gradiente de HDMA, HDMA ligado no meio do quadro, force blank no meio da linha, montagem dos exemplos | Média: mostra o que o emulador faz, não o console real |

## Divergências registradas

| Ponto | O que cada fonte diz | O que vale e por quê |
|---|---|---|
| Bit de FastROM em `MEMSEL` ($420D) | [anomie memmap]: bit 1. [fullsnes], [SNESdev wiki] e [bsnes]: bit 0 | **Bit 0.** Três fontes independentes, incluindo um emulador de alta precisão |
| Escrita na CGRAM no hblank | [SNESdev wiki]: segura em vblank, hblank ou force blank. [fullsnes]: no hblank funciona só em parte do tempo. [bsnes] e [Mesen2]: errada só entre os pontos 22 e 273 das linhas visíveis | A janela dos emuladores explica as duas: o hblank inteiro fica dentro dela, mas uma escrita lenta da CPU pode passar do ponto 22. Para a CPU, usar vblank ou force blank; HDMA de cor no hblank funciona nos emuladores |
| HDMA ligado no meio do quadro | [superfamicom.org: registers]: começa no próximo ponto de HDMA, com A2A e NLTR escritos à mão. [ares] e [Mesen2]: o resultado depende de uma flag interna que só liga se algum canal estava ativo na linha 0 | Evitar; ligar no vblank com entrada de espera. Detalhe e teste em [dma-hdma.md](dma-hdma.md) |
| Tamanho máximo do LoROM | [fullsnes]: 2MB no arranjo comum. [SNESdev wiki]: até 4 MiB | Não é divergência real: os 4 MiB são o arranjo estendido que usa também os bancos 40-7D |
| Bancos da SRAM no HiROM | [fullsnes] (tabela de placas): 20-3F/A0-BF na maioria, outras variações. [SNESdev wiki]: 30-3F/B0-BF | Depende da placa. 30-3F:6000-7FFF cai dentro das duas descrições |
| Faixa 4200-5FFF | [fullsnes]: tudo a 6 clocks como área de registradores. [anomie memmap]: 4200-43FF registradores, 4400-5FFF livre | Mesma velocidade; só muda o nome |

## Não confirmado ou fora do escopo

- HDMA ligado no meio do quadro, janela da CGRAM no hblank e momento do force blank dentro da linha: documentados pelo código do [bsnes], do [ares] e do [Mesen2] e por teste no MesenCE, sem medição em console real.
- Data exata do documento de timing do anomie: o espelho não traz versão nem data.
- Offset-per-tile: documentado pelo [SNESdev wiki: Offset-per-tile], com o formato conferido no [fullsnes], mas não testado no Mesen.
- Tabela de prioridade entre camadas conferida só no [fullsnes] (sem divergência conhecida).
- Chips de cartucho (SA-1, SuperFX, DSP-n e outros) aparecem só em visão geral; o driver de som do SPC700 e o BRR em detalhe ficam de fora.
