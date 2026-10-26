# Pilha, chamadas, interrupções e MVN/MVP

Fontes: [WDC] seções 3, 5, 7, [Clark] seções 6.2, 6.3, 6.6, [fullsnes], desempate com [Mesen2].

## Pilha

- S aponta pro **primeiro byte livre**. Push grava em S e depois decrementa; pull incrementa e depois lê [WDC 3.2][Clark].
- Fica sempre no banco 0. No modo emulação SH=$01 (página 1).
- Valores de 16 bits ficam na ordem little-endian na memória (byte alto empilhado primeiro).
- Stack relative (`LDA $01,s`) lê o último byte empilhado em S+1. Útil pra parâmetros e variáveis locais sem gastar D.

| Instrução | Empilha | Tamanho |
|---|---|---|
| PHA / PLA | A ou C | segue M |
| PHX, PHY / PLX, PLY | X, Y | segue X |
| PHP / PLP | P | sempre 1 byte |
| PHB / PLB | DB | 1 byte |
| PHK | PB | 1 byte (não existe PLK) |
| PHD / PLD | D | 2 bytes |
| PEA $1234 | valor de 16 bits | 2 bytes |
| PEI ($12) | 16 bits lidos em 0:D+$12 | 2 bytes |
| PER label | PC + 3 + offset (endereço relativo) | 2 bytes |

`PLP` restaura M e X junto: depois dele o tamanho dos registradores é o que estava empilhado.

## Chamadas e retornos

| Instrução | Faz | Bytes na pilha |
|---|---|---|
| `JSR $1234` | empilha PC+2 (endereço do último byte da instrução), pula dentro de PB | 2 |
| `JSR ($1234,x)` | igual, com o ponteiro lido em PB | 2 |
| `JSL $C08000` | empilha PB e depois PC+3, pula pra qualquer banco | 3 |
| `RTS` | puxa 2 bytes, soma 1, fica em PB | 2 |
| `RTL` | puxa 2 bytes e depois PB, soma 1 ao PC (o +1 **não** passa pro banco) | 3 |
| `RTI` | puxa P, PC e, no modo nativo, PB. Não soma 1 | 3 (emul.) / 4 (nativo) |
| `JML $C08000` / `JMP $8000` | pula, não empilha nada | 0 |

[Clark 6.2.2][WDC][Mesen2]. Consequência prática: rotina chamada com JSL tem que voltar com RTL, e rotina chamada com JSR volta com RTS. Misturar destrói a pilha.

Truque comum pra chamar uma rotina que termina em RTS (de outro banco, com JSL): fazer a rotina terminar em RTL, ou montar um trampolim no banco dela (`JSL` pra um stub que faz `JSR rotina` e `RTL`). Endereço de retorno empilhado é **endereço - 1**, então tabela de saltos via `PEA`/`RTS` empilha o alvo menos 1.

## Interrupções

Sequência [WDC 7.11, 7.12][Clark 6.3.1.1][Mesen2 `ProcessInterrupt`]:

1. Termina a instrução atual (MVN/MVP pode ser interrompida entre bytes e retoma depois).
2. Empilha PB, PC e P (4 bytes). No modo emulação empilha só PC e P (3 bytes).
3. Liga I, zera D, faz PB=$00. DB **não muda** (nenhuma das fontes altera DB; o [Mesen2] confirma).
4. Lê o vetor de 16 bits no banco 0 e pula pra 00:vetor.

Como o vetor tem 16 bits, o tratador começa no banco 0 (no SNES, num espelho de ROM em $00:8000-FFFF). Se o código estiver em outro banco, o tratador faz `JML` pra lá.

M e X **não** são alterados pela interrupção, mas P é empilhado e o RTI restaura tudo. Por isso o tratador precisa salvar os registradores no tamanho certo: o padrão é `REP #$30` e depois empilhar A, X e Y em 16 bits, DB e D, e desfazer na ordem inversa antes do RTI.

`RTI` tem que rodar no mesmo modo (nativo ou emulação) em que a interrupção aconteceu, senão puxa o número errado de bytes [Clark 6.3.2].

BRK e COP são instruções de 1 byte seguidas de um byte de assinatura; o endereço empilhado é o do opcode + 2 [WDC 7.15][Clark 6.3.1]. Prioridade de entrada: RESET > ABORT > NMI > IRQ [WDC 7.19].

### Vetores (banco 0)

| Evento | Nativo | Emulação |
|---|---|---|
| COP | $FFE4 | $FFF4 |
| BRK | $FFE6 | $FFFE (mesmo do IRQ) |
| ABORT | $FFE8 | $FFF8 |
| NMI | $FFEA | $FFFA |
| IRQ | $FFEE | $FFFE |
| RESET | (não tem) | $FFFC |

Reservados: $FFE0-FFE3 e $FFEC (nativo), $FFF0-FFF3 e $FFF6 (emulação) [WDC tabelas 5-2 e 5-3][Clark][fullsnes]. No SNES o NMI é o V-Blank e o ABORT não é usado [fullsnes "CPU Exception Vectors"]. Divergência: o [SFC wiki] lista o BRK de emulação em $FFF6; o datasheet diz $FFFE e $FFF6 reservado, e o [Mesen2] usa o vetor do IRQ legado pro BRK de emulação. Vale o [WDC].

No modo emulação BRK e IRQ dividem o vetor: o tratador diferencia pelo bit 4 (B) do P empilhado.

## MVN e MVP

| | MVN ($54) | MVP ($44) |
|---|---|---|
| X / Y | endereço inicial de origem / destino | endereço **final** de origem / destino |
| Movimento | incrementa X e Y | decrementa X e Y |
| Use quando | destino abaixo da origem (ou bancos diferentes) | destino acima da origem com sobreposição |

- C (16 bits, independente de M) = quantidade de bytes **menos 1**. Repete até C virar $FFFF, 7 ciclos por byte [Clark 6.6][fullsnes][Mesen2]. O [WDC 3.5.9] descreve a condição de parada de forma simplificada; o comportamento real é "até C=$FFFF".
- No fim, **DB = banco de destino**. Salve com PHB/PLB [WDC 7.18][Clark][Mesen2].
- Com X=1 (índices de 8 bits) os endereços ficam presos em $00xx. Use `REP #$10` antes.
- Bytes de máquina: `opcode, banco destino, banco origem` [WDC][Clark].
- Sintaxe: padrão WDC e ca65 escrevem `MVN origem,destino`; **o asar escreve `MVN destino,origem`** (grava os operandos na ordem de máquina, conferido no `arch-65816.cpp`, e o manual anota "destination, source") [asar][ca65][WDC 6]. Sintaxe do WLA-DX: não confirmado.

Exemplo asar, copiando 256 bytes de $7F0000 para $7E2000:

```asm
    PHB
    REP #$30
    LDA #$00FF        ; 256 bytes - 1
    LDX #$0000        ; origem (dentro do banco $7F)
    LDY #$2000        ; destino (dentro do banco $7E)
    MVN $7E,$7F       ; asar: destino, origem
    PLB
```
