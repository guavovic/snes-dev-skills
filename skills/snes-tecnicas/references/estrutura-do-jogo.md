# Estrutura de um jogo

Como um jogo de SNES se organiza do reset ao quadro rodando. Registradores bit a bit: snes-hardware/references/ppu-registradores.md, dma-hdma.md, interrupcoes-e-timing.md e controles.md. Instruções e ciclos: snes-assembly.

## Init seguro

Ordem recomendada pela wiki da comunidade [SNESdev wiki: Init code]:

1. `sei`, `clc`, `xce` (sai do modo emulação), `rep #$ff` seguido de `sep #$24` (flags conhecidas, I ligado, A de 8 bits), pilha no topo da low RAM, D = `$0000`, banco de dados igual ao do código (`phk` / `plb`).
2. **Antes de tudo no PPU:** `$4200` (NMITIMEN) = 0 e `$420C` (HDMAEN) = 0, para nenhuma interrupção nem HDMA rodar no meio do init. Depois `$2100` (INIDISP) = `$8F` (force blank).
3. Limpar a WRAM por DMA de fonte fixa (DMAP `$08`, destino WMDATA `$2180`), e depois VRAM, CGRAM e OAM, ainda em force blank.
4. Rodar a rotina de **reset de registradores**.
5. Subir gráficos, ligar NMI e auto-joypad em `$4200`, sair do force blank.

**Reset de registradores por cena.** A wiki recomenda uma rotina reutilizável que coloca os registradores do PPU em valores conhecidos, chamada no boot e a cada troca de fase ou cena, para um efeito da cena anterior não vazar para a próxima. Valores que não são zero: VMAIN `$80`, CGWSEL `$30`, COLDATA `$E0`, BGnVOFS `$FF`, M7A e M7D com 1.0 (`$0100` em 8.8, escritos como `$00` e depois `$01`), WRIO `$FF`, MEMSEL 1 se o jogo for FastROM [SNESdev wiki: Init code]. O esqueleto LoROM completo está em snes-hardware/references/exemplos.md.

## Laço principal e NMI

O padrão recomendado é **NMI curta, lógica no laço** [SNESdev wiki: VBlank routine][SNESdev wiki: VBlank interrupts]:

- O laço principal usa o controle já lido pela NMI, roda a lógica, escreve os resultados em **registradores sombra** (cópias na WRAM de scroll, brilho, TM etc.), enche os buffers (OAM, paleta, fila de DMA), **liga a flag de quadro pronto** e espera com `wai`.
- A NMI salva A/X/Y em 16 bits, DB e D, faz `phk`/`plb` e D = 0 [SNESdev wiki: VBlank routine].
- Se a flag estiver ligada: transfere OAM, fila de DMA e paleta, escreve os registradores sombra, liga o HDMA e desliga a flag. Se não estiver: **não transfere nada** e soma 1 no contador de lag.
- O que precisa estar pronto antes da linha 0 (DMA, HDMA, scroll) vem primeiro; controle e contadores por último [SNESdev wiki: VBlank routine].
- O controle não é atualizado num quadro de lag, para a lógica não perder um aperto [SNESdev wiki: VBlank routine].
- A NMI não deve tocar a porta da WRAM (`$2180-$2183`) nem o multiplicador e o divisor, porque o laço pode estar no meio de um uso [SNESdev wiki: VBlank routine].
- A wiki sugere **uma rotina de vblank por estado** do jogo (título, fase, menu), trocada por ponteiro, em vez de uma NMI cheia de condições [SNESdev wiki: VBlank routine].
- Ler `$4210` (RDNMI) reconhece a NMI [fullsnes]. Uma NMI que chega durante um DMA longo só entra quando o DMA termina, e aí pode já estar fora do vblank [fullsnes].
- Se a NMI só desliga a flag no fim, ela inteira precisa caber antes da próxima NMI (cerca de 260 linhas no NTSC), senão o quadro seguinte se perde [SNESdev wiki: VBlank routine].

## Fila de DMA

Em vez de cada parte do jogo mexer na VRAM, ela **pede** uma transferência (origem de 24 bits, destino na VRAM, tamanho, modo) e a NMI esvazia a fila [SNESdev wiki: VBlank routine]:

- A fila tem um teto de bytes por quadro abaixo do que cabe no vblank: 6.123 bytes no NTSC de 224 linhas (191 tiles de 4bpp), 3.641 com 239 linhas, 14.398 no PAL de 224 [SNESdev wiki: Timing]. Cada byte de DMA custa 8 master clocks [fullsnes].
- Pedido que não cabe volta com erro (a wiki usa o carry) e quem pediu tenta no próximo quadro [SNESdev wiki: VBlank routine].
- Paleta e OAM costumam ter buffer próprio e transferência fixa, fora da fila.
- Código em [exemplos.md](exemplos.md).

## Buffer de OAM e tabela alta

- Buffer de 544 bytes na WRAM: 512 da tabela baixa (X, Y, tile e atributo de 128 sprites) e 32 da tabela alta (2 bits por sprite: bit par = bit 8 do X, bit ímpar = tamanho; 4 sprites por byte) [fullsnes]. Formato em snes-graficos/references/tilemap-e-oam.md e snes-hardware/references/ppu-formatos.md.
- Transferência uma vez por quadro: OAMADD = 0 e DMA de 544 bytes para OAMDATA (destino `$04`); o exemplo do [fullsnes] usa DMAP `$02`.
- A cada quadro o jogo **limpa** o buffer (todo sprite em Y=224, que esconde sprites de até 32x32) e os atores escrevem os seus a partir do índice 0 [fullsnes][SNESdev wiki: Sprites].
- Reempacotar os 2 bits da tabela alta todo quadro é caro; a wiki sugere deixar a tabela alta com um padrão fixo e só mexer quando precisa [SNESdev wiki: Sprites].
- X = -256 não esconde de verdade: o sprite ainda conta para o limite de fatias por linha [fullsnes].
- **Limite por linha:** 32 sprites e 34 fatias de 8 pixels; ao passar, STAT77 (`$213E`) liga os bits 6 e 7 e o excedente some [fullsnes][SNESdev wiki: Sprites]. Sprite de índice menor fica por cima. O bit 7 de OAMADDH liga a **rotação de prioridade**, que muda qual sprite é o primeiro; girar isso a cada quadro faz o flicker que espalha o sumiço entre todos [fullsnes].

## Controle

- Liga o auto-joypad com o bit 0 de `$4200`. A leitura automática começa nas primeiras linhas do vblank e dura 4224 master clocks (cerca de 3 linhas); espere `$4212` bit 0 = 0 antes de ler `$4218` [fullsnes][SNESdev wiki: Controller reading].
- Bits de JOY1 (`$4218`/`$4219`, 16 bits): 15 B, 14 Y, 13 Select, 12 Start, 11 cima, 10 baixo, 9 esquerda, 8 direita, 7 A, 6 X, 5 L, 4 R [fullsnes]. Tabela completa em snes-hardware/references/controles.md.
- **Recém-apertado** = (atual XOR anterior) AND atual [SNESdev wiki: Controller reading]. Pelo mesmo raciocínio, recém-solto = (atual XOR anterior) AND anterior.
- O bit 0 de `$4016` precisa ficar em 0 enquanto o auto-joypad roda [fullsnes].

## Atores e máquina de estados

Não foi achado documento primário de um estúdio da época descrevendo o seu sistema de objetos. O que segue é o padrão de arquitetura comum em 65816, **sem afirmar que um jogo específico fazia assim** (não confirmado em fonte de época).

- **Tabela de atores como estrutura de arrays**: cada campo (estado, X, Y, velocidade, timer, quadro de animação) é um array de N entradas, e X é o índice do ator. Assim `lda ator_x,x` acessa o campo de qualquer ator com um só registrador.
- **Estado como índice numa tabela de ponteiros**: com A e X de 16 bits e o índice do ator em Y, `lda estado,y`, `asl`, `tax`, `jsr (tabela,x)`. Com A de 8 bits e X de 16, o `tax` copia também o byte alto escondido de A, então zere esse byte ou use A de 16 [Clark]. O `JSR (abs,X)` lê o ponteiro no banco do programa (PB) [Clark][Mesen2]; a divergência do datasheet está em snes-assembly/references/fontes.md.
- **Estado do jogo** (título, fase, pausa, menu) segue a mesma ideia um nível acima, e cada estado escolhe também a sua rotina de vblank [SNESdev wiki: VBlank routine].
- Cada ator escreve os seus sprites no buffer de OAM e, se precisa de tiles novos (animação por streaming), põe um pedido na fila de DMA.

## Orçamento do quadro, lag e slowdown

- NTSC: 262 linhas, vblank a partir da linha 225 (37 linhas de vblank com 224 visíveis). São 357.368 master clocks por quadro, 346.888 disponíveis para a CPU depois do refresh da DRAM [SNESdev wiki: Timing].
- A CPU acessa memória a 6, 8 ou 12 master clocks (3,58 / 2,68 / 1,79 MHz) conforme a região [SNESdev wiki: Timing][fullsnes]. Ciclos por instrução e otimizações em snes-assembly/references/desempenho.md.
- **Lag** é o quadro em que a lógica não terminou antes da NMI: a NMI não transfere, a tela repete o quadro anterior e o mundo anda mais devagar. É o slowdown visível nos jogos da época. Com a flag de quadro pronto ele aparece no contador de lag [SNESdev wiki: VBlank routine].
- Para ver onde o tempo vai, uma técnica conhecida é mudar o brilho ou a cor de fundo no começo e no fim da lógica e olhar a faixa na tela (**não confirmado** em fonte primária; o profiler de um emulador mostra o mesmo de forma direta).

## Vblank estendido (letterbox)

Para ganhar banda de DMA, dá para esconder linhas no topo e no fim com force blank e tratá-las como vblank extra [undisbeliever]:

- Uma IRQ de V no fim da área visível liga o force blank, e outra no topo desliga; cada linha tirada rende cerca de 165 bytes a mais de DMA [undisbeliever].
- Ligar e desligar no hblank, com o glitch de INIDISP em mente (ver [cor-e-transicoes.md](cor-e-transicoes.md)).
- A primeira linha depois do force blank pode sair sem sprites [undisbeliever].

Related: [hdma-efeitos.md](hdma-efeitos.md), [exemplos.md](exemplos.md), [fontes.md](fontes.md)
