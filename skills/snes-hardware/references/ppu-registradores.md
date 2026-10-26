# Registradores do PPU ($2100-$213F)

Fontes: [fullsnes: PPU] e [SNESdev wiki: PPU registers], conferidos registrador a registrador. Valores de VRAM são em **words** (16 bits), não em bytes.

Legenda de "Quando":
- **VB/FB**: só tem efeito garantido em vblank ou force blank.
- **Livre**: pode ser escrito a qualquer hora, inclusive por HDMA no meio da tela, e vale a partir da linha seguinte (ou do ponto seguinte, no caso de scroll e cor).
- **x2**: escrita dupla (byte baixo, depois alto) no mesmo endereço.

## Controle de tela, OAM e modo

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2100 | INIDISP | bit7: force blank (1 = tela preta, VRAM liberada); bits 3-0: brilho (0-15) | Livre. Ver armadilhas abaixo |
| $2101 | OBSEL | bits 7-5: par de tamanhos dos OBJs; bits 4-3: intervalo extra entre os tiles $0FF e $100 de OBJ (0 = nenhum, passos de 4K words); bits 2-0: base dos tiles de OBJ em passos de 8K words | Entre quadros |
| $2102/3 | OAMADDL/H | bits 8-0: endereço em words na OAM; bit15 ($2103 bit7): rotação de prioridade | VB/FB. Recarregado sozinho no início do vblank com o último valor escrito |
| $2104 | OAMDATA | Escreve um byte na OAM e avança | VB/FB. Abaixo de $200 a escrita é em pares: o 1º byte fica num latch e os dois vão juntos no 2º |
| $2105 | BGMODE | bits 7-4: tamanho de tile de BG4-BG1 (0 = 8x8, 1 = 16x16); bit3: BG3 em prioridade máxima (só Mode 1); bits 2-0: modo 0-7 | Livre |
| $2106 | MOSAIC | bits 7-4: tamanho do bloco (0 = 1x1 a 15 = 16x16); bits 3-0: liga mosaico em BG4-BG1 | Livre |

Pares de tamanho de OBJ ($2101 bits 7-5) [fullsnes] [SNESdev wiki]:

| Valor | Pequeno | Grande |
|---|---|---|
| 0 | 8x8 | 16x16 |
| 1 | 8x8 | 32x32 |
| 2 | 8x8 | 64x64 (OBJ de 64 de altura pode dar a volta da borda de baixo para a de cima) |
| 3 | 16x16 | 32x32 |
| 4 | 16x16 | 64x64 |
| 5 | 32x32 | 64x64 |
| 6 | 16x32 | 32x64 (não documentado oficialmente) |
| 7 | 16x32 | 32x32 (não documentado oficialmente) |

## Backgrounds

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2107-$210A | BG1SC-BG4SC | bits 7-2: base do tilemap em passos de 1K words; bits 1-0: tamanho (0 = 32x32, 1 = 64x32, 2 = 32x64, 3 = 64x64 tiles) | Livre |
| $210B | BG12NBA | bits 7-4: base dos tiles do BG2; bits 3-0: do BG1; passos de 4K words | Livre |
| $210C | BG34NBA | bits 7-4: BG4; bits 3-0: BG3 | Livre |
| $210D | BG1HOFS / M7HOFS | x2. 10 bits de scroll horizontal do BG1; o mesmo endereço guarda 13 bits com sinal do Mode 7 | Livre |
| $210E | BG1VOFS / M7VOFS | x2. Scroll vertical do BG1 / Mode 7 | Livre |
| $210F-$2114 | BG2HOFS ... BG4VOFS | x2. Scroll dos outros BGs, 10 bits | Livre |

Detalhe do scroll [fullsnes] [SNESdev wiki]: os registradores de scroll compartilham um latch ("Prev"). O horizontal é montado como `(byte << 8) | (Prev & ~7) | ((HOFS_atual >> 8) & 7)`; o vertical como `(byte << 8) | Prev`. Na prática: escreva sempre o byte baixo e depois o alto, e não intercale escrita de outro scroll no meio. O latch é dividido com o dos registradores do Mode 7 ($211B-$2120).

## VRAM

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2115 | VMAIN | bit7: incrementa depois de $2118/$2139 (0) ou depois de $2119/$213A (1); bits 3-2: remapeamento de endereço (para gráfico em formato de bitmap); bits 1-0: passo (0 = 1, 1 = 32, 2 e 3 = 128 words) | Livre |
| $2116/7 | VMADDL/H | Endereço em words (15 bits; o bit15 não tem efeito) | Livre. Escrever aqui faz o prefetch da leitura |
| $2118/9 | VMDATAL/H | Escreve byte baixo / alto da word | VB/FB. Fora disso a escrita é ignorada, mas o endereço incrementa mesmo assim |
| $2139/A | RDVRAML/H | Lê byte baixo / alto | VB/FB. A leitura usa um buffer de prefetch: a primeira leitura depois de escrever VMADD devolve o dado certo, mas leituras feitas sem reescrever o endereço vêm deslocadas; reescreva VMADD antes de ler |

## Mode 7

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $211A | M7SEL | bits 7-6: fora do mapa (0 e 1 = repete, 2 = transparente, 3 = preenche com o tile 0); bit1: espelha vertical; bit0: espelha horizontal | Livre |
| $211B | M7A | x2. 16 bits com sinal, ponto fixo 1.7.8. Também operando de 16 bits do multiplicador | Livre (HDMA por linha é o uso comum) |
| $211C | M7B | x2. Idem. Também operando de 8 bits do multiplicador (só o último byte escrito) | Livre |
| $211D | M7C | x2. 1.7.8 com sinal | Livre |
| $211E | M7D | x2. 1.7.8 com sinal | Livre |
| $211F | M7X | x2. Centro X, 13 bits com sinal | Livre |
| $2120 | M7Y | x2. Centro Y, 13 bits com sinal | Livre |

Fórmula [fullsnes] [SNESdev wiki]:

```
( VX )   ( A  B )   ( SX + HOFS - X0 )   ( X0 )
( VY ) = ( C  D ) * ( SY + VOFS - Y0 ) + ( Y0 )
```

`SX`, `SY` = ponto da tela; `VX`, `VY` = ponto no mapa de 1024x1024; `X0`, `Y0` = M7X/M7Y. Para girar por um ângulo com escala: A = cos·escalaX, B = sen·escalaX, C = -sen·escalaY, D = cos·escalaY. O hardware arredonda produtos intermediários (zera os 6 bits baixos), então o resultado exato tem pequenas diferenças de uma conta em ponto flutuante [fullsnes].

## CGRAM

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2121 | CGADD | Índice da cor (0-255); também zera o flip-flop de escrita | Livre |
| $2122 | CGDATA | x2. Cor de 15 bits: `0BBBBBGG GGGRRRRR`, byte baixo primeiro | VB/FB (ver divergência) |
| $213B | RDCGRAM | x2. Leitura da cor (bit7 do byte alto é open bus) | VB/FB |

Divergência: o [SNESdev wiki] diz que a CGRAM pode ser escrita em vblank, hblank ou force blank. O [fullsnes] diz que no hblank só funciona numa janela curta de poucos ciclos. **Recomendação desta skill:** trocar cor por HDMA no hblank é técnica conhecida, mas trate como avançada e teste em hardware ou em emulador de precisão; para escrita feita pela CPU, use vblank ou force blank.

## Janelas

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2123 | W12SEL | Para BG1 (bits 3-0) e BG2 (bits 7-4): por camada, bit0 inverte W1, bit1 liga W1, bit2 inverte W2, bit3 liga W2 (ligada sem inverter = dentro da janela, ligada e invertida = fora) | Livre |
| $2124 | W34SEL | Idem para BG3 e BG4 | Livre |
| $2125 | WOBJSEL | Idem para OBJ (bits 3-0) e para a janela de cor/color math (bits 7-4) | Livre |
| $2126/7 | WH0/WH1 | Janela 1: X esquerdo e X direito, inclusivos. Esquerdo maior que direito = janela vazia | Livre |
| $2128/9 | WH2/WH3 | Janela 2: idem | Livre |
| $212A | WBGLOG | 2 bits por BG (BG1 nos bits 1-0 ... BG4 nos 7-6): como juntar W1 e W2 (0 OR, 1 AND, 2 XOR, 3 XNOR) | Livre |
| $212B | WOBJLOG | bits 1-0: OBJ; bits 3-2: janela de cor | Livre |
| $212C | TM | Camadas na tela principal: bit4 OBJ, bits 3-0 BG4-BG1 | Livre |
| $212D | TS | Camadas na sub-tela (mesma ordem) | Livre |
| $212E | TMW | Aplica a janela na tela principal, por camada | Livre |
| $212F | TSW | Aplica a janela na sub-tela, por camada | Livre |

Janela com borda curva ou formato livre = mudar WH0-WH3 linha a linha por HDMA.

## Color math

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2130 | CGWSEL | bits 7-6: força preto na tela principal (0 nunca, 1 fora da janela de cor, 2 dentro, 3 sempre); bits 5-4: onde o color math vale (0 sempre, 1 dentro da janela de cor, 2 fora, 3 nunca); bit1: usar a sub-tela (1) ou a cor fixa (0) como 2º operando; bit0: direct color nos modos 3, 4 e 7 | Livre |
| $2131 | CGADSUB | bit7: 0 soma, 1 subtrai; bit6: divide o resultado por 2; bits 5-0: camadas afetadas (bit5 backdrop, bit4 OBJ, bits 3-0 BG4-BG1) | Livre |
| $2132 | COLDATA | bits 7-5: quais canais recebem o valor (B, G, R); bits 4-0: intensidade | Livre (escrever um canal por vez, ou mais de um com o mesmo valor) |

Só OBJs com paleta 4-7 entram no color math; paletas 0-3 ficam imunes [fullsnes] [SNESdev wiki]. Mode 5 e 6 não fazem soma nem subtração [fullsnes].

## Resolução e varredura

| Reg. | Nome | Bits | Quando |
|---|---|---|---|
| $2133 | SETINI | bit7: ext sync (sempre 0 no console normal); bit6: EXTBG (BG2 do Mode 7 com prioridade por pixel); bit3: pseudo-hires (512 pixels misturando tela principal e sub-tela); bit2: overscan (239 linhas em vez de 224); bit1: OBJ interlace; bit0: interlace | Entre quadros |

## Leituras de status e latch

| Reg. | Nome | Bits |
|---|---|---|
| $2134-$2136 | MPYL/M/H | Produto de 24 bits com sinal de M7A × M7B (8 bits) |
| $2137 | SLHV | Ler aqui trava os contadores H e V (precisa de $4201 bit7 = 1) |
| $2138 | RDOAM | Lê a OAM e avança |
| $213C | OPHCT | x2 (leitura). Contador H travado, 9 bits (0-339) |
| $213D | OPVCT | x2 (leitura). Contador V travado, 9 bits |
| $213E | STAT77 | bit7: excesso de tempo de OBJ (mais de 34 tiles na linha); bit6: excesso de OBJs (mais de 32 na linha); bits 3-0: versão do PPU1 |
| $213F | STAT78 | bit7: campo do interlace; bit6: houve latch de H/V (zera na leitura); bit4: 0 NTSC, 1 PAL; bits 3-0: versão do PPU2. Ler aqui reinicia o flip-flop de $213C/$213D |

## Armadilhas

- **Force blank:** escreva `$8F` (force blank + brilho máximo guardado) e não `$80`. Ao sair, `$0F`. Desligar o force blank no meio da tela, fora do vblank, pode corromper a avaliação de sprites daquela linha e da seguinte [fullsnes].
- **Bug do INIDISP:** em alguns modelos, uma escrita em $2100 pode ter efeito antecipado e gerar glitch. Contorno citado pelo [fullsnes]: escrever com endereço longo (`sta.l $002100` ou espelho em banco alto, como `$8F2100`). O momento exato em que o force blank passa a valer dentro da linha **não foi confirmado** nas fontes consultadas.
- **OAMADD é recarregado** no início de todo vblank. Se o código escreve a OAM aos poucos, regrave o endereço antes de cada lote.
- **Escrita na VRAM fora de VB/FB some** sem erro, mas o endereço avança: o resto do upload sai deslocado.
- **Leitura de VRAM com prefetch:** sempre regrave VMADD antes de ler.
- **Mode 7 e multiplicador** usam os mesmos registradores. No Mode 7 ativo, o multiplicador só dá resultado confiável em vblank ou force blank [fullsnes] [SNESdev wiki].
- **Offset-per-tile** (modos 2, 4 e 6): o [fullsnes] marca a seção como incompleta. O formato básico é: o BG3 vira tabela de deslocamento por coluna para BG1/BG2. Os detalhes finos **ficam de fora** desta skill.
