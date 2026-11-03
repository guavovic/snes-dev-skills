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
- Recalcular 256 cores em um quadro pesa na CPU: no Mesen, um passo por canal nas 256 cores custou mais de um quadro [Teste local]. Espalhe por vários quadros (algumas paletas por quadro) e suba só as paletas que mudaram.
- Alternativa sem recalcular: tinta por color math com a cor fixa (seção anterior), barata e global, mas afeta tudo por igual e esbarra nos limites do color math.
- Estação também pode trocar tiles (neve no chão, folhas), por streaming (ver [streaming-e-scroll.md](streaming-e-scroll.md)).

### Caso documentado: Harvest Moon

A desmontagem aberta do Harvest Moon (HM-Decomp) e o guia da reimplementação em C que parte dela (HarvestMoonSnesDecomp, conferida contra o jogo byte a byte) descrevem o caminho do jogo para a hora do dia [HM-Decomp][HarvestMoonSnesDecomp: GUIDE]. Resumo com as nossas palavras, sem código do jogo:

- **Uma paleta pronta por parte do dia, por mapa.** Uma tabela na ROM (`$80:BB5C`) dá a cada mapa uma paleta para cada faixa de hora (antes das 7h, 7h-14h59, 15h-16h59, 17h-17h59 e das 18h em diante); um valor reservado diz "mantém a que está", o que deixa os interiores sem mudança [HarvestMoonSnesDecomp: GUIDE]. A tabela aparece com o nome `Time_Palette_Table` no mapa de bancos do HM-Decomp [HM-Decomp].
- **Três cópias na WRAM:** a que vai para a CGRAM, uma em preparo (a da noite) e a que está na tela [HarvestMoonSnesDecomp: GUIDE].
- **Transição lenta por passos, não fórmula.** Quando a hora entra em outra faixa, o jogo aponta a paleta alvo; uma rotina que roda todo quadro, a cada 32 quadros, move cada cor um passo em vermelho, verde e azul na direção do alvo e manda a cópia por DMA. Quando nenhuma cor muda, a transição acabou. A troca inteira pode levar 31 x 32 quadros, uns 16 segundos [HarvestMoonSnesDecomp: GUIDE]. O HM-Decomp chama essas rotinas de `SetTimeofDayPalette` e `TransitionTimeofDayPalettes` e tem na RAM um contador de troca de paleta (`$7E:017A`) [HM-Decomp].
- **Nem tudo escurece.** Antes das 18h só a metade dos BGs muda; a partir das 18h, a dos sprites também, com uma paleta de sprites de noite por mapa. As primeiras cores, que parecem ser as da caixa de texto, ficam de fora [HarvestMoonSnesDecomp: GUIDE].
- **Estação é outro mapa.** A fazenda tem um mapa por estação (mapas 0 a 3), e só três cores de uma paleta de sprites mudam com a estação [HarvestMoonSnesDecomp: GUIDE]. Ou seja, a estação troca tiles e paleta junto com o mapa, enquanto a hora do dia troca só a paleta.

As duas fontes não são independentes: o guia parte da desmontagem e credita os nomes a ela. O que dá peso ao guia é a verificação byte a byte da reimplementação contra o jogo [HarvestMoonSnesDecomp: README]. Não houve conferência própria na ROM, porque a regra do repositório não usa jogo comercial. O exemplo de [exemplos.md](exemplos.md) segue o mesmo caminho com código nosso, testado no Mesen [Teste local].

Para outros jogos com dia e noite, não foi achado texto técnico: em Breath of Fire II só há a descrição de um código de trapaça (um valor de hora de `$00` a `$7F` no mapa do mundo) e paletas extraídas por fãs para cada momento entre dia e noite, o que mostra o efeito mas não o caminho [VG Resource: Breath of Fire 2].

## Fade de brilho

- INIDISP (`$2100`) bits 3-0 são o brilho mestre: com valor N, a imagem sai com intensidade de (N+1)/16 [fullsnes]. O fade padrão é somar ou subtrair 1 no brilho por quadro (ou a cada 2 quadros) na sombra de INIDISP que a NMI escreve [undisbeliever].
- **Brilho 0 não é preto garantido**: termine o fade com force blank (bit 7) antes de mexer em VRAM ou trocar a cena [undisbeliever][fullsnes].
- **Glitch de INIDISP**: o PPU pode reagir a um valor que passa no barramento antes da escrita de verdade. A saída recomendada é escrever por endereço longo cujo banco é o próprio valor: `sta $802100` para ligar o force blank (com A = `$80`) e `sta $0f2100` para desligar (com A = `$0F`) [undisbeliever]. Isso exige que o banco `$80` ou `$0F` espelhe os registradores, o que vale nos bancos `$00-$3F` e `$80-$BF` (snes-hardware/references/mapa-de-memoria.md).
- No console de placa 1-CHIP, ligar o force blank com `$80` e depois sair com `$0F` dá uma faixa de degradê com glitch; mantenha os bits de brilho ligados no valor de force blank (`$8F`) [undisbeliever].
- Fade para branco não sai do brilho mestre. A saída é color math somando a cor fixa a tudo (CGWSEL `$00`, CGADSUB `$3F`) e subindo a intensidade de COLDATA com os três canais ligados até 31, onde cada canal satura [fullsnes]. No exemplo de névoa no horizonte, a wiki nota que trocar a soma pela subtração leva ao preto em vez do branco [SNESdev wiki: Color math]. O exemplo de [exemplos.md](exemplos.md) chegou ao branco puro no Mesen [Teste local]. Sprite com paleta 0-3 fica fora e não clareia [fullsnes].

## Mosaico

- MOSAIC (`$2106`): bits 7-4 são o tamanho do bloco (1 a 16 pixels), bits 3-0 ligam por BG [fullsnes].
- Transição clássica: aumentar o tamanho do mosaico a cada quadro enquanto faz o fade, trocar a cena em force blank e desfazer ao contrário.
- Mudar o mosaico no meio da tela (por IRQ ou HDMA) é possível, mas o PPU termina o bloco atual com o tamanho vertical antigo antes de aplicar o novo [fullsnes].
- Os bits de liga só existem para BG1-BG4; sprites não têm mosaico [fullsnes].

Related: [hdma-efeitos.md](hdma-efeitos.md), [estrutura-do-jogo.md](estrutura-do-jogo.md), [exemplos.md](exemplos.md), [fontes.md](fontes.md)
