# Mudanças

## [Não lançado]

- **snes-testes**: Mesen rodado de verdade (print no terminal, `allowIoOsAccess`, chaves do `emu.getState()`, executável por sistema, receita conferida e exemplo de PowerShell corrigido para esperar o processo); FXPAK, usb2snes, Super EverDrive e snes9x com fonte oficial ou comparação registrada.
- **snes-assembly**: sintaxe do WLA-DX conferida no código, temporização de refresh, NMI e IRQ pelo bsnes, Eyes e Lichty e 6502.org como fontes, e todos os exemplos montados no asar 1.91 (hook agora com `autoclean`).
- **snes-hardware**: exemplos montados no asar e rodados no Mesen (tabela de vetores corrigida); HDMA ligado no meio do quadro, janela da CGRAM, force blank no meio da linha, offset-per-tile e Y e X para esconder OBJ documentados com código de emulador e teste próprio; datas das fontes conferidas.

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
