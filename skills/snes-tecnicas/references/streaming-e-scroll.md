# Scroll, paralaxe e streaming de tiles

Como a época rolava mapas maiores que a VRAM e montava profundidade com várias camadas. Tamanho do tilemap, endereço em words e VMAIN: snes-hardware/references/ppu-registradores.md e snes-graficos/references/tilemap-e-oam.md.

## Paralaxe com vários BGs

- Cada BG tem o seu par de scroll (BGnHOFS e BGnVOFS), escrito duas vezes (byte baixo e alto) [fullsnes]. No modo 1, o mais usado, há BG1 e BG2 de 4bpp e BG3 de 2bpp [fullsnes].
- Profundidade simples: a fase em BG1, o fundo distante em BG2 com scroll de uma fração da câmera (por exemplo metade), e BG3 para a barra de status ou nuvens.
- O jogo calcula o scroll de cada BG no laço, guarda em sombras na WRAM e a NMI escreve [SNESdev wiki: VBlank routine].
- Mais camadas do que BGs: paralaxe por faixa com HDMA no scroll de um BG só (ver [hdma-efeitos.md](hdma-efeitos.md)) [SNESdev wiki: HDMA examples].
- Camada na frente dos sprites (folhagem, grade): bit de prioridade no tilemap e ordem do modo [fullsnes]; ordem completa das camadas em snes-hardware/references/ppu-formatos.md.

## Mapa maior que a VRAM

O tilemap de um BG tem no máximo 64x64 tiles; uma fase maior que isso vive na ROM (ou descomprimida na WRAM) e entra na VRAM aos poucos [SNESdev wiki: Scrolling a large map]:

- O tilemap na VRAM funciona como um anel: a câmera anda, e a coluna (ou linha) que vai aparecer logo depois da borda é escrita por cima da que saiu do outro lado.
- **Detectar quando precisa de coluna nova**: guarde o X da câmera do quadro anterior e compare `(antigo XOR novo) AND tamanho_do_tile`; se o bit do tile mudou, a câmera cruzou uma borda de tile [SNESdev wiki: Scrolling a large map].
- O laço monta a coluna num buffer da WRAM e põe um pedido na fila de DMA; a NMI sobe [SNESdev wiki: Scrolling a large map][SNESdev wiki: VBlank routine].

## Coluna e linha de tilemap por DMA

- **Coluna**: VMAIN = `$81` (incremento de 32 words depois do byte alto, ou seja, uma linha do tilemap abaixo), DMA com DMAP `$01` para `$2118/$2119`, 64 bytes (32 tiles de 2 bytes). Depois volte VMAIN para `$80` [fullsnes][SNESdev wiki].
- **Linha**: VMAIN = `$80`, DMA contínuo. Num tilemap de 64 de largura a linha atravessa duas telas de 32x32, que ficam a `$400` words de distância; são dois DMAs [SNESdev wiki].
- Num tilemap de 64 de altura a coluna também passa de uma tela para a outra, então são dois pedidos.

## Streaming de tiles (CHR)

Tiles que mudam (animação de personagem grande, água animada, tiles da fase seguinte) podem ser enviados à VRAM sob demanda, em vez de deixar tudo carregado:

- O orçamento é o mesmo do vblank: uns 6 KB por quadro no NTSC de 224 linhas, cerca de 191 tiles de 4bpp, dividido com a OAM, a paleta e as colunas do tilemap [SNESdev wiki: Timing].
- Um personagem com muitos quadros de animação pode guardar só o quadro atual na VRAM e subir o próximo quando a animação troca, por um pedido na fila de DMA. Isso é uma consequência direta do orçamento acima; **não confirmado** em fonte de qual jogo da época fazia assim.
- Se o quadro não cabe, ganhe banda com vblank estendido (linhas pretas no topo e no fim) [undisbeliever] ou espalhe o upload por dois quadros, com buffer duplo na VRAM.
- Tiles comprimidos na ROM são descomprimidos na WRAM antes do DMA; formatos em snes-graficos/references/compressao.md. Jogos com S-DD1 ou SPC7110 tinham o chip fazendo isso (ver [chips-especiais.md](chips-especiais.md)).

Related: [hdma-efeitos.md](hdma-efeitos.md), [estrutura-do-jogo.md](estrutura-do-jogo.md), [exemplos.md](exemplos.md), [fontes.md](fontes.md)
