# Efeitos de HDMA

HDMA escreve de 1 a 4 bytes num registrador do PPU em cada linha, no hblank, sem a CPU participar durante a tela. Formato da tabela, padrões de transferência, modo indireto e bugs do chip: snes-hardware/references/dma-hdma.md. Aqui fica o **uso**.

Lembrete rápido do formato [SNESdev wiki: HDMA examples][fullsnes]:

- Cada entrada começa com um byte de contagem: `$00` encerra o canal no quadro; `$01-$80` escreve uma vez e espera N linhas; `$81-$FF` escreve em toda linha por N-$80 linhas (um bloco de dados por linha).
- Padrão (DMAP bits 2-0): 0 = 1 byte; 1 = dois registradores (xx, xx+1); 2 = mesmo registrador duas vezes (escrita dupla, como scroll); 3 = xx, xx, xx+1, xx+1; 4 = quatro registradores seguidos.
- Modo indireto (DMAP bit 6): a tabela guarda ponteiros de 16 bits e o banco vem de DASB (`$43n7`). Serve para repetir o mesmo bloco de dados em várias faixas sem copiar.
- Liga em HDMAEN (`$420C`) **no vblank** [SNESdev wiki: HDMA examples]. Tabela que muda de quadro para quadro precisa de **buffer duplo**: a CPU escreve numa cópia enquanto o HDMA lê a outra, e a NMI troca o ponteiro [SNESdev wiki: HDMA examples].

## Degradê de céu

Dois caminhos:

- **Cor fixa (COLDATA `$2132`) com color math somando no fundo.** Barato, um canal com padrão 0 e um byte por linha. Cada escrita de COLDATA muda um ou mais canais de cor (bits 7-5 escolhem R, G, B), então um degradê de uma cor só é uma escrita por faixa; mexer em dois canais diferentes pede dois bytes na linha [fullsnes]. Bits e fórmula do color math: snes-hardware/references/ppu-registradores.md. É também como se faz névoa no horizonte [SNESdev wiki: Color math].
- **Trocar uma cor da paleta (CGRAM) por linha.** Dois canais: um escreve CGADD (`$2121`, padrão 0) e outro CGDATA (`$2122`, padrão 2), ligados juntos em HDMAEN `$C0`; ou um canal só com padrão 3 começando em CGADD (CGADD, CGADD, CGDATA, CGDATA) [SNESdev wiki: HDMA examples]. Dá cor real na cor 0 (fundo) sem depender de color math.

Exemplo em [exemplos.md](exemplos.md) e o gradiente de referência em snes-hardware/references/exemplos.md.

## Ondulação de água e calor

- HDMA no scroll horizontal de um BG (BGnHOFS, padrão 2, escrita dupla) com um valor diferente por linha, tirado de uma tabela de seno. Deslocando o começo da tabela a cada quadro, a onda anda [SNESdev wiki: HDMA examples].
- A wiki usa **modo indireto** com ponteiros para uma tabela de seno de 48 linhas de período, para não gerar a tabela inteira de novo a cada quadro [SNESdev wiki: HDMA examples].
- Só na faixa da água: as entradas acima da água escrevem o scroll normal e ficam paradas; a onda começa na linha da superfície.
- Calor (miragem) é a mesma coisa com amplitude pequena. No scroll vertical (BGnVOFS) a onda estica e encolhe a imagem na vertical.
- Variante da wiki: **shear** (inclinar a imagem) com um deslocamento que cresce linha a linha, com buffer duplo [SNESdev wiki: HDMA examples].

## Paralaxe por faixa

Um BG só pode ter várias "camadas" se cada faixa de linhas tiver o seu scroll horizontal. Exemplo da wiki: BG1HOFS com padrão 2 e quatro entradas de 45, 22, 128 e 128 linhas, com valores `cameraX >> 3`, `cameraX >> 2`, `cameraX` e `cameraX << 1`: o céu anda devagar, o chão anda mais rápido que a câmera [SNESdev wiki: HDMA examples]. A CPU só recalcula 4 valores por quadro. Paralaxe com vários BGs fica em [streaming-e-scroll.md](streaming-e-scroll.md).

## Ligar e desligar camadas por faixa

HDMA em TM (`$212C`, padrão 0) liga um BG só em parte da tela, por exemplo a barra de status num BG que some na área do jogo [SNESdev wiki: HDMA examples].

## Perspectiva de Mode 7 (pseudo 3D)

- Mode 7 é um BG com matriz 2x2 (A, B, C, D em 8.8) e centro; a matriz vale para a linha inteira, e trocá-la **linha a linha** por HDMA faz cada linha ter uma escala diferente, o que dá o chão em perspectiva [SNESdev wiki: Mode 7 transform][Dizworld]. Fórmula e registradores em snes-hardware/references/ppu-registradores.md.
- A escala de cada linha cai com a distância até o horizonte; acima do horizonte a tela costuma mostrar outra coisa (céu por HDMA em BGMODE ou TM, ou IRQ trocando o modo) [Dizworld].
- A CPU gera a tabela de HDMA quando o ângulo ou a altura da câmera mudam. O exemplo Dizworld de Brad Smith gera tudo a 60 quadros por segundo; com ângulo fixo dá para gerar uma vez só [Dizworld].
- Quantos canais: com padrão 2, um canal por registrador (M7A, M7B, M7C, M7D). Como M7A/M7B e M7C/M7D são vizinhos (`$211B/$211C` e `$211D/$211E`), o padrão 3 cobre dois registradores por canal; isso é dedução da tabela de padrões, **não confirmado** num exemplo publicado.
- Cuidado: o latch de escrita dupla de M7A é o mesmo de BGnHOFS; um HDMA em BG1HOFS no meio de uma escrita da CPU em M7A estraga as duas [SNESdev wiki: HDMA examples].
- Super Mario Kart usava a pista em Mode 7 e personagens em sprites desenhados em vários ângulos (billboard), por causa da memória [Iwata Asks: Mario Kart Wii]. Ver [desenvolvedores.md](desenvolvedores.md).

## Janela em forma de círculo (foco de luz, lanterna, transição em íris)

- As janelas do PPU têm borda esquerda e direita (WH0/WH1 em `$2126/$2127` para a janela 1). Por HDMA, cada linha recebe o seu par esquerda/direita: um canal com padrão 1 em `$2126` escreve WH0 e WH1 juntos [SNESdev wiki: Drawing window shapes].
- Para um círculo, guarde a meia largura por linha numa tabela pré-calculada e faça esquerda = centro - meia e direita = centro + meia, cortando em 0-255. Linhas fora do círculo usam esquerda = 255 e direita = 0, que fecham a janela [SNESdev wiki: Drawing window shapes].
- O que a janela faz depende de quem ela recorta (W12SEL, WOBJSEL, TMW/TSW) e do color math. Para **escurecer fora da luz**: CGWSEL bits 5-4 = 2 (color math só fora da janela de cor) com subtração da cor fixa, ou CGWSEL bits 7-6 = 1 (tela principal preta fora da janela) [SNESdev wiki: Windows][fullsnes][bsnes]. Ver [cor-e-transicoes.md](cor-e-transicoes.md).
- Encoding do campo de área das janelas: bit 1 liga, bit 0 inverte (2 = dentro, 3 = fora) [SNESdev wiki: Windows][bsnes]. O texto do [fullsnes] para esse campo diverge; ver [fontes.md](fontes.md).
- Transição em íris: o raio diminui a cada quadro até a tela fechar. Lanterna que segue o personagem: o centro acompanha o X/Y dele e a tabela começa na linha do topo do círculo.

## Cortina de caixa de texto

A wiki mostra uma caixa de texto que abre de cima para baixo mudando, no vblank, só os bytes de contagem da tabela de HDMA (a faixa da caixa cresce uma linha por quadro), sem reescrever os dados [SNESdev wiki: HDMA examples].

Related: [cor-e-transicoes.md](cor-e-transicoes.md), [streaming-e-scroll.md](streaming-e-scroll.md), [exemplos.md](exemplos.md), [fontes.md](fontes.md)
