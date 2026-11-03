# Mudanças

## [Não lançado]

- **snes-tecnicas**: paleta de hora do dia e estação com caso documentado (Harvest Moon, pela desmontagem e pelo guia da reimplementação em C) e exemplo novo em asar, testado no Mesen, que leva a paleta até a alvo um passo por canal, em fatias por quadro.
- **snes-assembly**, **snes-rom-hack**, **snes-tecnicas**, **snes-testes**: conta sem precedência do asar 1.x documentada como armadilha (`asar 1.90` com dois dígitos, define, divisão) e conferida em todos os blocos das sete skills; callback de memória do Mesen disparando nas escritas do DMA e do HDMA registrado como armadilha, com teste próprio (#37).

## v0.2

Revisão das sete skills: todos os exemplos em asar foram montados no asar 1.91 e rodados no Mesen 2.2.1 com ROM própria, as pendências da v0.1 foram conferidas no código dos emuladores e em fonte oficial, e o que não fechou foi para issues com o marco v0.3.

- **snes-testes**: Mesen rodado de verdade (print no terminal, `allowIoOsAccess`, chaves do `emu.getState()`, executável por sistema, receita conferida e exemplo de PowerShell corrigido para esperar o processo); FXPAK, usb2snes, Super EverDrive e snes9x com fonte oficial ou comparação registrada.
- **snes-assembly**: sintaxe do WLA-DX conferida no código, temporização de refresh, NMI e IRQ pelo bsnes, Eyes e Lichty e 6502.org como fontes, e todos os exemplos montados no asar 1.91 (hook agora com `autoclean`).
- **snes-graficos**: formato do LC_LZ11 por duas implementações abertas, números do Lunar Compress conferidos no pacote oficial v2.00, LZSS.C de Okumura e as variantes de jogos de SNES, expansão de 1bpp conferida no Mesen, documento do Klarth lido inteiro e formatos do YY-CHR pela página oficial em japonês.
- **snes-hardware**: exemplos montados no asar e rodados no Mesen (tabela de vetores corrigida); HDMA ligado no meio do quadro, janela da CGRAM, force blank no meio da linha, offset-per-tile e Y e X para esconder OBJ documentados com código de emulador e teste próprio; datas das fontes conferidas.
- **snes-rom-hack**: projeto mínimo montado no asar 1.91 e rodado no Mesen, checksum de tamanho irregular comparado entre asar, Snes9x e SNESdev, ExLoROM e SRAM conferidos no código do Mesen, Snes9x e FXPAK, regras de envio oficiais do SMW Central e organização do z3randomizer como referência.
- **snes-desmontagem**: CDL do Mesen conferido rodando (operando marcado como código), motivo de o DiztinGUIsh não importá-lo e caminho de conversão, sintaxe da condição do trace logger lida no código, Capstone avaliado contra ROM própria e guiado pelo CDL, e a desmontagem do Super Metroid que monta (InsaneFirebat) conferida.
- **snes-tecnicas**: exemplos montados no asar 1.91 e conferidos no Mesen (fade de saída corrigido), exemplos novos de fade para branco, Mode 7 com padrão 3 e medidor do quadro, streaming de animação com caso documentado e relato em japonês das entrevistas de F-ZERO e Super Mario Kart.

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
