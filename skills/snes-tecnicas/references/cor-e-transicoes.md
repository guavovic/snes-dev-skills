# Cor, luz e transições

Color math, troca de paleta, fade e mosaico. Bits de CGWSEL, CGADSUB, COLDATA, janelas, INIDISP e MOSAIC: snes-hardware/references/ppu-registradores.md. Formato BGR555 e divisão da CGRAM: snes-graficos/references/paletas-e-cor.md.

## Color math

O PPU monta duas imagens, a tela principal (TM) e a sub-tela (TS) ou a cor fixa (COLDATA), e soma ou subtrai uma da outra, com opção de dividir por 2 [fullsnes][SNESdev wiki: Color math]. Usos da época, segundo a wiki:

- **Transparência a 50%**: água, vidro, fantasma, nuvem por cima da fase. A camada transparente vai para a sub-tela (ou a principal, conforme o caso) e o color math faz a média [SNESdev wiki: Color math].
- **Sombra**: subtração na área da sombra (um BG ou sprite com paleta 4-7 que escurece o que está atrás) [SNESdev wiki: Color math].
- **Névoa no horizonte**: soma da cor fixa com um degradê de COLDATA por HDMA (ver [hdma-efeitos.md](hdma-efeitos.md)) [SNESdev wiki: Color math].
- **Tinta na tela inteira**: subtrair ou somar uma cor fixa a tudo dá um tom de noite, de pôr do sol ou de flash, sem mexer na paleta [SNESdev wiki: Color math].

Limites que pegam [SNESdev wiki: Color math][fullsnes]:

- Sprite só entra no color math se usar paleta 4-7 (cores `$C0-$FF`).
- Sprite não mistura com sprite: o math é entre a tela principal e a sub-tela, e sprites ficam na mesma camada.
- Nos modos 5 e 6 não há soma nem subtração.
- O "dividir por 2" é ignorado onde o pixel da sub-tela é transparente (aí entra o backdrop sem metade), o que evita a imagem escurecer onde a camada de cima não tem nada.

## Escurecer fora da luz

Combina janela com color math [SNESdev wiki: Windows][fullsnes][bsnes]:

- Desenhe a janela com a forma da luz (círculo por HDMA, ver [hdma-efeitos.md](hdma-efeitos.md)).
- **Escuro parcial**: CGWSEL bits 5-4 = 2 (math só fora da janela de cor), CGADSUB em subtração, COLDATA com a cor a subtrair. Fora da luz tudo fica mais escuro; dentro fica normal.
- **Escuro total**: CGWSEL bits 7-6 = 1, que força a tela principal a preto fora da janela de cor.
- Encoding do campo de área das janelas: bit 1 liga, bit 0 inverte [SNESdev wiki: Windows][bsnes].

## Paleta de hora do dia e estação

Técnica: guardar a paleta "de base" na ROM e uma cópia de trabalho da CGRAM (512 bytes) na WRAM. Quando a hora muda, recalcular a cópia e subir por DMA no vblank (destino CGDATA, ver snes-hardware/references/dma-hdma.md) [SNESdev wiki: VBlank routine].

- Cada cor é BGR555: 5 bits por canal [SNESdev wiki: CGRAM]. Para escurecer ou tingir, separe os canais, aplique a regra a cada um (multiplicar por um fator, somar um tom e limitar em 0-31, ou interpolar até uma paleta alvo) e junte de novo.
- Interpolar entre duas paletas prontas (dia e noite, verão e inverno) dá mais controle artístico do que uma fórmula: o artista escolhe as cores de cada momento e o código só faz a transição em alguns quadros.
- Recalcular 256 cores em um quadro pesa na CPU; espalhe por vários quadros (algumas paletas por quadro) e suba só as paletas que mudaram.
- Alternativa sem recalcular: tinta por color math com a cor fixa (seção anterior), barata e global, mas afeta tudo por igual e esbarra nos limites do color math.
- Estação também pode trocar tiles (neve no chão, folhas), por streaming (ver [streaming-e-scroll.md](streaming-e-scroll.md)).

Quais jogos da época usavam cada caminho para hora do dia ou estação **não foi confirmado** em fonte técnica; fica como técnica, sem atribuir a jogo.

## Fade de brilho

- INIDISP (`$2100`) bits 3-0 são o brilho mestre: com valor N, a imagem sai com intensidade de (N+1)/16 [fullsnes]. O fade padrão é somar ou subtrair 1 no brilho por quadro (ou a cada 2 quadros) na sombra de INIDISP que a NMI escreve [undisbeliever].
- **Brilho 0 não é preto garantido**: termine o fade com force blank (bit 7) antes de mexer em VRAM ou trocar a cena [undisbeliever][fullsnes].
- **Glitch de INIDISP**: o PPU pode reagir a um valor que passa no barramento antes da escrita de verdade. A saída recomendada é escrever por endereço longo cujo banco é o próprio valor: `sta $802100` para ligar o force blank (com A = `$80`) e `sta $0f2100` para desligar (com A = `$0F`) [undisbeliever]. Isso exige que o banco `$80` ou `$0F` espelhe os registradores, o que vale nos bancos `$00-$3F` e `$80-$BF` (snes-hardware/references/mapa-de-memoria.md).
- No console de placa 1-CHIP, ligar o force blank com `$80` e depois sair com `$0F` dá uma faixa de degradê com glitch; mantenha os bits de brilho ligados no valor de force blank (`$8F`) [undisbeliever].
- Fade para branco não sai do brilho mestre. Uma saída é color math somando a cor fixa a tudo e subindo COLDATA até o branco; é dedução do funcionamento da soma [SNESdev wiki: Color math], sem exemplo publicado conferido.

## Mosaico

- MOSAIC (`$2106`): bits 7-4 são o tamanho do bloco (1 a 16 pixels), bits 3-0 ligam por BG [fullsnes].
- Transição clássica: aumentar o tamanho do mosaico a cada quadro enquanto faz o fade, trocar a cena em force blank e desfazer ao contrário.
- Mudar o mosaico no meio da tela (por IRQ ou HDMA) é possível, mas o PPU termina o bloco atual com o tamanho vertical antigo antes de aplicar o novo [fullsnes].
- Os bits de liga só existem para BG1-BG4; sprites não têm mosaico [fullsnes].

Related: [hdma-efeitos.md](hdma-efeitos.md), [estrutura-do-jogo.md](estrutura-do-jogo.md), [exemplos.md](exemplos.md), [fontes.md](fontes.md)
