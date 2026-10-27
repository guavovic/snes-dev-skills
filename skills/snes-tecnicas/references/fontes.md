# Fontes

Consultadas em 26/10/2026. No texto, cada afirmação leva o rótulo entre colchetes. Detalhes de registrador que esta skill só aponta foram conferidos nas fontes das skills snes-hardware, snes-graficos e snes-assembly (ver o `fontes.md` de cada uma).

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [SNESdev wiki: Init code] | https://snes.nesdev.org/wiki/Init_code | comunidade SNESdev (NESdev) | consultada em 2026 | Ordem do init, limpeza de memória por DMA, rotina de reset de registradores e seus valores | Alta: wiki técnica revisada pela comunidade, bate com [fullsnes] |
| [SNESdev wiki: VBlank routine] | https://snes.nesdev.org/wiki/VBlank_routine | comunidade SNESdev | consultada em 2026 | Registradores sombra, flag de quadro, contador de lag, fila de DMA com limite, ordem da NMI, uma rotina por estado | Alta |
| [SNESdev wiki: VBlank interrupts] | https://snes.nesdev.org/wiki/VBlank_interrupts | comunidade SNESdev | consultada em 2026 | NMI curta e o que salvar na entrada | Alta |
| [SNESdev wiki: Timing] | https://snes.nesdev.org/wiki/Timing | comunidade SNESdev | consultada em 2026 | Linhas por quadro, master clocks por quadro, bytes de DMA por vblank (NTSC 224/239, PAL) | Alta |
| [SNESdev wiki: HDMA examples] | https://snes.nesdev.org/wiki/HDMA_examples | comunidade SNESdev | consultada em 2026 | Formato da tabela, TM por faixa, paralaxe por faixa, seno indireto, shear, cortina de caixa de texto, gradiente de CGRAM, buffer duplo, conflito de latch com M7A | Alta |
| [SNESdev wiki: Sprites] | https://snes.nesdev.org/wiki/Sprites | comunidade SNESdev | consultada em 2026 | Limites por linha, STAT77, esconder sprite, tabela alta com padrão fixo | Alta |
| [SNESdev wiki: Controller reading] | https://snes.nesdev.org/wiki/Controller_reading | comunidade SNESdev | consultada em 2026 | Auto-joypad, espera em $4212, recém-apertado | Alta |
| [SNESdev wiki: Color math] | https://snes.nesdev.org/wiki/Color_math | comunidade SNESdev | consultada em 2026 | Usos (transparência, sombra, névoa, tinta), paleta 4-7 dos sprites, half com sub-tela transparente | Alta |
| [SNESdev wiki: CGRAM] | https://snes.nesdev.org/wiki/CGRAM | comunidade SNESdev | consultada em 2026 | Formato BGR555 (via snes-graficos) | Alta |
| [SNESdev wiki: Windows] | https://snes.nesdev.org/wiki/Windows | comunidade SNESdev | consultada em 2026 | Encoding das janelas, uso com color math | Alta |
| [SNESdev wiki: Drawing window shapes] | https://snes.nesdev.org/wiki/Drawing_window_shapes | comunidade SNESdev | consultada em 2026 | Janela por HDMA em WH0/WH1, linha vazia com 255/0, meia largura pré-calculada | Alta |
| [SNESdev wiki: Mode 7 transform] | https://snes.nesdev.org/wiki/Mode_7_transform | comunidade SNESdev | consultada em 2026 | Matriz 8.8 e troca por linha | Alta |
| [SNESdev wiki: Scrolling a large map] | https://snes.nesdev.org/wiki/Scrolling_a_large_map | comunidade SNESdev | consultada em 2026 | Tilemap em anel, detecção de borda de tile, buffer e DMA no vblank | Alta |
| [SNESdev wiki] | https://snes.nesdev.org/wiki/DMA_examples e https://snes.nesdev.org/wiki/DMA_registers | comunidade SNESdev | consultada em 2026 | Coluna e linha de tilemap por DMA, prioridade do HDMA | Alta |
| [fullsnes] | https://problemkaputt.de/fullsnes.txt | Martin Korth (nocash) | versão consultada em 2026 | Registradores do PPU e da CPU, OAM, INIDISP, MOSAIC, DMA e bug de revisão, auto-joypad, chips especiais e listas de jogos | Alta para hardware; texto do campo de área das janelas embaralhado (ver divergências) |
| [undisbeliever] | https://undisbeliever.net/snesdev/registers/inidisp.html | undisbeliever | consultada em 2026 | Brilho e fade, force blank, glitch de INIDISP, 1-CHIP, vblank estendido por IRQ | Alta: autor com testes em hardware; ponto único para o glitch e o letterbox |
| [bsnes] | https://github.com/bsnes-emu/bsnes (`bsnes/sfc/ppu/io.cpp`, `window.cpp`) | byuu e colaboradores | código consultado em 2026 | Desempate do encoding das janelas e semântica de CGWSEL | Alta (emulador de alta precisão) |
| [Dizworld] | https://github.com/bbbradsmith/SNES_stuff/tree/main/dizworld | Brad Smith (CC BY 4.0) | consultado em 2026 | Perspectiva de Mode 7 por HDMA gerada pela CPU a 60 quadros, horizonte | Alta: código aberto que roda em hardware |
| [Clark] | http://www.6502.org/tutorials/65c816opcodes.html | Bruce Clark, 6502.org | revisão consultada em 2026 | `JSR (abs,X)` e transferências entre registradores de tamanhos diferentes | Alta (também fonte da snes-assembly) |
| [Mesen2] | https://github.com/SourMesen/Mesen2 | Sour | código consultado em 2026 | Banco do ponteiro de `JSR (abs,X)` | Alta (desempate, ver snes-assembly) |
| [Iwata Asks: Mario Kart Wii] | https://iwataasks.nintendo.com/interviews/wii/mariokart/0/0 | Nintendo (Satoru Iwata com a equipe) | 2008 | Origem de Super Mario Kart, tela de dois jogadores, personagens em vários ângulos por falta de memória | Alta para o relato; é memória de desenvolvedor, não documento técnico |
| [entrevista SNES Classic: Star Fox] | https://www.nintendo.com/en-gb/News/2017/September/Nintendo-Classic-Mini-SNES-developer-interview-Volume-1-Star-Fox-Star-Fox-2-1273086.html | Nintendo, com Miyamoto, Imamura e Watanabe | 2017 | Super FX, "Super NES isn't polygon hardware", custo por vértice, tempo do chip, Super FX 2 | Alta para o relato |
| [GameBusiness.jp: Super Metroid] | https://www.gamebusiness.jp/article/2017/09/16/13439.html | GameBusiness.jp | 16/09/2017 | Primeiro ano de Super Metroid gasto pesquisando o hardware | Média: imprensa, em japonês |
| [RGME] | https://sneslab.net/wiki/Retro_Game_Mechanics_Explained | sneslab.net, sobre o canal Retro Game Mechanics Explained | consultada em 2026 | Lista dos vídeos "Super NES Features" | Baixa para esta skill: vídeos não transcritos, só leitura recomendada |
| [Speaker Deck: kent-hamaguchi] | https://speakerdeck.com/kenthamaguchi/how-to-make-snes-rom | kent-hamaguchi | 2019 | Desenvolvimento para Super Famicom hoje | Baixa: autor recente; não usada para afirmação |

As 5 fontes principais: [SNESdev wiki] (várias páginas), [fullsnes], [undisbeliever], [Dizworld] e [bsnes].

## Divergências registradas

| Ponto | Uma fonte | Outra fonte | Adotado |
|---|---|---|---|
| Encoding do campo de área das janelas (2 bits por camada) | [fullsnes]: texto "0..1=Disable, 1=Inside, 2=Outside", embaralhado | [SNESdev wiki: Windows] e [bsnes]: bit 1 liga, bit 0 inverte (2 = dentro, 3 = fora) | [SNESdev wiki] e [bsnes], confirmado no código do bsnes; o mesmo encoding está na snes-hardware |
| Banco do ponteiro de `JSR (abs,X)` | Datasheet WDC, seção 3.5.2: banco 0 | [Clark], [Mesen2] e o próprio WDC na seção 7.9: banco do programa | Banco do programa (ver snes-assembly/references/fontes.md) |

## Não confirmado ou fora do escopo

- **Atores e máquina de estados**: não foi achado documento de estúdio da época descrevendo o seu sistema de objetos; o padrão está como arquitetura comum, sem atribuir a jogo.
- **Paleta de hora do dia e estação**: a técnica (cópia da CGRAM na WRAM, recalcular, DMA) é consequência das fontes, mas qual jogo comercial usava cada caminho não foi confirmado.
- **Streaming de quadros de animação**: decorre do orçamento de DMA; nenhum jogo específico confirmado.
- **Mode 7 com padrão 3 cobrindo dois registradores por canal**: dedução da tabela de padrões, sem exemplo publicado conferido.
- **Fade para branco por color math**: dedução do funcionamento da soma, sem exemplo publicado conferido.
- **Medir o quadro mudando a cor de fundo**: técnica conhecida, sem fonte primária.
- **Relato técnico em japonês de programador da época**: nada confiável achado. Um texto no kakuyomu (https://kakuyomu.jp/users/meikjy/news/16818093084663682415) foi descartado.
- **Vídeos do Retro Game Mechanics Explained**: só indicados, conteúdo não usado.
- **Exemplos em asar**: escritos à mão e não montados.
- Página "Tricks" da SNESdev wiki: deu 404 na consulta, não usada.

Related: [../SKILL.md](../SKILL.md)
