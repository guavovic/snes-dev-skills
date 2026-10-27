# Espaço livre e hooks

## Achar espaço livre com segurança

Ordem de preferência:

1. **Área expandida.** Tudo que você acrescentou no fim da ROM é seu. É o lugar mais seguro.
2. **Área provada livre na ROM original.** Uma faixa que nunca é lida. Prova = rodar o jogo com breakpoint de leitura (ou log de acesso) na faixa e passar pelas partes do jogo que podem usar aquilo. "Tá cheio de `$FF`" não é prova: tabela, gráfico e som têm trechos repetidos.
3. **Código que você tornou morto.** Rotina original substituída inteira pelo seu hook. Marque com comentário o intervalo reaproveitado.

**RATS.** É a marca que o asar grava antes de cada bloco de freespace: "STAR" + (tamanho - 1) em 16 bits little-endian + o mesmo valor XOR `$FFFF`, 8 bytes no total [asar]. Ferramentas da comunidade de Super Mario World leem essas marcas pra não sobrescrever o bloco de outro patch. Em jogo que não é SMW, RATS só ajuda se todos os seus patches usarem asar.

**Como o asar procura** (LoROM): sequência longa de `freespacebyte` (padrão `$00`), começando no offset `$80000` (banco `$10`); abaixo disso ele não procura [asar]. `freecode` busca nos bancos `$10-$3F`; `freedata` prefere `$40-$6F` e `$F0-$FF` e cai pra `$10-$3F` [asar]. No máximo 125 blocos de freespace por patch [asar].

Consequência pra jogo que não é SMW: se a ROM original tem mais de 512 KB, a busca a partir do banco `$10` cai dentro do jogo e pode achar uma sequência de zeros que é dado. Saídas:

- expandir antes, preencher com `freespacebyte` e conferir que o original não tem sequência longa desse byte a partir de `$80000`; ou
- asar 2.0: `freespace ...,start=$xxxxxx` pra começar a busca onde você sabe que é livre [asar]; ou
- `org` direto numa área provada livre, com `assert pc() <= $fim` no final pra não estourar.

## Anatomia de um hook com JSL

Objetivo: no endereço X do jogo, desviar pra rotina nova e voltar.

1. **Escolha o ponto.** Precisa de pelo menos 4 bytes (tamanho do `JSL`, opcode `$22`) [sneslab][fullsnes], e o trecho sobrescrito tem que terminar no fim de uma instrução: se o 4º byte cai no meio de uma, sobrescreva até o fim dela e complete com `NOP` (`$EA`).
2. **Evite** trecho que seja destino de branch vindo de outro lugar (quem pula pro meio dos seus bytes cai no meio do `JSL`) e trecho com branch relativo ou `JSR`, que mudam de significado quando refeitos em outro banco.
3. **Anote o original:** endereço, bytes e instruções. Vai pro comentário e pra rotina nova.
4. **Escreva a rotina:** salva o estado, faz o trabalho, restaura o estado, refaz as instruções originais, `RTL`.

`JSL` empilha PB e depois o endereço do último byte da instrução (opcode + 3); `RTL` desempilha, soma 1 e restaura PB [sneslab][fullsnes]. Por isso a volta cai no byte seguinte ao `JSL`: se você completou com `NOP`, ele executa o `NOP` e segue.

```asm
; Hook no jogo base: em $00:8123 o original era
;   A5 10      lda $10
;   8D 00 02   sta $0200
; 5 bytes. JSL ocupa 4, sobra 1 -> NOP.
org $008123
    autoclean jsl HookContador
    nop

freecode
HookContador:
    php                 ; salva flags, inclusive M e X
    phb                 ; salva DB
    phd                 ; salva D (só se for mexer em D)
    phk
    plb                 ; DB = banco desta rotina
    rep #$30            ; A, X, Y em 16 bits
    ; ... trabalho novo aqui ...
    pld
    plb
    plp                 ; M/X e flags como o jogo deixou
    lda $10             ; refaz as instruções sobrescritas,
    sta $0200           ; com o mesmo M/X e DB do original
    rtl
```

As instruções originais vão depois do `PLP` porque têm que rodar com o M/X e o DB do jogo (`lda $10` em 8 bits lê 1 byte, em 16 lê 2), e as flags N/Z que elas deixam são as que o código seguinte espera.

O manual do asar traz o mesmo padrão: `org` no ponto do hook, `autoclean jsl`, `freecode`, rotina, instruções refeitas, `rtl` [asar].

## O que preservar

| Estado | Como salvar | Por quê |
|---|---|---|
| Flags, M, X | `PHP` / `PLP` | O código seguinte pode usar C, Z, N e assume o tamanho de registrador |
| A, X, Y | `PHA`/`PHX`/`PHY` e os `PL*` | Só se o original usa o valor depois. Desempilhe no mesmo tamanho em que empilhou |
| Byte alto de X/Y | Salve X e Y em 16 bits antes de ir pra 8 | `SEP #$10` zera o byte alto de X e Y, e `PLP` não devolve [fullsnes] |
| DB | `PHB` ... `PLB` | Endereço absoluto usa DB; o seu dado está no seu banco |
| D | `PHD` ... `PLD` | Endereço direct page usa D; só se você mudar D |
| Pilha | Equilíbrio exato | Cada push com seu pull; `RTL` lê 3 bytes do topo |

Opcodes usados: `PHP $08`, `PLP $28`, `PHB $8B`, `PLB $AB`, `PHK $4B`, `PHD $0B`, `PLD $2B`, `REP $C2`, `SEP $E2` [sneslab][fullsnes]. Tamanho, ciclos e flags de cada um: `snes-assembly`.

## Variações

- **JML ida e volta:** `JML` (opcode `$5C`, 4 bytes) pro código novo e outro `JML` de volta pro endereço depois do trecho sobrescrito [sneslab][fullsnes]. Não usa pilha, útil quando o trecho mexe na pilha. A volta é endereço fixo: anote no comentário.
- **Trampolim:** quando só cabe um `JSR` (3 bytes, mesmo banco), coloque num espaço livre do banco original um `JSL Rotina` seguido de `RTS`, e aponte o `JSR` pra ele.
- **Hook em vetor:** troque o ponteiro de NMI/IRQ nativo (`$FFEA`/`$FFEE`) por uma rotina em banco `$00` que faça o trabalho e termine com `JML` pro endereço antigo. O vetor tem 16 bits e o banco é sempre `$00` [fullsnes]. Detalhe de NMI e IRQ: `snes-hardware`.
- **Hook de dado:** às vezes não precisa de código: troque um ponteiro de tabela por uma tabela nova no freespace (`autoclean dl Tabela`) [asar].
