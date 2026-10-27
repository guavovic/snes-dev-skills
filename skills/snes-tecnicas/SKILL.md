---
name: snes-tecnicas
description: Técnicas que os jogos comerciais de Super Nintendo (SNES / Super Famicom) usavam, explicadas para quem programa em assembly 65816 com asar. Use quando a tarefa for montar a estrutura de um jogo (init seguro, laço principal, NMI curta, fila de DMA para VRAM, CGRAM e OAM no vblank, buffer de OAM com a tabela alta, leitura de controle e botão recém-apertado), organizar atores e máquina de estados, medir orçamento de tempo por quadro (lag, slowdown, vblank estendido), fazer efeitos de HDMA (degradê no céu, ondulação de água e calor, paralaxe por faixa, perspectiva de Mode 7 e pseudo 3D, janela em forma de círculo para foco de luz ou lanterna, cortina de caixa de texto), usar color math (transparência, sombra, névoa, escurecer fora da luz), trocar paleta para hora do dia ou estação, fazer fade de brilho e mosaico de transição, rolar mapa grande com streaming de tiles, decidir se precisa de chip especial (SA-1, Super FX, DSP-1, CX4, S-DD1) ou entender o que os desenvolvedores da época contaram. Também serve para perguntas como "como o jogo faz a água ondular", "por que meu jogo dá lag", "como fazer um holofote", "como escurecer a tela aos poucos" ou "como o Mario Kart faz a pista".
---

# snes-tecnicas

Como os jogos da época resolviam problemas comuns no SNES, com o porquê e um exemplo curto em asar. Esta skill fala de **técnica e organização**; os registradores bit a bit ficam nas outras skills do repositório, e os references apontam para elas em vez de repetir:

- **snes-hardware**: registradores do PPU, DMA/HDMA, NMI/IRQ, timing, controle, chips do cartucho.
- **snes-graficos**: formato de tile, paleta BGR555, tilemap, OAM, compressão.
- **snes-assembly**: instruções, ciclos, modos de endereçamento, pilha e interrupções.
- **snes-rom-hack**: asar, espaço livre e hooks quando a técnica entra numa ROM existente.

Toda afirmação técnica tem fonte entre colchetes (`[SNESdev wiki]`, `[fullsnes]`...), listadas em [references/fontes.md](references/fontes.md) com as divergências. Os exemplos são originais e **não foram montados** (não havia asar na máquina de quem escreveu); confira antes de usar.

## Visão geral

- **Um quadro, duas metades.** O laço principal roda a lógica durante a tela e só prepara dados em buffers na WRAM; a NMI, no vblank, copia esses buffers para VRAM, CGRAM e OAM por DMA e escreve os registradores "sombra". Quem respeita essa divisão não tem lixo na tela [SNESdev wiki: VBlank routine].
- **O vblank é curto.** No NTSC de 224 linhas cabem uns 6 KB de DMA por quadro; tudo o que muda na tela disputa esse espaço [SNESdev wiki: Timing].
- **HDMA é o truque mais barato.** Ele troca de 1 a 4 bytes de registrador por linha sem gastar CPU durante a tela; degradê, ondulação, paralaxe por faixa, perspectiva de Mode 7 e janelas em forma de círculo saem daí [SNESdev wiki: HDMA examples].
- **Color math e janelas** fazem transparência, sombra e luz; o brilho de INIDISP faz fade; o mosaico faz transição [SNESdev wiki: Color math][fullsnes].
- **Chip no cartucho** foi a saída quando a CPU não dava conta (polígonos, rotação de sprites, descompressão) [fullsnes].

## Regras de ouro

1. **A NMI só transfere quando o laço principal terminou o quadro.** Use uma flag: o laço liga, a NMI confere, transfere e desliga. Sem a flag, a NMI copia buffer pela metade; com ela, quadro atrasado vira um quadro de lag contado, não lixo [SNESdev wiki: VBlank routine].
2. **Na NMI, o que precisa estar pronto antes da linha 0 vem primeiro** (DMA, HDMAEN, scroll); controle e contadores por último [SNESdev wiki: VBlank routine].
3. **Fila de DMA com limite de bytes por quadro.** Pedido que não cabe espera o próximo quadro; não estoure o vblank [SNESdev wiki: VBlank routine][SNESdev wiki: Timing].
4. **OAM inteiro de uma vez:** buffer de 544 bytes na WRAM, um DMA por quadro, sprite sem uso escondido em Y=224 [fullsnes][SNESdev wiki: Sprites].
5. **Tabela de HDMA que muda precisa de buffer duplo**, e HDMAEN só se liga no vblank [SNESdev wiki: HDMA examples].
6. **Canal de HDMA não serve para DMA geral no mesmo quadro**, e o HDMA tem prioridade sobre o DMA [fullsnes][SNESdev wiki].
7. **Fade é brilho, mas o fim é force blank:** brilho 0 ainda não é preto garantido; termine com `$80` em INIDISP [fullsnes][undisbeliever].
8. **Meça o tempo do quadro** antes de otimizar: contador de lag na NMI [SNESdev wiki: VBlank routine]; o resto do método está em [references/estrutura-do-jogo.md](references/estrutura-do-jogo.md).

## Armadilhas

- NMI que roda durante um DMA longo pode cair fora do vblank [fullsnes].
- Esquecer de voltar VMAIN para `$80` depois de subir uma coluna de tilemap com incremento de 32 deixa o próximo upload torto [fullsnes][SNESdev wiki].
- HDMA em BG1HOFS pode estragar uma escrita dupla de M7A feita pela CPU no mesmo momento, porque o latch é compartilhado [SNESdev wiki: HDMA examples].
- Em algumas revisões do console, um DMA que termina bem quando um HDMA começa trava a máquina [fullsnes]. Detalhe em snes-hardware/references/dma-hdma.md.
- Mais de 32 sprites ou 34 fatias de 8 pixels numa linha somem; a época contornava com flicker girando a prioridade da OAM [fullsnes][SNESdev wiki: Sprites].
- Sprite só entra no color math com paleta 4-7, e sprite não mistura com sprite [SNESdev wiki: Color math].
- Mexer em INIDISP para force blank tem glitch de leitura antecipada; escreva por endereço longo com o banco certo (ver [references/cor-e-transicoes.md](references/cor-e-transicoes.md)) [undisbeliever].

## Índice dos references

| Arquivo | Conteúdo |
|---|---|
| [estrutura-do-jogo.md](references/estrutura-do-jogo.md) | Init seguro, reset de registradores por cena, laço principal, NMI, flag de quadro, fila de DMA, OAM shadow e tabela alta, controle, atores e máquina de estados, orçamento e lag, vblank estendido |
| [hdma-efeitos.md](references/hdma-efeitos.md) | Degradê, ondulação de água e calor, paralaxe por faixa, perspectiva de Mode 7, janela em círculo (foco de luz), cortina de caixa de texto |
| [cor-e-transicoes.md](references/cor-e-transicoes.md) | Color math (transparência, sombra, névoa, tinta), escurecer fora da janela, paleta de hora do dia e estação, fade de brilho, mosaico |
| [streaming-e-scroll.md](references/streaming-e-scroll.md) | Paralaxe com vários BGs, mapa maior que a VRAM, coluna e linha de tilemap por DMA, streaming de tiles |
| [chips-especiais.md](references/chips-especiais.md) | Quando a época usou chip: SA-1, Super FX, DSP-n, CX4, S-DD1, SPC7110, OBC1, com jogos de exemplo |
| [desenvolvedores.md](references/desenvolvedores.md) | O que os desenvolvedores contaram em entrevistas (Super Mario Kart, Star Fox, Super Metroid) e o que não foi achado em japonês |
| [exemplos.md](references/exemplos.md) | Código original em asar: NMI com flag, fila de DMA, controle, gradiente, onda, foco de luz, fade |
| [fontes.md](references/fontes.md) | Fontes, confiança, divergências e o que ficou de fora |
