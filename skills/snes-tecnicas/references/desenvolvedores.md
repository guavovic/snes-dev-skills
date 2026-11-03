# O que os desenvolvedores da época contaram

Relatos de quem fez jogos de SNES, em entrevistas publicadas pela Nintendo ou pela imprensa. Servem para entender **por que** uma técnica foi escolhida; o como está nos outros references. Citações curtas, com a fonte; o resto é paráfrase.

## Super Mario Kart (1992)

Fonte: Iwata Asks, Mario Kart Wii, vol. 0, parte 0 [Iwata Asks: Mario Kart Wii].

- O jogo nasceu da vontade de ter uma tela de **dois jogadores** ao mesmo tempo. A velocidade do F-Zero não era possível com a tela dividida em dois, e daí veio um jogo de kart, mais lento.
- Os personagens são sprites desenhados em vários ângulos, escolhidos conforme a direção da câmera (o que hoje se chama billboard), porque não havia memória para mais.
- Técnica relacionada: perspectiva de Mode 7 por HDMA ([hdma-efeitos.md](hdma-efeitos.md)) e DSP-1 no cartucho ([chips-especiais.md](chips-especiais.md)) [fullsnes].

## Star Fox (1993) e Star Fox 2

Fonte: entrevista dos desenvolvedores do Super NES Classic Edition, volume 1, com Shigeru Miyamoto, Imamura e Watanabe [entrevista SNES Classic: Star Fox].

- "Super NES isn't polygon hardware": o console não foi feito para polígonos, e cada vértice a mais custava processamento.
- O chip Super FX levou cerca de dois anos para ficar pronto.
- O Super FX 2 dobrou a memória e também o preço do cartucho.
- Técnica relacionada: [chips-especiais.md](chips-especiais.md).

## Super Metroid (1994)

Fonte: entrevista publicada pelo GameBusiness.jp em 16/09/2017 [GameBusiness.jp: Super Metroid].

- O primeiro ano do projeto foi gasto pesquisando o hardware, antes de produzir o jogo de fato.

## Em japonês

### F-ZERO: o experimento de Mode 7 (entrevista da Nintendo, 2017)

Na série de entrevistas de lançamento do Nintendo Classic Mini: Super Famicom, publicada em japonês no site da Nintendo, a equipe de F-ZERO (Shimizu, Nishida e Imamura) conta como o jogo nasceu [Nintendo JP: F-ZERO]:

- Os programadores novos recebiam cada um um tema de experimento com as funções do Super Famicom, e o tema de Nishida era uma corrida usando o Mode 7. Ele explica que o console tinha os modos 0 a 7 e que o 7 era o que fazia "背景の拡大・縮小・回転" (ampliar, reduzir e girar o fundo).
- Shimizu descreve a demo: girar cerca de quatro quintos de baixo da tela e mostrar a paisagem distante no quinto de cima. É a divisão que esta skill descreve em [hdma-efeitos.md](hdma-efeitos.md): chão em Mode 7 e outra coisa acima do horizonte.
- Os carros eram sprites desenhados à mão, um por um, em vários ângulos, porque ainda não havia polígonos; rodas animadas multiplicariam o número de desenhos, e por isso as naves flutuam sem rodas. O mesmo motivo de memória aparece no relato de Super Mario Kart [Iwata Asks: Mario Kart Wii].

Na entrevista de Super Mario Kart da mesma série, Sugiyama diz que o console se vendia por "ampliar, reduzir e girar" e que a equipe penou para transformar essa função em jogo [Nintendo JP: Super Mario Kart].

É relato de memória, mais de 25 anos depois, e não documento técnico: serve para o porquê das escolhas, não para detalhe de registrador.

### O que foi descartado

- Uma apresentação no Speaker Deck (kent-hamaguchi, 2019) fala de desenvolvimento para Super Famicom, mas é de autor recente e não de programador da época: baixa confiança, não usada para afirmação técnica.
- Um texto no kakuyomu foi descartado (ficção ou relato sem fonte).

## Leitura recomendada (não transcrita)

A série "Super NES Features" do canal Retro Game Mechanics Explained (Objects, Color Math, Lag & Blanking, DMA & HDMA, Mode 7) é listada pelo sneslab.net como boa explicação visual [RGME]. O conteúdo dos vídeos **não foi transcrito nem conferido** para esta skill; nenhuma afirmação daqui depende deles. Em 02/11/2026 foi procurada transcrição ou descrição detalhada dos vídeos e só se achou a descrição curta de cada um; como o que eles explicam (OAM, color math, DMA e HDMA, Mode 7) já está coberto por [fullsnes] e pela [SNESdev wiki: HDMA examples], eles ficam só como leitura.

Related: [chips-especiais.md](chips-especiais.md), [hdma-efeitos.md](hdma-efeitos.md), [fontes.md](fontes.md)
