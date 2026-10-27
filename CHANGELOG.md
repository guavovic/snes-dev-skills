# Mudanças

## v0.1

Primeira versão, com sete skills pesquisadas em fontes primárias (fullsnes, SNESdev wiki, documentos do anomie, datasheet da WDC, manual do asar, código do Mesen e do bsnes), cada uma com o seu `references/fontes.md`.

- **snes-hardware**: mapa de memória, CPU, PPU, DMA e HDMA, APU, controles e timing.
- **snes-assembly**: 65816 com asar, modos de endereçamento e tabela de opcodes.
- **snes-rom-hack**: cabeçalho, checksum, espaço livre, hooks e patches.
- **snes-desmontagem**: código e dado, trace, CDL e organização do projeto.
- **snes-graficos**: tiles, paletas, sprites, Mode 7, compressão e um script de conversão PNG.
- **snes-testes**: Mesen por linha de comando, testes em Lua e console real.
- **snes-tecnicas**: estrutura de jogo, efeitos de HDMA, color math e transições.
- Estrutura do repositório e plugin do Claude Code.

Os exemplos em asar foram revisados à mão, mas ainda não foram montados nem rodados em emulador. O que ficou sem confirmação está nas issues de sobras de cada skill.
