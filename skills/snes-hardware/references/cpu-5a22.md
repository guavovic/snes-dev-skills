# CPU 5A22 (65C816) e registradores $42xx

O 5A22 da Ricoh é um núcleo 65C816 com DMA, multiplicador, divisor, timer de H/V e leitura automática de controle embutidos [fullsnes] [SNESdev wiki: MMIO registers].

## Núcleo 65C816 (resumo)

Fontes: [WDC datasheet] [fullsnes: CPU 65XX].

- Registradores: A (acumulador, 8 ou 16 bits; a metade alta se chama B), X e Y (8 ou 16 bits), S (stack, 16 bits), D (direct page, 16 bits), DBR (banco de dados), PBR (banco de programa), P (flags).
- Flags de P, do bit 0 ao 7: C, Z, I, D, X (B em emulação), M (sem uso em emulação), V, N.
- `M = 1`: A em 8 bits; a parte B é preservada e trocável com `XBA`. `X = 1`: X e Y em 8 bits, e a parte alta deles é zerada na hora.
- Direct page e stack ficam sempre no banco 00. Em modo emulação o byte alto do stack fica em $01.
- Só `JML`, `JSL`, `RTL`, `RTI` e `JMP` longo trocam o PBR. O contador de programa não atravessa a fronteira de banco sozinho: código que passa de $FFFF volta a $0000 do mesmo banco.
- Estado no reset [WDC datasheet]: E = 1 (emulação), M = X = 1, I = 1, D (decimal) = 0, D (direct page) = $0000, DBR = PBR = $00, byte alto de S = $01, parte alta de X e Y = $00. A, a parte baixa de X/Y e a de S **não** são inicializadas.
- Entrar no modo nativo: `clc` seguido de `xce`. Depois disso `rep`/`sep` controlam M e X.

## Tabela dos registradores $4016-$421F

"Quando escrever" diz se há restrição de momento. W = escrita, R = leitura.

| Reg. | Nome | Acesso | Bits | Quando escrever / observações |
|---|---|---|---|---|
| $4016 | JOYWR | W | bit0: strobe (latch) dos controles | Qualquer hora; deixar em 0 com auto-joypad ligado. Acesso de 12 clocks |
| $4016 | JOYA | R | bit0: dado serial do controle 1; bit1: do controle 3 (multitap) | Leitura manual, um bit por leitura |
| $4017 | JOYB | R | bit0: controle 2; bit1: controle 4; bits 2-4 sempre 1 | Idem |
| $4200 | NMITIMEN | W | bit7: NMI no vblank; bits 5-4: IRQ (0 off, 1 H, 2 V, 3 H e V); bit0: auto-joypad | Qualquer hora. Reset = $00. Desligar a IRQ aqui também reconhece a IRQ pendente |
| $4201 | WRIO | W | bit7: pino 6 do controle 2 e latch de H/V da light gun; demais: porta de I/O | Power-on $FF. O latch por $2137 só funciona com bit7 = 1 |
| $4202 | WRMPYA | W | Multiplicando, 8 bits sem sinal | Fica guardado entre multiplicações |
| $4203 | WRMPYB | W | Multiplicador; escrever aqui dispara a conta | Resultado em $4216/7 depois de ~8 ciclos de CPU |
| $4204/5 | WRDIVL/H | W | Dividendo, 16 bits sem sinal | |
| $4206 | WRDIVB | W | Divisor 8 bits; escrever dispara a conta | Quociente em $4214/5 e resto em $4216/7 depois de ~16 ciclos. Divisor 0 dá quociente $FFFF e resto = dividendo |
| $4207/8 | HTIMEL/H | W | 9 bits: ponto H da IRQ | Power-on $1FF. Valor maior que 339 nunca dispara |
| $4209/A | VTIMEL/H | W | 9 bits: linha V da IRQ | Power-on $1FF. Maior que 261 (NTSC) ou 311 (PAL) nunca dispara |
| $420B | MDMAEN | W | bit n: inicia o DMA do canal n | A CPU para até o fim; ver [dma-hdma.md](dma-hdma.md) |
| $420C | HDMAEN | W | bit n: liga o HDMA do canal n | Escrever no vblank; ligar no meio do quadro tem comportamento não totalmente conhecido |
| $420D | MEMSEL | W | bit0: 1 = FastROM (WS2 a 6 clocks) | Reset 0. Só ajuda com cartucho FastROM e código rodando em 80-FF |
| $4210 | RDNMI | R | bit7: flag de vblank/NMI, zera na leitura; bits 3-0: versão da CPU | Ler no handler de NMI para reconhecer |
| $4211 | TIMEUP | R | bit7: flag de IRQ do timer, zera na leitura | Ler no handler de IRQ, senão a IRQ dispara de novo |
| $4212 | HVBJOY | R | bit7: dentro do vblank; bit6: dentro do hblank; bit0: auto-joypad em andamento | Polling seguro a qualquer hora |
| $4213 | RDIO | R | Leitura da porta de I/O (bit7 = pino 6 do controle 2) | |
| $4214/5 | RDDIVL/H | R | Quociente da divisão | |
| $4216/7 | RDMPYL/H | R | Produto da multiplicação ou resto da divisão | |
| $4218-$421F | JOY1L-JOY4H | R | Resultado do auto-joypad, 16 bits por controle | Ver [controles.md](controles.md) |

Fontes: [fullsnes] [SNESdev wiki: MMIO registers]. Os tempos de 8 e 16 ciclos da matemática vêm dos dois; ler antes disso devolve valor intermediário [fullsnes].

## Porta da WRAM no B-bus

| Reg. | Nome | Acesso | Função |
|---|---|---|---|
| $2180 | WMDATA | R/W | Lê ou escreve a WRAM no endereço atual e incrementa |
| $2181-$2183 | WMADDL/M/H | W | Endereço de 17 bits dentro da WRAM (só o bit0 de $2183 conta) |

Serve para encher a WRAM por DMA (B-bus $80) a partir da ROM [fullsnes] [SNESdev wiki].

## Multiplicador com sinal do PPU

O PPU tem um multiplicador instantâneo: 16 bits com sinal escritos em $211B (duas escritas) vezes 8 bits com sinal escritos em $211C, resultado de 24 bits em $2134-$2136. Esses registradores são os mesmos da matriz do Mode 7, então só use o multiplicador fora do Mode 7 ou em vblank/force blank [fullsnes] [SNESdev wiki: PPU registers].

## Armadilhas

- Esquecer de ler $4211 no handler de IRQ deixa a CPU presa em IRQ.
- Ler $4216/7 cedo demais devolve resultado parcial. Gaste ao menos 8 (multiplicação) ou 16 (divisão) ciclos antes, por exemplo com `nop` ou com instruções úteis.
- O multiplicador do 5A22 é sem sinal; para conta com sinal use o do PPU ($211B/$211C) ou trate o sinal à mão.
- O banco de direct page é sempre 00: apontar D para a WRAM alta ($7E:2000+) não funciona, só para 0000-1FFF (que espelha a WRAM baixa) ou registradores.
