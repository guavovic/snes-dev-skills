# Fontes

Consultadas em 26/10/2026; as da v0.2 em 02/11/2026. No texto, cada afirmação leva o rótulo entre colchetes. Detalhes de registrador que esta skill só aponta foram conferidos nas fontes das skills snes-hardware, snes-graficos e snes-assembly (ver o `fontes.md` de cada uma).

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
| Independência das fontes do Harvest Moon | [HarvestMoonSnesDecomp: GUIDE] descreve a transição | [HM-Decomp] só dá nomes e endereços, e o guia parte dele | As duas batem (tabela em `$80:BB5C`, rotinas de troca por hora); vale o guia, pela verificação byte a byte [HarvestMoonSnesDecomp: README], registrado que não são independentes |
| [Iwata Asks: Mario Kart Wii] | https://iwataasks.nintendo.com/interviews/wii/mariokart/0/0 | Nintendo (Satoru Iwata com a equipe) | 2008 | Origem de Super Mario Kart, tela de dois jogadores, personagens em vários ângulos por falta de memória | Alta para o relato; é memória de desenvolvedor, não documento técnico |
| [entrevista SNES Classic: Star Fox] | https://www.nintendo.com/en-gb/News/2017/September/Nintendo-Classic-Mini-SNES-developer-interview-Volume-1-Star-Fox-Star-Fox-2-1273086.html | Nintendo, com Miyamoto, Imamura e Watanabe | 2017 | Super FX, "Super NES isn't polygon hardware", custo por vértice, tempo do chip, Super FX 2 | Alta para o relato |
| [GameBusiness.jp: Super Metroid] | https://www.gamebusiness.jp/article/2017/09/16/13439.html | GameBusiness.jp | 16/09/2017 | Primeiro ano de Super Metroid gasto pesquisando o hardware | Média: imprensa, em japonês |
| [RGME] | https://sneslab.net/wiki/Retro_Game_Mechanics_Explained | sneslab.net, sobre o canal Retro Game Mechanics Explained | consultada em 2026 | Lista dos vídeos "Super NES Features" | Baixa para esta skill: vídeos não transcritos, só leitura recomendada |
| [Speaker Deck: kent-hamaguchi] | https://speakerdeck.com/kenthamaguchi/how-to-make-snes-rom | kent-hamaguchi | 2019 | Desenvolvimento para Super Famicom hoje | Baixa: autor recente; não usada para afirmação |
| [Nintendo JP: F-ZERO] | https://topics.nintendo.co.jp/c/article/0e9c42d3-7d8a-11e7-8cda-063b7ac45a6d.html (hoje fora do ar; cópia em https://web.archive.org/web/20191213044242/https://topics.nintendo.co.jp/c/article/0e9c42d3-7d8a-11e7-8cda-063b7ac45a6d.html) | Nintendo, com Shimizu, Nishida e Imamura | 2017 | Experimento de Mode 7 que virou F-ZERO, chão girando com paisagem em cima, carros desenhados em vários ângulos | Alta para o relato; em japonês, memória de desenvolvedor |
| [Nintendo JP: Super Mario Kart] | https://topics.nintendo.co.jp/c/article/3228ce3a-8d29-11e7-8cda-063b7ac45a6d.html (cópia em https://web.archive.org/web/20191213045717/https://topics.nintendo.co.jp/c/article/3228ce3a-8d29-11e7-8cda-063b7ac45a6d.html) | Nintendo, com Sugiyama e Konno | 2017 | Esforço para usar ampliar, reduzir e girar no jogo | Alta para o relato; em japonês |
| [NESdev BBS: CPU usage meter] | https://nesdev.nes.science/f12/t12419.xhtml (cópia do tópico "SNES CPU usage meter" do fórum NESdev) | fórum NESdev | 23 e 24/02/2015 | Medir o quadro por brilho, cor 0, cor fixa ou leitura da linha por SLHV/OPVCT | Média: fórum, com autores experientes; confere com [fullsnes] |
| [OpenSNES: profile.h] | https://k0b3n4irb.github.io/opensnes/profile_8h.html | projeto OpenSNES | consultada em 2026 | Medidor de quadro somando a cor fixa no backdrop | Média: biblioteca atual, não da época; confirma o método |
| [sneslab: DMA channel usage in SMW] | https://sneslab.net/wiki/DMA_channel_usage_in_SMW | comunidade sneslab | consultada em 2026 | Canal 2 de DMA sobe os gráficos do jogador em Super Mario World | Média: documentação de fãs a partir da desmontagem |
| [sneslab: Dynamic X] | https://sneslab.net/wiki/Dynamic_X | comunidade sneslab | consultada em 2026 | O jogo original sobe gráficos do jogador, Yoshi e podoboos sempre; a biblioteca só quando precisa | Média: documentação de fãs |
| [Superfamicom wiki: Using DMA effectively] | https://wiki.superfamicom.org/using-dma-effectively | comunidade superfamicom.org | consultada em 2026 | Comparar quadro pedido com o carregado, animação a 30 quadros, limite de DMA por quadro | Média: wiki técnica sem autor |
| [HM-Decomp] | https://github.com/ElisaS-Codes/HM-Decomp (`BankMap.txt` e `RamMap.txt`) | ElisaS-Codes e DasK | 2023-2024 | Nomes e endereços das rotinas e da tabela de paleta por hora do dia e do contador de troca de paleta no Harvest Moon | Média: desmontagem de fãs, rotinas marcadas como entendidas; só os mapas de texto foram lidos, não o código |
| [HarvestMoonSnesDecomp: GUIDE] | https://github.com/RodoLy/HarvestMoonSnesDecomp/blob/main/GUIDE.md (seções 5.2, 5.11 e 5.19) | Rodrigo (RodriLoy) | versão de 02/11/2026 | Faixas de hora com paleta por mapa, três cópias na WRAM, passo de um por canal a cada 32 quadros, metade dos BGs e dos sprites, mapa por estação | Média/alta: guia de uma reimplementação conferida contra o jogo; parte do HM-Decomp, então não é fonte independente |
| [HarvestMoonSnesDecomp: README] | https://github.com/RodoLy/HarvestMoonSnesDecomp/blob/main/README.md | Rodrigo (RodriLoy) | versão de 02/11/2026 | Método de verificação: cada rotina comparada com o jogo (memória, registradores da CPU e do DMA) | Média/alta |
| [VG Resource: Breath of Fire 2] | https://www.vg-resource.com/thread-43428.html (lido na cópia do Internet Archive de 16/04/2025) | fórum The VG Resource, tópico de 27/02/2025 | 2025 | Código de trapaça de "sempre dia" no mapa do mundo, faixa de valores da hora, paletas extraídas entre dia e noite | Baixa: observação de quem fez a trapaça, sem explicar o código |
| [Teste local] | Montagem no asar 1.91 e execução no Mesen 2.2.1 (`--testRunner`, ROM vazia própria, scripts Lua) | feito para esta skill | 02/11/2026 e 03/11/2026 | Todos os trechos de exemplos.md, o bug do fade de saída, a conta da esquerda para a direita do asar e o custo do passo de paleta | Alta para o comportamento no emulador; não é hardware real |

As 5 fontes principais: [SNESdev wiki] (várias páginas), [fullsnes], [undisbeliever], [Dizworld] e [bsnes].

## Divergências registradas

| Ponto | Uma fonte | Outra fonte | Adotado |
|---|---|---|---|
| Encoding do campo de área das janelas (2 bits por camada) | [fullsnes]: texto "0..1=Disable, 1=Inside, 2=Outside", embaralhado | [SNESdev wiki: Windows] e [bsnes]: bit 1 liga, bit 0 inverte (2 = dentro, 3 = fora) | [SNESdev wiki] e [bsnes], confirmado no código do bsnes; o mesmo encoding está na snes-hardware |
| Banco do ponteiro de `JSR (abs,X)` | Datasheet WDC, seção 3.5.2: banco 0 | [Clark], [Mesen2] e o próprio WDC na seção 7.9: banco do programa | Banco do programa (ver snes-assembly/references/fontes.md) |

## Não confirmado ou fora do escopo

- **Atores e máquina de estados**: não foi achado documento de estúdio da época descrevendo o seu sistema de objetos; o padrão está como arquitetura comum, sem atribuir a jogo.
- **Hora do dia em outros jogos**: só o Harvest Moon tem o caminho descrito em texto técnico. Para Breath of Fire II há só a observação de um código de trapaça [VG Resource: Breath of Fire 2]; Seiken Densetsu 3, Terranigma e Lufia não têm descrição achada (busca de 03/11/2026 no GitHub, em fóruns e em japonês).
- **Vídeos do Retro Game Mechanics Explained**: sem transcrição achada; ficam só como leitura, porque o conteúdo já está coberto por [fullsnes] e pela [SNESdev wiki].
- **Página "Tricks" da SNESdev wiki**: deu 404 em 2026; em 02/11/2026 a busca no site e no índice do archive.org (prefixo `snes.nesdev.org/wiki/Trick`) só achou outra página ("Tricky-to-emulate games"). Não há cópia arquivada, então foi descartada.
- Um texto no kakuyomu (https://kakuyomu.jp/users/meikjy/news/16818093084663682415) foi descartado como relato em japonês.

## Resolvido na v0.2

- **Exemplos em asar**: montados e testados no Mesen [Teste local]; o fade de saída tinha um bug e foi corrigido.
- **Mode 7 com padrão 3 em dois registradores por canal**: [fullsnes], [Dizworld] e [Teste local].
- **Fade para branco por color math**: [fullsnes], [SNESdev wiki: Color math] e [Teste local].
- **Medir o quadro pela cor de fundo**: [NESdev BBS: CPU usage meter], [OpenSNES: profile.h] e [Teste local]. Não é fonte da época, mas o método está descrito e conferido.
- **Streaming de quadros de animação**: caso de Super Mario World [sneslab: DMA channel usage in SMW][sneslab: Dynamic X] e o método de [Superfamicom wiki: Using DMA effectively].
- **Relato técnico em japonês**: entrevistas de 2017 da Nintendo [Nintendo JP: F-ZERO][Nintendo JP: Super Mario Kart].

## Resolvido na v0.3

- **Paleta de hora do dia e estação num jogo da época** (issue #35): caso do Harvest Moon pelo guia da reimplementação em C e pelos mapas da desmontagem [HarvestMoonSnesDecomp: GUIDE][HM-Decomp], com exemplo próprio em asar testado no Mesen [Teste local].

Related: [../SKILL.md](../SKILL.md)
