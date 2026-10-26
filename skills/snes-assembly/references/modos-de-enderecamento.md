# Modos de endereçamento

Fontes: [WDC] seção 3 e tabela 6-2, [Clark] seção 5, [fullsnes]. Sintaxe do asar conferida na lista de opcodes do manual e no `arch-65816.cpp` [asar].

O 65816 gera endereço de 24 bits (banco:endereço). O que muda de um modo pro outro é **de onde vem o banco**: DB, PB, banco 0 fixo ou o próprio operando.

## Tabela

| Modo | asar | Bytes | Endereço efetivo | Banco |
|---|---|---|---|---|
| Imediato | `LDA #$12` / `LDA #$1234` | 2 ou 3 | o próprio operando | - |
| Implícito / acumulador | `INX`, `ASL A` | 1 | - | - |
| Absoluto | `LDA $1234` | 3 | DB:$1234 | DB |
| Absoluto,X / ,Y | `LDA $1234,x` | 3 | DB:$1234 + X | DB, e o carry passa pro banco seguinte |
| Absoluto long | `LDA $7E1234` | 4 | $7E1234 | operando |
| Absoluto long,X | `LDA $7E1234,x` | 4 | $7E1234 + X | operando |
| Direct | `LDA $12` | 2 | D + $12 | 0 |
| Direct,X / ,Y | `LDA $12,x` | 2 | D + $12 + X | 0 |
| (Direct) | `LDA ($12)` | 2 | ponteiro de 16 bits em 0:D+$12 | dado em DB |
| (Direct),Y | `LDA ($12),y` | 2 | ponteiro + Y | dado em DB, pode cruzar banco |
| (Direct,X) | `LDA ($12,x)` | 2 | ponteiro em 0:D+$12+X | dado em DB |
| [Direct] | `LDA [$12]` | 2 | ponteiro de 24 bits em 0:D+$12 | do ponteiro |
| [Direct],Y | `LDA [$12],y` | 2 | ponteiro de 24 bits + Y | do ponteiro |
| Stack relative | `LDA $03,s` | 2 | S + $03 | 0 |
| (Stack relative),Y | `LDA ($03,s),y` | 2 | ponteiro de 16 bits em 0:S+$03, + Y | dado em DB |
| Relativo 8 | `BNE label` | 2 | PC + 2 + offset (-128..127) | PB |
| Relativo 16 | `BRL label` | 3 | PC + 3 + offset (±32 KB), dá a volta no banco | PB |
| Bloco | `MVN $dst,$src` (ver armadilha) | 3 | X origem, Y destino | operandos |
| JMP absoluto | `JMP $8000` | 3 | PB:$8000 | PB |
| JMP (a) | `JMP ($1234)` | 3 | ponteiro lido em 0:$1234 | PB |
| JMP (a,x) / JSR (a,x) | `JMP ($1234,x)` | 3 | ponteiro lido em **PB**:$1234+X | PB |
| JML [a] | `JML [$1234]` | 3 | ponteiro de 24 bits lido em 0:$1234 | do ponteiro |
| JML / JSL long | `JML $C08000` | 4 | $C08000 | operando |

## Regras que valem pra todos

- **Direct e stack relative são sempre banco 0.** D + offset dá a volta em $FFFF dentro do banco 0 [WDC 3.3][Clark].
- **Absoluto usa DB, não PB.** Um `LDA tabela,x` num banco de código diferente de DB lê lixo. É o erro de banco mais comum.
- **Indexação de dado atravessa banco**: DB=$12, `LDA $FFFE,x` com X=$0A lê $130008 [WDC 3.5.3][Clark]. Já o ponteiro de `(d)`/`[d]` é lido em banco 0 e dá a volta lá.
- **JMP (a,x) lê o ponteiro em PB.** O [WDC 3.5.2] diz banco 0, mas o próprio [WDC 7.9], o [Clark 5.5] e o código do [Mesen2] (`JMP_AbsIdxXInd` usa `GetProgramAddress`) dizem PB. Vale PB. Isso é útil: a tabela de saltos fica no mesmo banco da rotina.
- **JMP (a) e JML [a] leem o ponteiro em banco 0** [WDC 7.9][Clark].
- **Três endereços diferentes** [Clark 5.23]: `LDA $56` é direct (0:D+$56), `LDA $0056` é absoluto (DB:$0056), `LDA $000056` é long. No asar o tamanho vem do número de dígitos ou do sufixo `.b/.w/.l`.
- **DL diferente de $00 custa +1 ciclo** em todo modo direct [WDC 3.5.17][Clark]. Deixe D alinhado em $xx00.
- **Page wrap da emulação**: com E=1 e DL=$00, `LDA ($FF)` lê o byte alto do ponteiro em $0000. `PEI ($FF)`, `[d]` e `[d],y` não dão a volta e leem $0100 [Clark, apêndice][WDC 7.2]. No modo nativo não há wrap de página.

## Forçar o tamanho no asar

| Quero | asar | ca65 | WLA-DX |
|---|---|---|---|
| direct (8 bits) | `LDA.b label` | `LDA z:label` | `LDA label.b` |
| absoluto (16 bits) | `LDA.w label` | `LDA a:label` | `LDA label.w` |
| long (24 bits) | `LDA.l label` | `LDA f:label` | `LDA label.l` |
| imediato de 8 / 16 | `LDA.b #0` / `LDA.w #0` | `.a8` / `.a16` antes | `LDA #0.b` / `LDA #0.w` |

Fontes: [asar] "Opcode Length Specification", [ca65] seções de prefixo de endereço e `.A8/.A16`, [WLA-DX] "Mnemonics". O sinal `<`, `!`/`|`, `>` do padrão WDC (tabela 6-2) não é usado pelo asar pra isso [asar].

Sem sufixo, o asar escolhe pelo valor: `$12` direct, `$1234` absoluto, `$123456` long. Pra **label**, ele usa absoluto se o label estiver no banco atual (comando `bank`) e long se não; direct só com `.b` ou `optimize dp` [asar "bank", "optimize"].
