# Registradores e flags do 65816

Fontes: [WDC] seções 2 e 7, [Clark] seções 2 a 4, [fullsnes] "CPU Registers and Flags". Tudo aqui foi conferido em pelo menos duas delas.

## Registradores

| Registrador | Largura | Função |
|---|---|---|
| A / B / C | 8 + 8 = 16 | Acumulador. A = byte baixo, B = byte alto, C = os 16 bits juntos. Com M=1 as operações usam só A, mas B continua lá. |
| X, Y | 8 ou 16 | Índices. Com X=1 (flag) o byte alto é forçado a $00. |
| S | 16 | Ponteiro de pilha, aponta pro primeiro byte livre. No modo emulação SH é forçado a $01. |
| D | 16 | Direct Page: base dos modos "direct" (`$12`, `$12,x` ...), sempre no banco 0. |
| DB (DBR) | 8 | Data Bank: banco usado pelos modos absolutos de dado (`$1234`, `$1234,x`, `($12),y` ...). |
| PB (K) | 8 | Program Bank: banco do código. Só muda com JML, JSL, RTL, RTI e interrupção. |
| PC | 16 | Contador de programa dentro de PB. Não atravessa banco: passa de $FFFF pra $0000 no mesmo banco. |
| P | 8 | Flags. |
| E | 1 | Flag escondida de emulação, só acessível via XCE. |

Apelidos que confundem [fullsnes][Clark]: "K" = PB; "B" em PHB/PLB é o DB; "B" em XBA é o byte alto do acumulador; "C" em TCD/TCS/TDC/TSC é o acumulador de 16 bits inteiro.

## Registrador P

| Bit | Valor | Nativo | Emulação |
|---|---|---|---|
| 7 | $80 | N negativo | N |
| 6 | $40 | V overflow | V |
| 5 | $20 | M: 1 = A de 8 bits, 0 = A de 16 bits | (sempre 1) |
| 4 | $10 | X: 1 = X/Y de 8 bits, 0 = 16 bits | B (BRK), só visível no byte empilhado |
| 3 | $08 | D decimal | D |
| 2 | $04 | I desliga IRQ | I |
| 1 | $02 | Z zero | Z |
| 0 | $01 | C carry | C |

Atenção ao sentido: **flag em 1 = 8 bits**. `REP #$30` deixa A, X e Y em 16 bits; `SEP #$30` deixa tudo em 8 bits. REP zera os bits marcados no operando, SEP liga. Os dois levam 3 ciclos e 2 bytes [Clark][SFC wiki].

## O que acontece ao trocar de tamanho

- **X de 16 pra 8 bits (SEP #$10)**: XH e YH viram $00 na hora. Voltar pra 16 bits (REP #$10) não recupera: X=$1234 vira $0034 [Clark][WDC 7.23].
- **A de 16 pra 8 bits (SEP #$20)**: B **não** é zerado, fica guardado. Exemplo do [WDC 7.23]: com B=$23, `SEP #$20`, `LDA #$01`, `REP #$20` deixa A=$2301. É a armadilha do "B escondido".
- **Transferências**: o tamanho do destino manda. TAX com M=1 e X=0 copia os 16 bits de C (B incluso) pra X. TXA com M=1 copia só o byte baixo [WDC 7.20][Clark].
- **Exceções que são sempre 16 bits**, independente de M: TCS, TSC, TCD, TDC [WDC 7.20]. TXS/TSX/TXY/TYX seguem X. XBA troca A e B sempre, e N/Z vêm do novo A (8 bits) [Clark 6.10.3].
- **PHP/PLP** são sempre 8 bits. PHA/PLA seguem M; PHX/PLX/PHY/PLY seguem X; PHD/PLD são sempre 16 bits; PHB/PLB/PHK sempre 8 bits [Clark][WDC].

## Modo emulação e XCE

- O RESET deixa o 65816 em modo emulação com E=1, M=X=1, I=1, flag D=0, D=$0000, DB=$00, PB=$00, SH=$01 e XH=YH=$00. A, SL, XL e YL ficam sem valor definido: inicialize S e o resto no código [WDC 2.25].
- `XCE` troca C com E. É a única instrução que mexe em E [Clark 6.10.4].
- Entrar no modo nativo: `CLC` + `XCE`. Depois disso M e X continuam 1 até um REP.
- Voltar pra emulação: `SEC` + `XCE`. Força M=X=1, XH=YH=$00 e SH=$01. Os bytes baixos e B não mudam [WDC 7.10].
- No modo emulação REP/SEP não conseguem zerar M nem X [WDC 7.8.3.1].
- Diferenças que pegam quem porta código 6502 [Clark, apêndice]:
  - Direct page com DL=$00 dá a volta na página ("page wrap") só no modo emulação e só nas instruções "antigas". `[d]`, `[d],y` e `PEI` não dão a volta [WDC 7.2][Clark 5.7].
  - Desvio tomado que cruza página custa +1 ciclo só no modo emulação.
  - RTI puxa 3 bytes na emulação e 4 no nativo.
  - Na emulação, JSL, JSR (a,x), PEA, PEI, PER, PHD, PLD e RTL podem sair da página 1 da pilha [WDC 7.1].

No SNES todo jogo roda em modo nativo depois do boot; o modo emulação só importa no vetor de RESET e se alguma rotina voltar pra ele.

## Modo decimal

D=1 faz ADC/SBC em BCD. Não custa ciclo extra no 65816. N, Z e C saem válidos, V não tem significado útil [Clark]. Interrupções zeram D ao entrar [WDC].
