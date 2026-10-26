# Tabela de instruções (256 opcodes)

Gerada a partir da tabela do [Clark] e conferida opcode por opcode contra o [SFC wiki] (ciclos base + notas de rodapé) com um script que testou todas as combinações de m, x, e, w, p e t. As 256 linhas batem, com três exceções resolvidas abaixo. Sintaxe convertida pro [asar] conforme a lista de opcodes do manual e o `arch-65816.cpp`.

## Como ler

- **Bytes**: `3-m` = 3 bytes com M=0 (16 bits) e 2 com M=1. `3-x` idem com X.
- **Ciclos (fórmula)**, notação do [Clark]: `m`, `x`, `e` = valor da flag (0 ou 1); `w` = 1 se DL (byte baixo de D) for diferente de $00; `p` = 1 se a indexação ou o desvio cruzar página; `t` = 1 se o desvio for tomado.
- **8 bits / 16 bits**: a fórmula já calculada no modo nativo com M=X=1 e com M=X=0, D alinhado, sem cruzar página e desvio não tomado. Some à mão o que a fórmula disser pro seu caso.
- **nvmxdizc**: `.` não muda, `*` muda, `0`/`1` forçado, `m` = muda conforme o resultado na largura de M, `x` = na largura de X. ` e` no fim = mexe na flag E (só XCE).
- Ciclo aqui é ciclo de CPU. No SNES cada ciclo dura 6, 8 ou 12 ciclos de clock mestre conforme a região de memória acessada (ver [desempenho](desempenho.md)).

Regras resumidas, válidas pra tabela toda [WDC notas da tabela 5-5][Clark][SFC wiki]:

- +1 ciclo se M=0 (operando de 16 bits) em leitura/escrita; +2 em read-modify-write (ASL, ROL, INC, TSB ...).
- +1 se DL diferente de $00 nos modos direct.
- +1 em `abs,x`, `abs,y`, `(d),y` se cruzar página **ou** se X=0 (índices de 16 bits). Escrita indexada sempre paga esse ciclo.
- Desvio: +1 se tomado; +1 a mais se tomado e cruzar página, **só no modo emulação**.
- BRK, COP e RTI: +1 no modo nativo (empilham/puxam PB).
- Modo decimal não custa ciclo extra.

## Divergências na tabela

| Opcode | [SFC wiki] | [Clark] / outros | Vale |
|---|---|---|---|
| WDM ($42) | 0 ciclos, "sujeito a mudança" | 2 ciclos, 2 bytes | [Clark]: é um NOP de 2 bytes. O [WDC 7.16] diz que é reservado pra CPUs futuras; não use. |
| MVN/MVP | célula quebrada ("1[3]") | 7 ciclos por byte movido | [Clark] + [fullsnes] + [Mesen2] |
| BRK ($00) | 2 bytes | 1 byte + assinatura | Mesma coisa: a CPU pula a assinatura e empilha opcode+2. No asar `BRK` sozinho já gera `00 00` [asar `arch-65816.cpp`]; no ca65 `brk` gera 1 byte e `brk #$34` gera 2 [ca65]. |

O [fullsnes] traz uma lista de ciclos simplificada com contagens herdadas do 6502 em alguns modos; pra ciclo vale [WDC] + [Clark].

## Tabela

Ordenada por mnemônico. Pra desmontar, procure pelo opcode (`$A9`). A coluna Mnem. mostra o nome WDC; quando o asar usa outro nome (JML pro JMP long), ele aparece na coluna de sintaxe.

| Mnem. | Op | Modo | Sintaxe asar | Bytes | Ciclos (fórmula) | 8 bits | 16 bits | nvmxdizc |
|---|---|---|---|---|---|---|---|---|
| ADC | $61 | (dir,X) | `ADC ($10,x)` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| ADC | $63 | stk,S | `ADC $32,s` | 2 | 5-m | 4 | 5 | `mm....mm` |
| ADC | $65 | dir | `ADC $10` | 2 | 4-m+w | 3 | 4 | `mm....mm` |
| ADC | $67 | [dir] | `ADC [$10]` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| ADC | $69 | imm | `ADC #$54` | 3-m | 3-m | 2 | 3 | `mm....mm` |
| ADC | $6D | abs | `ADC $9876` | 3 | 5-m | 4 | 5 | `mm....mm` |
| ADC | $6F | long | `ADC $FEDBCA` | 4 | 6-m | 5 | 6 | `mm....mm` |
| ADC | $71 | (dir),Y | `ADC ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `mm....mm` |
| ADC | $72 | (dir) | `ADC ($10)` | 2 | 6-m+w | 5 | 6 | `mm....mm` |
| ADC | $73 | (stk,S),Y | `ADC ($32,s),y` | 2 | 8-m | 7 | 8 | `mm....mm` |
| ADC | $75 | dir,X | `ADC $10,x` | 2 | 5-m+w | 4 | 5 | `mm....mm` |
| ADC | $77 | [dir],Y | `ADC [$10],y` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| ADC | $79 | abs,Y | `ADC $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `mm....mm` |
| ADC | $7D | abs,X | `ADC $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `mm....mm` |
| ADC | $7F | long,X | `ADC $FEDCBA,x` | 4 | 6-m | 5 | 6 | `mm....mm` |
| AND | $21 | (dir,X) | `AND ($10,x)` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| AND | $23 | stk,S | `AND $32,s` | 2 | 5-m | 4 | 5 | `m.....m.` |
| AND | $25 | dir | `AND $10` | 2 | 4-m+w | 3 | 4 | `m.....m.` |
| AND | $27 | [dir] | `AND [$10]` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| AND | $29 | imm | `AND #$54` | 3-m | 3-m | 2 | 3 | `m.....m.` |
| AND | $2D | abs | `AND $9876` | 3 | 5-m | 4 | 5 | `m.....m.` |
| AND | $2F | long | `AND $FEDBCA` | 4 | 6-m | 5 | 6 | `m.....m.` |
| AND | $31 | (dir),Y | `AND ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `m.....m.` |
| AND | $32 | (dir) | `AND ($10)` | 2 | 6-m+w | 5 | 6 | `m.....m.` |
| AND | $33 | (stk,S),Y | `AND ($32,s),y` | 2 | 8-m | 7 | 8 | `m.....m.` |
| AND | $35 | dir,X | `AND $10,x` | 2 | 5-m+w | 4 | 5 | `m.....m.` |
| AND | $37 | [dir],Y | `AND [$10],y` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| AND | $39 | abs,Y | `AND $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| AND | $3D | abs,X | `AND $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| AND | $3F | long,X | `AND $FEDCBA,x` | 4 | 6-m | 5 | 6 | `m.....m.` |
| ASL | $06 | dir | `ASL $10` | 2 | 7-2*m+w | 5 | 7 | `m.....mm` |
| ASL | $0A | acc | `ASL A` | 1 | 2 | 2 | 2 | `m.....mm` |
| ASL | $0E | abs | `ASL $9876` | 3 | 8-2*m | 6 | 8 | `m.....mm` |
| ASL | $16 | dir,X | `ASL $10,x` | 2 | 8-2*m+w | 6 | 8 | `m.....mm` |
| ASL | $1E | abs,X | `ASL $9876,x` | 3 | 9-2*m | 7 | 9 | `m.....mm` |
| BCC | $90 | rel8 | `BCC LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BCS | $B0 | rel8 | `BCS LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BEQ | $F0 | rel8 | `BEQ LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BIT | $24 | dir | `BIT $10` | 2 | 4-m+w | 3 | 4 | `mm....m.` |
| BIT | $2C | abs | `BIT $9876` | 3 | 5-m | 4 | 5 | `mm....m.` |
| BIT | $34 | dir,X | `BIT $10,x` | 2 | 5-m+w | 4 | 5 | `mm....m.` |
| BIT | $3C | abs,X | `BIT $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `mm....m.` |
| BIT | $89 | imm | `BIT #$54` | 3-m | 3-m | 2 | 3 | `......m.` |
| BMI | $30 | rel8 | `BMI LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BNE | $D0 | rel8 | `BNE LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BPL | $10 | rel8 | `BPL LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BRA | $80 | rel8 | `BRA LABEL` | 2 | 3+e*p | 3 | 3 | `........` |
| BRK | $00 | imp | `BRK #$00` | 2 (1 + assinatura) | 8-e | 8 | 8 | `....01..` |
| BRL | $82 | rel16 | `BRL LABEL` | 3 | 4 | 4 | 4 | `........` |
| BVC | $50 | rel8 | `BVC LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| BVS | $70 | rel8 | `BVS LABEL` | 2 | 2+t+t*e*p | 2 | 2 | `........` |
| CLC | $18 | imp | `CLC` | 1 | 2 | 2 | 2 | `.......0` |
| CLD | $D8 | imp | `CLD` | 1 | 2 | 2 | 2 | `....0...` |
| CLI | $58 | imp | `CLI` | 1 | 2 | 2 | 2 | `.....0..` |
| CLV | $B8 | imp | `CLV` | 1 | 2 | 2 | 2 | `.0......` |
| CMP | $C1 | (dir,X) | `CMP ($10,x)` | 2 | 7-m+w | 6 | 7 | `m.....mm` |
| CMP | $C3 | stk,S | `CMP $32,s` | 2 | 5-m | 4 | 5 | `m.....mm` |
| CMP | $C5 | dir | `CMP $10` | 2 | 4-m+w | 3 | 4 | `m.....mm` |
| CMP | $C7 | [dir] | `CMP [$10]` | 2 | 7-m+w | 6 | 7 | `m.....mm` |
| CMP | $C9 | imm | `CMP #$54` | 3-m | 3-m | 2 | 3 | `m.....mm` |
| CMP | $CD | abs | `CMP $9876` | 3 | 5-m | 4 | 5 | `m.....mm` |
| CMP | $CF | long | `CMP $FEDBCA` | 4 | 6-m | 5 | 6 | `m.....mm` |
| CMP | $D1 | (dir),Y | `CMP ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `m.....mm` |
| CMP | $D2 | (dir) | `CMP ($10)` | 2 | 6-m+w | 5 | 6 | `m.....mm` |
| CMP | $D3 | (stk,S),Y | `CMP ($32,s),y` | 2 | 8-m | 7 | 8 | `m.....mm` |
| CMP | $D5 | dir,X | `CMP $10,x` | 2 | 5-m+w | 4 | 5 | `m.....mm` |
| CMP | $D7 | [dir],Y | `CMP [$10],y` | 2 | 7-m+w | 6 | 7 | `m.....mm` |
| CMP | $D9 | abs,Y | `CMP $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `m.....mm` |
| CMP | $DD | abs,X | `CMP $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `m.....mm` |
| CMP | $DF | long,X | `CMP $FEDCBA,x` | 4 | 6-m | 5 | 6 | `m.....mm` |
| COP | $02 | imm | `COP #$12` | 2 (1 + assinatura) | 8-e | 8 | 8 | `....01..` |
| CPX | $E0 | imm | `CPX #$54` | 3-x | 3-x | 2 | 3 | `x.....xx` |
| CPX | $E4 | dir | `CPX $10` | 2 | 4-x+w | 3 | 4 | `x.....xx` |
| CPX | $EC | abs | `CPX $9876` | 3 | 5-x | 4 | 5 | `x.....xx` |
| CPY | $C0 | imm | `CPY #$54` | 3-x | 3-x | 2 | 3 | `x.....xx` |
| CPY | $C4 | dir | `CPY $10` | 2 | 4-x+w | 3 | 4 | `x.....xx` |
| CPY | $CC | abs | `CPY $9876` | 3 | 5-x | 4 | 5 | `x.....xx` |
| DEC | $3A | acc | `DEC A` | 1 | 2 | 2 | 2 | `m.....m.` |
| DEC | $C6 | dir | `DEC $10` | 2 | 7-2*m+w | 5 | 7 | `m.....m.` |
| DEC | $CE | abs | `DEC $9876` | 3 | 8-2*m | 6 | 8 | `m.....m.` |
| DEC | $D6 | dir,X | `DEC $10,x` | 2 | 8-2*m+w | 6 | 8 | `m.....m.` |
| DEC | $DE | abs,X | `DEC $9876,x` | 3 | 9-2*m | 7 | 9 | `m.....m.` |
| DEX | $CA | imp | `DEX` | 1 | 2 | 2 | 2 | `x.....x.` |
| DEY | $88 | imp | `DEY` | 1 | 2 | 2 | 2 | `x.....x.` |
| EOR | $41 | (dir,X) | `EOR ($10,x)` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| EOR | $43 | stk,S | `EOR $32,s` | 2 | 5-m | 4 | 5 | `m.....m.` |
| EOR | $45 | dir | `EOR $10` | 2 | 4-m+w | 3 | 4 | `m.....m.` |
| EOR | $47 | [dir] | `EOR [$10]` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| EOR | $49 | imm | `EOR #$54` | 3-m | 3-m | 2 | 3 | `m.....m.` |
| EOR | $4D | abs | `EOR $9876` | 3 | 5-m | 4 | 5 | `m.....m.` |
| EOR | $4F | long | `EOR $FEDBCA` | 4 | 6-m | 5 | 6 | `m.....m.` |
| EOR | $51 | (dir),Y | `EOR ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `m.....m.` |
| EOR | $52 | (dir) | `EOR ($10)` | 2 | 6-m+w | 5 | 6 | `m.....m.` |
| EOR | $53 | (stk,S),Y | `EOR ($32,s),y` | 2 | 8-m | 7 | 8 | `m.....m.` |
| EOR | $55 | dir,X | `EOR $10,x` | 2 | 5-m+w | 4 | 5 | `m.....m.` |
| EOR | $57 | [dir],Y | `EOR [$10],y` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| EOR | $59 | abs,Y | `EOR $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| EOR | $5D | abs,X | `EOR $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| EOR | $5F | long,X | `EOR $FEDCBA,x` | 4 | 6-m | 5 | 6 | `m.....m.` |
| INC | $1A | acc | `INC A` | 1 | 2 | 2 | 2 | `m.....m.` |
| INC | $E6 | dir | `INC $10` | 2 | 7-2*m+w | 5 | 7 | `m.....m.` |
| INC | $EE | abs | `INC $9876` | 3 | 8-2*m | 6 | 8 | `m.....m.` |
| INC | $F6 | dir,X | `INC $10,x` | 2 | 8-2*m+w | 6 | 8 | `m.....m.` |
| INC | $FE | abs,X | `INC $9876,x` | 3 | 9-2*m | 7 | 9 | `m.....m.` |
| INX | $E8 | imp | `INX` | 1 | 2 | 2 | 2 | `x.....x.` |
| INY | $C8 | imp | `INY` | 1 | 2 | 2 | 2 | `x.....x.` |
| JMP | $4C | abs | `JMP $1234` | 3 | 3 | 3 | 3 | `........` |
| JMP | $5C | long | `JML $FEDCBA` | 4 | 4 | 4 | 4 | `........` |
| JMP | $6C | (abs) | `JMP ($1234)` | 3 | 5 | 5 | 5 | `........` |
| JMP | $7C | (abs,X) | `JMP ($1234,x)` | 3 | 6 | 6 | 6 | `........` |
| JMP | $DC | [abs] | `JML [$1234]` | 3 | 6 | 6 | 6 | `........` |
| JSL | $22 | long | `JSL $123456` | 4 | 8 | 8 | 8 | `........` |
| JSR | $20 | abs | `JSR $1234` | 3 | 6 | 6 | 6 | `........` |
| JSR | $FC | (abs,X) | `JSR ($1234,x)` | 3 | 8 | 8 | 8 | `........` |
| LDA | $A1 | (dir,X) | `LDA ($10,x)` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| LDA | $A3 | stk,S | `LDA $32,s` | 2 | 5-m | 4 | 5 | `m.....m.` |
| LDA | $A5 | dir | `LDA $10` | 2 | 4-m+w | 3 | 4 | `m.....m.` |
| LDA | $A7 | [dir] | `LDA [$10]` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| LDA | $A9 | imm | `LDA #$54` | 3-m | 3-m | 2 | 3 | `m.....m.` |
| LDA | $AD | abs | `LDA $9876` | 3 | 5-m | 4 | 5 | `m.....m.` |
| LDA | $AF | long | `LDA $FEDBCA` | 4 | 6-m | 5 | 6 | `m.....m.` |
| LDA | $B1 | (dir),Y | `LDA ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `m.....m.` |
| LDA | $B2 | (dir) | `LDA ($10)` | 2 | 6-m+w | 5 | 6 | `m.....m.` |
| LDA | $B3 | (stk,S),Y | `LDA ($32,s),y` | 2 | 8-m | 7 | 8 | `m.....m.` |
| LDA | $B5 | dir,X | `LDA $10,x` | 2 | 5-m+w | 4 | 5 | `m.....m.` |
| LDA | $B7 | [dir],Y | `LDA [$10],y` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| LDA | $B9 | abs,Y | `LDA $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| LDA | $BD | abs,X | `LDA $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| LDA | $BF | long,X | `LDA $FEDCBA,x` | 4 | 6-m | 5 | 6 | `m.....m.` |
| LDX | $A2 | imm | `LDX #$54` | 3-x | 3-x | 2 | 3 | `x.....x.` |
| LDX | $A6 | dir | `LDX $10` | 2 | 4-x+w | 3 | 4 | `x.....x.` |
| LDX | $AE | abs | `LDX $9876` | 3 | 5-x | 4 | 5 | `x.....x.` |
| LDX | $B6 | dir,Y | `LDX $10,y` | 2 | 5-x+w | 4 | 5 | `x.....x.` |
| LDX | $BE | abs,Y | `LDX $9876,y` | 3 | 6-2*x+x*p | 4 | 6 | `x.....x.` |
| LDY | $A0 | imm | `LDY #$54` | 3-x | 3-x | 2 | 3 | `x.....x.` |
| LDY | $A4 | dir | `LDY $10` | 2 | 4-x+w | 3 | 4 | `x.....x.` |
| LDY | $AC | abs | `LDY $9876` | 3 | 5-x | 4 | 5 | `x.....x.` |
| LDY | $B4 | dir,X | `LDY $10,x` | 2 | 5-x+w | 4 | 5 | `x.....x.` |
| LDY | $BC | abs,X | `LDY $9876,x` | 3 | 6-2*x+x*p | 4 | 6 | `x.....x.` |
| LSR | $46 | dir | `LSR $10` | 2 | 7-2*m+w | 5 | 7 | `0.....m*` |
| LSR | $4A | acc | `LSR A` | 1 | 2 | 2 | 2 | `0.....m*` |
| LSR | $4E | abs | `LSR $9876` | 3 | 8-2*m | 6 | 8 | `0.....m*` |
| LSR | $56 | dir,X | `LSR $10,x` | 2 | 8-2*m+w | 6 | 8 | `0.....m*` |
| LSR | $5E | abs,X | `LSR $9876,x` | 3 | 9-2*m | 7 | 9 | `0.....m*` |
| MVN | $54 | src,dest | `MVN $34,$12` | 3 | 7 por byte | 7 | 7 | `........` |
| MVP | $44 | src,dest | `MVP $34,$12` | 3 | 7 por byte | 7 | 7 | `........` |
| NOP | $EA | imp | `NOP` | 1 | 2 | 2 | 2 | `........` |
| ORA | $01 | (dir,X) | `ORA ($10,x)` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| ORA | $03 | stk,S | `ORA $32,s` | 2 | 5-m | 4 | 5 | `m.....m.` |
| ORA | $05 | dir | `ORA $10` | 2 | 4-m+w | 3 | 4 | `m.....m.` |
| ORA | $07 | [dir] | `ORA [$10]` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| ORA | $09 | imm | `ORA #$54` | 3-m | 3-m | 2 | 3 | `m.....m.` |
| ORA | $0D | abs | `ORA $9876` | 3 | 5-m | 4 | 5 | `m.....m.` |
| ORA | $0F | long | `ORA $FEDBCA` | 4 | 6-m | 5 | 6 | `m.....m.` |
| ORA | $11 | (dir),Y | `ORA ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `m.....m.` |
| ORA | $12 | (dir) | `ORA ($10)` | 2 | 6-m+w | 5 | 6 | `m.....m.` |
| ORA | $13 | (stk,S),Y | `ORA ($32,s),y` | 2 | 8-m | 7 | 8 | `m.....m.` |
| ORA | $15 | dir,X | `ORA $10,x` | 2 | 5-m+w | 4 | 5 | `m.....m.` |
| ORA | $17 | [dir],Y | `ORA [$10],y` | 2 | 7-m+w | 6 | 7 | `m.....m.` |
| ORA | $19 | abs,Y | `ORA $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| ORA | $1D | abs,X | `ORA $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `m.....m.` |
| ORA | $1F | long,X | `ORA $FEDCBA,x` | 4 | 6-m | 5 | 6 | `m.....m.` |
| PEA | $F4 | imm | `PEA $1234` | 3 | 5 | 5 | 5 | `........` |
| PEI | $D4 | dir | `PEI ($12)` | 2 | 6+w | 6 | 6 | `........` |
| PER | $62 | imm | `PER LABEL` | 3 | 6 | 6 | 6 | `........` |
| PHA | $48 | imp | `PHA` | 1 | 4-m | 3 | 4 | `........` |
| PHB | $8B | imp | `PHB` | 1 | 3 | 3 | 3 | `........` |
| PHD | $0B | imp | `PHD` | 1 | 4 | 4 | 4 | `........` |
| PHK | $4B | imp | `PHK` | 1 | 3 | 3 | 3 | `........` |
| PHP | $08 | imp | `PHP` | 1 | 3 | 3 | 3 | `........` |
| PHX | $DA | imp | `PHX` | 1 | 4-x | 3 | 4 | `........` |
| PHY | $5A | imp | `PHY` | 1 | 4-x | 3 | 4 | `........` |
| PLA | $68 | imp | `PLA` | 1 | 5-m | 4 | 5 | `m.....m.` |
| PLB | $AB | imp | `PLB` | 1 | 4 | 4 | 4 | `*.....*.` |
| PLD | $2B | imp | `PLD` | 1 | 5 | 5 | 5 | `*.....*.` |
| PLP | $28 | imp | `PLP` | 1 | 4 | 4 | 4 | `********` |
| PLX | $FA | imp | `PLX` | 1 | 5-x | 4 | 5 | `x.....x.` |
| PLY | $7A | imp | `PLY` | 1 | 5-x | 4 | 5 | `x.....x.` |
| REP | $C2 | imm | `REP #$12` | 2 | 3 | 3 | 3 | `********` |
| ROL | $26 | dir | `ROL $10` | 2 | 7-2*m+w | 5 | 7 | `m.....mm` |
| ROL | $2A | acc | `ROL A` | 1 | 2 | 2 | 2 | `m.....mm` |
| ROL | $2E | abs | `ROL $9876` | 3 | 8-2*m | 6 | 8 | `m.....mm` |
| ROL | $36 | dir,X | `ROL $10,x` | 2 | 8-2*m+w | 6 | 8 | `m.....mm` |
| ROL | $3E | abs,X | `ROL $9876,x` | 3 | 9-2*m | 7 | 9 | `m.....mm` |
| ROR | $66 | dir | `ROR $10` | 2 | 7-2*m+w | 5 | 7 | `m.....m*` |
| ROR | $6A | acc | `ROR A` | 1 | 2 | 2 | 2 | `m.....m*` |
| ROR | $6E | abs | `ROR $9876` | 3 | 8-2*m | 6 | 8 | `m.....m*` |
| ROR | $76 | dir,X | `ROR $10,x` | 2 | 8-2*m+w | 6 | 8 | `m.....m*` |
| ROR | $7E | abs,X | `ROR $9876,x` | 3 | 9-2*m | 7 | 9 | `m.....m*` |
| RTI | $40 | imp | `RTI` | 1 | 7-e | 7 | 7 | `********` |
| RTL | $6B | imp | `RTL` | 1 | 6 | 6 | 6 | `........` |
| RTS | $60 | imp | `RTS` | 1 | 6 | 6 | 6 | `........` |
| SBC | $E1 | (dir,X) | `SBC ($10,x)` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| SBC | $E3 | stk,S | `SBC $32,s` | 2 | 5-m | 4 | 5 | `mm....mm` |
| SBC | $E5 | dir | `SBC $10` | 2 | 4-m+w | 3 | 4 | `mm....mm` |
| SBC | $E7 | [dir] | `SBC [$10]` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| SBC | $E9 | imm | `SBC #$54` | 3-m | 3-m | 2 | 3 | `mm....mm` |
| SBC | $ED | abs | `SBC $9876` | 3 | 5-m | 4 | 5 | `mm....mm` |
| SBC | $EF | long | `SBC $FEDBCA` | 4 | 6-m | 5 | 6 | `mm....mm` |
| SBC | $F1 | (dir),Y | `SBC ($10),y` | 2 | 7-m+w-x+x*p | 5 | 7 | `mm....mm` |
| SBC | $F2 | (dir) | `SBC ($10)` | 2 | 6-m+w | 5 | 6 | `mm....mm` |
| SBC | $F3 | (stk,S),Y | `SBC ($32,s),y` | 2 | 8-m | 7 | 8 | `mm....mm` |
| SBC | $F5 | dir,X | `SBC $10,x` | 2 | 5-m+w | 4 | 5 | `mm....mm` |
| SBC | $F7 | [dir],Y | `SBC [$10],y` | 2 | 7-m+w | 6 | 7 | `mm....mm` |
| SBC | $F9 | abs,Y | `SBC $9876,y` | 3 | 6-m-x+x*p | 4 | 6 | `mm....mm` |
| SBC | $FD | abs,X | `SBC $9876,x` | 3 | 6-m-x+x*p | 4 | 6 | `mm....mm` |
| SBC | $FF | long,X | `SBC $FEDCBA,x` | 4 | 6-m | 5 | 6 | `mm....mm` |
| SEC | $38 | imp | `SEC` | 1 | 2 | 2 | 2 | `.......1` |
| SED | $F8 | imp | `SED` | 1 | 2 | 2 | 2 | `....1...` |
| SEI | $78 | imp | `SEI` | 1 | 2 | 2 | 2 | `.....1..` |
| SEP | $E2 | imm | `SEP #$12` | 2 | 3 | 3 | 3 | `********` |
| STA | $81 | (dir,X) | `STA ($10,x)` | 2 | 7-m+w | 6 | 7 | `........` |
| STA | $83 | stk,S | `STA $32,s` | 2 | 5-m | 4 | 5 | `........` |
| STA | $85 | dir | `STA $10` | 2 | 4-m+w | 3 | 4 | `........` |
| STA | $87 | [dir] | `STA [$10]` | 2 | 7-m+w | 6 | 7 | `........` |
| STA | $8D | abs | `STA $9876` | 3 | 5-m | 4 | 5 | `........` |
| STA | $8F | long | `STA $FEDBCA` | 4 | 6-m | 5 | 6 | `........` |
| STA | $91 | (dir),Y | `STA ($10),y` | 2 | 7-m+w | 6 | 7 | `........` |
| STA | $92 | (dir) | `STA ($10)` | 2 | 6-m+w | 5 | 6 | `........` |
| STA | $93 | (stk,S),Y | `STA ($32,s),y` | 2 | 8-m | 7 | 8 | `........` |
| STA | $95 | dir,X | `STA $10,x` | 2 | 5-m+w | 4 | 5 | `........` |
| STA | $97 | [dir],Y | `STA [$10],y` | 2 | 7-m+w | 6 | 7 | `........` |
| STA | $99 | abs,Y | `STA $9876,y` | 3 | 6-m | 5 | 6 | `........` |
| STA | $9D | abs,X | `STA $9876,x` | 3 | 6-m | 5 | 6 | `........` |
| STA | $9F | long,X | `STA $FEDCBA,x` | 4 | 6-m | 5 | 6 | `........` |
| STP | $DB | imp | `STP` | 1 | 3 | 3 | 3 | `........` |
| STX | $86 | dir | `STX $10` | 2 | 4-x+w | 3 | 4 | `........` |
| STX | $8E | abs | `STX $9876` | 3 | 5-x | 4 | 5 | `........` |
| STX | $96 | dir,Y | `STX $10,y` | 2 | 5-x+w | 4 | 5 | `........` |
| STY | $84 | dir | `STY $10` | 2 | 4-x+w | 3 | 4 | `........` |
| STY | $8C | abs | `STY $9876` | 3 | 5-x | 4 | 5 | `........` |
| STY | $94 | dir,X | `STY $10,x` | 2 | 5-x+w | 4 | 5 | `........` |
| STZ | $64 | dir | `STZ $10` | 2 | 4-m+w | 3 | 4 | `........` |
| STZ | $74 | dir,X | `STZ $10,x` | 2 | 5-m+w | 4 | 5 | `........` |
| STZ | $9C | abs | `STZ $9876` | 3 | 5-m | 4 | 5 | `........` |
| STZ | $9E | abs,X | `STZ $9876,x` | 3 | 6-m | 5 | 6 | `........` |
| TAX | $AA | imp | `TAX` | 1 | 2 | 2 | 2 | `x.....x.` |
| TAY | $A8 | imp | `TAY` | 1 | 2 | 2 | 2 | `x.....x.` |
| TCD | $5B | imp | `TCD` | 1 | 2 | 2 | 2 | `*.....*.` |
| TCS | $1B | imp | `TCS` | 1 | 2 | 2 | 2 | `........` |
| TDC | $7B | imp | `TDC` | 1 | 2 | 2 | 2 | `*.....*.` |
| TRB | $14 | dir | `TRB $10` | 2 | 7-2*m+w | 5 | 7 | `......m.` |
| TRB | $1C | abs | `TRB $9876` | 3 | 8-2*m | 6 | 8 | `......m.` |
| TSB | $04 | dir | `TSB $10` | 2 | 7-2*m+w | 5 | 7 | `......m.` |
| TSB | $0C | abs | `TSB $9876` | 3 | 8-2*m | 6 | 8 | `......m.` |
| TSC | $3B | imp | `TSC` | 1 | 2 | 2 | 2 | `*.....*.` |
| TSX | $BA | imp | `TSX` | 1 | 2 | 2 | 2 | `x.....x.` |
| TXA | $8A | imp | `TXA` | 1 | 2 | 2 | 2 | `m.....m.` |
| TXS | $9A | imp | `TXS` | 1 | 2 | 2 | 2 | `........` |
| TXY | $9B | imp | `TXY` | 1 | 2 | 2 | 2 | `x.....x.` |
| TYA | $98 | imp | `TYA` | 1 | 2 | 2 | 2 | `m.....m.` |
| TYX | $BB | imp | `TYX` | 1 | 2 | 2 | 2 | `x.....x.` |
| WAI | $CB | imp | `WAI` | 1 | 3 | 3 | 3 | `........` |
| WDM | $42 | imm | `WDM #$00` | 2 | 2 | 2 | 2 | `........` |
| XBA | $EB | imp | `XBA` | 1 | 3 | 3 | 3 | `*.....*.` |
| XCE | $FB | imp | `XCE` | 1 | 2 | 2 | 2 | `.......* e` |
