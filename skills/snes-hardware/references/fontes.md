# Fontes da skill snes-hardware

Consultadas em 26/10/2026. Nível de confiança: **alta** = documentação de referência conferida em hardware ou usada por emuladores de precisão; **média** = boa, mas antiga ou com partes declaradas incompletas; **apoio** = usada só para desempatar um ponto.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [fullsnes] | Fullsnes, Nocash SNES Specs. https://problemkaputt.de/fullsnes.htm | Martin Korth (nocash) | Atualizado ao longo de anos; data da versão não conferida | Tudo: mapa de memória, I/O, DMA/HDMA, PPU, APU, controles, header, timing, chips de cartucho | Alta. Seções de offset-per-tile e alguns tempos finos são marcados como incompletos pelo próprio autor |
| [SNESdev wiki] | SNESdev Wiki. https://snes.nesdev.org/wiki/ (páginas Memory_map, MMIO_registers, PPU_registers, DMA_registers, Timing, CPU_vectors, Booting_the_SPC700) | Comunidade NESdev/SNESdev | Mantida continuamente (consulta em 2026) | Registradores, timing, vetores, boot do SPC700 | Alta |
| [anomie timing] | Anomie's SNES Timing Doc, espelho em https://wiki.superfamicom.org/timing e custos de DMA/HDMA em https://wiki.superfamicom.org/dma-and-hdma | anomie | Anos 2000 (data exata não conferida) | Timing de linha, refresh, custos de DMA e HDMA | Média: valores de overhead aproximados |
| [anomie memmap] | Anomie's SNES Memory Mapping Doc v1.1, espelho em https://wiki.superfamicom.org/memory-mapping | anomie | 2003 | Mapa por banco, velocidades, LoROM/HiROM | Média: tem o erro do bit do MEMSEL (ver abaixo) |
| [WDC datasheet] | W65C816S 8/16-bit Microprocessor Datasheet. https://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf | The Western Design Center | 2024 (revisão de 13/03/2024) | Núcleo 65C816: registradores, flags, estado no reset, vetores | Alta para o núcleo; não cobre o que é próprio do 5A22 |
| [bsnes] | Código do bsnes, `bsnes/sfc/cpu/io.cpp`. https://github.com/bsnes-emu/bsnes | byuu (Near) e colaboradores | Versão atual do repositório | Usado só para desempatar o bit do MEMSEL | Apoio |

## Divergências registradas

| Ponto | O que cada fonte diz | O que vale e por quê |
|---|---|---|
| Bit de FastROM em `MEMSEL` ($420D) | [anomie memmap]: bit 1. [fullsnes], [SNESdev wiki] e [bsnes]: bit 0 | **Bit 0.** Três fontes independentes, incluindo um emulador de alta precisão |
| Escrita na CGRAM no hblank | [SNESdev wiki]: segura em vblank, hblank ou force blank. [fullsnes]: no hblank funciona só numa janela curta | Para escrita pela CPU, usar só vblank ou force blank. HDMA de cor no hblank fica como técnica avançada, a testar em emulador de precisão |
| Tamanho máximo do LoROM | [fullsnes]: 2MB no arranjo comum. [SNESdev wiki]: até 4 MiB | Não é divergência real: os 4 MiB são o arranjo estendido que usa também os bancos 40-7D |
| Bancos da SRAM no HiROM | [fullsnes] (tabela de placas): 20-3F/A0-BF na maioria, outras variações. [SNESdev wiki]: 30-3F/B0-BF | Depende da placa. 30-3F:6000-7FFF cai dentro das duas descrições |
| Faixa 4200-5FFF | [fullsnes]: tudo a 6 clocks como área de registradores. [anomie memmap]: 4200-43FF registradores, 4400-5FFF livre | Mesma velocidade; só muda o nome |

## Não confirmado ou fora do escopo

- Ligar HDMA no meio do quadro: comportamento não totalmente conhecido nas fontes.
- Offset-per-tile em detalhe: o [fullsnes] marca como incompleto; só o princípio entra.
- Tempo exato da janela de escrita na CGRAM dentro do hblank.
- Momento exato, dentro da linha, em que a mudança do force blank passa a valer.
- Valor de Y "seguro" para esconder cada tamanho de OBJ (só uma fonte).
- Formato de tile, tilemap e OAM conferido só no [fullsnes] (sem divergência conhecida).
- Chips de cartucho (SA-1, SuperFX, DSP-n e outros) aparecem só em visão geral.
- Os exemplos em asar não foram montados nesta entrega (sem asar disponível para execução); a sintaxe segue a documentação do asar, mas precisa de uma montagem de conferência.
