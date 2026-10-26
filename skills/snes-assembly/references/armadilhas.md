# Armadilhas

Os erros que mais quebram código de 65816, principalmente em ROM hack. Cada item tem o sintoma, a causa e o conserto.

## 1. Registrador no tamanho errado depois de um hook

**Sintoma**: o jogo trava ou faz coisa estranha logo depois do seu código, às vezes só em certas telas.
**Causa**: o código original estava com M/X num estado (ex.: A de 8 bits) e o hook voltou com outro, ou o seu código assumiu um tamanho que não era o do ponto de entrada. O montador não sabe o estado real: ele monta `LDA #$10` com 2 ou 3 bytes conforme o que você escreveu, e se a CPU estiver no outro tamanho ela lê a instrução seguinte desalinhada.
**Conserto**:
- Descubra o estado de M/X no ponto do hook (debugger do Mesen ou bsnes, ou lendo o código original até o último REP/SEP/PLP).
- Entre com `PHP` e saia com `PLP`: restaura M, X e as outras flags.
- Escreva imediatos com tamanho explícito no asar (`LDA.b #$10`, `LDX.w #$0100`). O asar avisa imediato sem tamanho com `-wWimplicitly_sized_immediate` [asar].
- Atenção: `PLP` também restaura C, Z, N. Se o código original testa uma flag logo depois do hook, devolva a flag certa em vez de restaurar tudo.

```asm
org $008123            ; endereço do hook (exemplo)
    JSL MeuCodigo      ; 4 bytes; complete com NOP se a instrução substituída for maior

freecode
MeuCodigo:
    PHP
    REP #$30
    PHA : PHX : PHY
    ; ... seu código em 16 bits ...
    PLY : PLX : PLA
    PLP
    ; refaça aqui as instruções originais que o JSL sobrescreveu
    RTL
```

## 2. A de 16 bits com B escondido

**Sintoma**: valor de 16 bits com byte alto aleatório; índice que pula pra longe; escrita que pisa no byte seguinte.
**Causa**: `SEP #$20` não zera B [WDC 7.23]. Depois de `REP #$20`, A vale B:A, com o B que sobrou de antes. O mesmo vale pra `TAX`/`TAY` com X=0 e M=1: copia os 16 bits de C.
**Conserto**: ao passar de 8 pra 16 bits, zere o byte alto (`REP #$20` + `AND #$00FF`, ou `LDA #$0000` antes de carregar o byte, ou `XBA` + `LDA #$00` + `XBA` em 8 bits). Antes de `TAX` com índice de 16 bits, garanta que B está limpo.

## 3. Índice de 8 bits apaga o byte alto

**Causa**: `SEP #$10` zera XH e YH na hora; `REP #$10` depois não traz de volta [Clark]. **Conserto**: salve X/Y na pilha (em 16 bits) antes de mudar pra 8 bits se for precisar do valor inteiro.

## 4. Banco de dados errado

**Sintoma**: tabela lida com lixo; funciona no banco original e quebra quando o código vai pra freespace.
**Causa**: modos absolutos (`LDA tabela,x`, `LDA ($00),y`) usam **DB**, não o banco do código. Código em freespace num banco novo continua com o DB de quem chamou. Interrupção também não muda DB.
**Conserto**:
- Use long (`LDA.l tabela,x`) pra acesso pontual, ou
- `PHB` / `PHK` / `PLB` no começo (DB = banco do código) e `PLB` no fim.
- No asar, o comando `bank` só muda a **escolha de tamanho** do montador, não o registrador [asar "bank"].
- Depois de `MVN`/`MVP`, DB = banco de destino.

## 5. D desalinhado custando ciclo (ou lendo o lugar errado)

**Causa**: D com byte baixo diferente de $00 adiciona 1 ciclo em todo acesso direct [WDC 3.5.17]. E se o código original mudou D (ex.: D=$4300 pra DMA, D=$2100 pra PPU), um `LDA $10` no seu hook lê $4310, não $0010.
**Conserto**: confira D no ponto do hook; use absoluto (`LDA.w $0010`) ou long quando não souber D. Ao mudar D, `PHD`/`PLD`.

## 6. RTS onde devia ser RTL (e vice-versa)

`JSL` empilha 3 bytes, `JSR` 2. Rotina em freespace chamada por `JSL` termina em `RTL`. Desvio pra outro banco com `JMP` não existe: use `JML`. Código não atravessa a fronteira de banco: PC dá a volta de $FFFF pra $0000 no mesmo banco [WDC 3.4].

## 7. Interrupção que estraga o estado

O NMI/IRQ pode entrar no meio de qualquer código. O tratador tem que salvar A, X, Y **em 16 bits** (`REP #$30` antes de empilhar), DB e D, e restaurar na ordem inversa. M e X voltam pelo RTI (P empilhado). Rodar o tratador sem ajustar DB lê dados do banco errado.

## 8. Ordem dos operandos de MVN/MVP

WDC e ca65: `MVN origem,destino`. **asar: `MVN destino,origem`** [asar manual + `arch-65816.cpp`]. Copiar código entre montadores sem inverter troca origem e destino em silêncio. Os bytes de máquina são sempre `54 destino origem`.

## 9. Page wrap do modo emulação

Só aparece no boot ou em código que volta pro modo emulação: com DL=$00, instruções "antigas" dão a volta na página direct e a pilha fica na página 1; as "novas" (`[d]`, `PEI`, `JSL` ...) não [Clark][WDC 7.1, 7.2]. No modo nativo não existe wrap de página.

## 10. Diferenças de sintaxe entre asar, ca65 e WLA-DX

| Assunto | asar | ca65 | WLA-DX |
|---|---|---|---|
| CPU | `arch 65816` | `.p816` / `--cpu 65816` | `wla-65816` |
| Tamanho do imediato | sufixo no opcode: `LDA.b #1`, `LDA.w #1`; sem sufixo, pelo número de dígitos hex | diretivas `.a8/.a16/.i8/.i16`, ou `.smart` (segue REP/SEP) | sufixo no operando `LDA #1.w`, `.ACCU 8/16`, `.INDEX 8/16`; acompanha REP/SEP sozinho |
| Forçar direct/abs/long | `LDA.b`, `LDA.w`, `LDA.l` | prefixo `z:`, `a:`, `f:` | `label.b`, `label.w`, `label.l` |
| Pulo long | `JML`, `JSL` (`JMP` long só no modo xkas, obsoleto) | `jml`, `jsl` (`jmp`/`jsr` long só com `long_jsr_jmp_rts`) | não confirmado |
| MVN/MVP | `MVN dst,src` | `mvn src,dst` ou `mvn #^src,#^dst` | não confirmado |
| `BRK` sem operando | 2 bytes (`00 00`) | 1 byte | não confirmado |
| Apelidos | não aceita `SWA`, `TAD` etc. | aceita `CPA DEA INA SWA TAD TAS TDA TSA` | não confirmado |
| Endereço do código | `org $008000` (endereço SNES; o mapeamento vem de `lorom`/`hirom`) | segmentos + arquivo de config do linker | `.BANK`/`.ORG`/`.SECTION` com `.MEMORYMAP` |
| Patch sobre ROM existente | nativo: `org`, `freecode`, `autoclean`, `pushpc/pullpc` | não é o foco | não é o foco |

Fontes: [asar] manual e `arch-65816.cpp`; [ca65] seções 65816, `.SMART`, `.A8/.A16`, prefixos de endereço; [WLA-DX] `asmsyntax.rst` e `asmdiv.rst`.

Avisos do [ca65] que valem pra qualquer montador: `.smart` acompanha REP/SEP pela ordem do texto, não pelo fluxo de execução; depois de um desvio ou de uma sub-rotina o montador pode estar errado sobre M/X. Na dúvida, declare o tamanho.

Ainda sem confirmação neste repositório: o mnemônico de pulo long, a sintaxe de MVN e o tamanho de `BRK` no WLA-DX; o exemplo de bytes da doc do WLA-DX para `.ACCU 16` aparece em ordem big-endian e parece erro de digitação da documentação.
