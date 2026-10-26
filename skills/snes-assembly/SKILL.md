---
name: snes-assembly
description: Assembly do 65816 (CPU do Super Nintendo / Super Famicom) com sintaxe do asar. Cobre registradores (A/B/C, X, Y, S, D, DB, PB), flags M e X, REP/SEP, XCE e modo emulação, todos os modos de endereçamento, pilha, JSR/JSL/RTS/RTL/RTI, MVN/MVP, tabela dos 256 opcodes com bytes e ciclos, interrupções e vetores, desempenho (FastROM, D alinhado) e armadilhas de ROM hack (tamanho de registrador depois de hook, B escondido, banco de dados errado). Use quando for escrever, ler, revisar ou depurar código 65816, ao montar patch com asar, ao desmontar rotina de jogo de SNES, ou quando alguém perguntar "quantos ciclos tem essa instrução", "por que o hook trava", "REP ou SEP?", "o que é o opcode $A9", "como faço JSL pra freespace", "qual a diferença entre asar, ca65 e WLA-DX", "LDA $12 lê de onde?", "como salvo os registradores no NMI".
---

# Assembly 65816 (SNES)

O 65816 é um 6502 estendido pra 16 bits e 24 bits de endereço. No SNES ele roda em modo nativo quase o tempo todo. A maior parte dos bugs vem de três coisas: tamanho de registrador (M/X), banco (DB/PB) e Direct Page (D). Sintaxe dos exemplos: asar.

## Regras de ouro

1. **Flag em 1 = 8 bits.** `REP #$30` = A, X, Y em 16 bits. `SEP #$30` = tudo em 8. `REP #$20`/`SEP #$20` só A; `#$10` só X/Y.
2. **Sempre saiba o estado de M e X** em cada ponto do código. O montador não sabe; você declara com o sufixo: `LDA.b #$01`, `LDA.w #$0001`, `LDX.w #$0000`.
3. **Hook entra com `PHP` e sai com `PLP`**, e salva A/X/Y em 16 bits (`REP #$30` antes de empilhar). Refaça as instruções originais sobrescritas.
4. **Absoluto usa DB, direct usa banco 0, código usa PB.** Código em outro banco lê tabela com `LDA.l tabela,x` ou faz `PHB : PHK : PLB` ... `PLB`.
5. **`SEP #$20` não zera B.** Ao voltar pra 16 bits, limpe o byte alto (`AND #$00FF`) antes de usar A como índice ou valor.
6. **`SEP #$10` zera XH e YH** e o valor alto não volta.
7. **`JSL` volta com `RTL`, `JSR` volta com `RTS`.** Pulo pra outro banco é `JML`. O PC não atravessa banco.
8. **D alinhado em $xx00**: DL diferente de zero custa 1 ciclo em todo acesso direct. Se mudar D, `PHD`/`PLD`.
9. **No asar, `MVN destino,origem`** (ao contrário do padrão WDC e do ca65). C = bytes - 1, e no fim DB = banco de destino.
10. **Endereço, bit e ciclo vêm das tabelas dos references**, nunca de memória.

## Entrada no modo nativo (boot)

```asm
    SEI
    CLC
    XCE              ; E=0: modo nativo, M e X ainda em 1
    REP #$38         ; A/X/Y 16 bits, D=0 (modo binário)
    LDX.w #$1FFF
    TXS              ; pilha no topo da WRAM baixa
    LDA.w #$0000
    TCD              ; D = $0000
    SEP #$20
    PHA
    PLB              ; DB = $00
```

## Armadilhas mais comuns (detalhe em `references/armadilhas.md`)

- **Tamanho errado depois do hook**: instrução seguinte lida desalinhada, travamento aleatório.
- **B escondido**: A de 16 bits com lixo no byte alto depois de `REP #$20` ou `TAX`.
- **Banco de dados errado**: tabela vira lixo quando o código vai pra freespace em outro banco; NMI/IRQ não mudam DB.
- **D trocado pelo jogo** (ex.: $4300 pra DMA): `LDA $10` lê $4310. Use `.w` ou long quando não souber D.
- **RTS/RTL trocados**: pilha desalinhada, retorno pra endereço errado.
- **Interrupção** que salva registrador em 8 bits e perde o byte alto.
- **Sintaxe de outro montador** colada no asar: MVN invertido, `.a16` inexistente, `z:`/`a:`/`f:` do ca65 viram erro.

## Fatos rápidos

| Item | Valor |
|---|---|
| Bits de P | N $80, V $40, M $20, X $10, D $08, I $04, Z $02, C $01 |
| Vetores nativos (banco 0) | COP $FFE4, BRK $FFE6, ABORT $FFE8, NMI $FFEA, IRQ $FFEE |
| Vetores emulação | COP $FFF4, ABORT $FFF8, NMI $FFFA, RESET $FFFC, IRQ/BRK $FFFE |
| Interrupção nativa | empilha PB, PC, P; I=1, D=0, PB=0; DB não muda |
| Sempre 16 bits | TCS, TSC, TCD, TDC, PHD/PLD, PEA/PEI/PER |
| Sempre 8 bits | PHP/PLP, PHB/PLB, PHK, XBA (N/Z do A novo) |
| Clock de memória | ROM/WRAM 8 clks, I/O $21xx e $42xx 6 clks, joypad $4016/7 12 clks, FastROM 6 clks em $80-$FF com $420D=1 |

## Índice dos references

| Preciso de | Arquivo |
|---|---|
| Registradores, P, tamanho, troca de modo, XCE, reset | `references/registradores-e-flags.md` |
| Modo de endereçamento, banco usado, forçar tamanho no asar/ca65/WLA | `references/modos-de-enderecamento.md` |
| Opcode, bytes, ciclos, flags afetadas (256 linhas) | `references/instrucoes.md` |
| Pilha, JSR/JSL/RTS/RTL/RTI, interrupções, vetores, MVN/MVP | `references/pilha-chamadas-interrupcoes.md` |
| Ciclos no SNES, FastROM, D alinhado, truques de velocidade | `references/desempenho.md` |
| Armadilhas com sintoma e conserto, tabela asar x ca65 x WLA-DX | `references/armadilhas.md` |
| De onde veio cada fato, divergências entre fontes | `references/fontes.md` |

Para desmontar uma rotina: ache o opcode em `instrucoes.md` (busque `$A9`), acompanhe REP/SEP/PLP pra saber o tamanho dos imediatos e anote DB e D antes de interpretar endereços.
