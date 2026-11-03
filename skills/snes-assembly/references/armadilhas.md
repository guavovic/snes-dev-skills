# Armadilhas

Os erros que mais quebram código de 65816, principalmente em ROM hack. Cada item tem o sintoma, a causa e o conserto.

## 1. Registrador no tamanho errado depois de um hook

**Sintoma**: o jogo trava ou faz coisa estranha logo depois do seu código, às vezes só em certas telas.
**Causa**: o código original estava com M/X num estado (ex.: A de 8 bits) e o hook voltou com outro, ou o seu código assumiu um tamanho que não era o do ponto de entrada. O montador não sabe o estado real: ele monta `LDA #$10` com 2 ou 3 bytes conforme o que você escreveu, e se a CPU estiver no outro tamanho ela lê a instrução seguinte desalinhada.
**Conserto**:
- Descubra o estado de M/X no ponto do hook (debugger do Mesen ou bsnes, ou lendo o código original até o último REP/SEP/PLP).
- Entre com `PHP` e saia com `PLP`: restaura M, X e as outras flags.
- Escreva imediatos com tamanho explícito no asar (`LDA.b #$10`, `LDX.w #$0100`). A opção `-wWimplicitly_sized_immediate` faz o asar avisar só quando o tamanho não sai do texto: literal decimal (`LDA #128`), expressão (`LDA #$0080+0`) ou label (`LDA #alvo`). Hex com quantidade de dígitos (`#$80`, `#$0080`) já conta como tamanho escolhido e não gera aviso, mesmo que seja o tamanho errado pro estado de M [asar], testado no asar 1.91.
- Atenção: `PLP` também restaura C, Z, N. Se o código original testa uma flag logo depois do hook, devolva a flag certa em vez de restaurar tudo.

```asm
org $008123            ; endereço do hook (exemplo)
    autoclean JSL MeuCodigo  ; 4 bytes; complete com NOP se a instrução substituída for maior

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

Este exemplo foi montado no asar 1.91 sobre uma ROM LoROM vazia de 1 MB. Sem o `autoclean`, o asar avisa `Wfreespace_leaked`: aplicar o patch de novo ocuparia outro bloco e deixaria o antigo perdido. Com o `autoclean`, aplicar duas vezes dá a mesma ROM. No mesmo teste, o `freecode` numa ROM de 128 KB falhou com "No freespace found": o asar não procurou espaço livre nos primeiros bancos, então expanda a ROM antes de usar `freecode` [asar].

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

WDC, ca65 e WLA-DX: `MVN origem,destino`. **asar: `MVN destino,origem`** [asar manual + `arch-65816.cpp`]. Copiar código entre montadores sem inverter troca origem e destino em silêncio. Os bytes de máquina são sempre `54 destino origem` [WDC][E&L].

Conferido montando: no asar 1.91, `MVN $34,$12` gera `54 34 12`; no WLA-DX, o teste `all_instructions_test` do repositório espera `mvn $12,$34` = `54 34 12` [WLA-DX código]. O asar também aceita um operando só de 16 bits, no formato `$SSDD` (byte alto = origem): `MVN $7E7F` gera `54 7F 7E`, ou seja, origem $7E e destino $7F, ao contrário da forma com vírgula. Evite essa forma.

## 9. Page wrap do modo emulação

Só aparece no boot ou em código que volta pro modo emulação: com DL=$00, instruções "antigas" dão a volta na página direct e a pilha fica na página 1; as "novas" (`[d]`, `PEI`, `JSL` ...) não [Clark][WDC 7.1, 7.2]. No modo nativo não existe wrap de página.

## 10. Diferenças de sintaxe entre asar, ca65 e WLA-DX

| Assunto | asar | ca65 | WLA-DX |
|---|---|---|---|
| CPU | `arch 65816` | `.p816` / `--cpu 65816` | `wla-65816` |
| Tamanho do imediato | sufixo no opcode: `LDA.b #1`, `LDA.w #1`; sem sufixo, pelo número de dígitos hex | diretivas `.a8/.a16/.i8/.i16`, ou `.smart` (segue REP/SEP) | sufixo no operando `LDA #1.w`, `.ACCU 8/16`, `.INDEX 8/16`; acompanha REP/SEP sozinho |
| Forçar direct/abs/long | `LDA.b`, `LDA.w`, `LDA.l` | prefixo `z:`, `a:`, `f:` | `label.b`, `label.w`, `label.l` |
| Pulo long | `JML`, `JSL`, `JML.l` (`JMP $C08000` e `JSR.l` dão erro no 1.91) | `jml`, `jsl` (`jmp`/`jsr` long só com `long_jsr_jmp_rts`) | `JML`, `JSL`, ou `JMP`/`JSR` com operando de 24 bits, com `>` ou com `.l` |
| MVN/MVP | `MVN dst,src` | `mvn src,dst` ou `mvn #^src,#^dst` | `mvn src,dst` |
| `BRK` sem operando | 2 bytes (`00 00`); `COP` sem operando = `02 00` | 1 byte | 2 bytes (`00 00`); `BRK $01` = `00 01` |
| Apelidos | nenhum (`BLT BGE CPA DEA INA SWA TAD TAS TDA TSA` dão erro); `INC`/`DEC` sem operando = `$1A`/`$3A` | aceita `CPA DEA INA SWA TAD TAS TDA TSA` | aceita `DEA INA SWA TAD TAS TDA TSA`; não tem `BLT`, `BGE` nem `CPA` |
| Endereço do código | `org $008000` (endereço SNES; o mapeamento vem de `lorom`/`hirom`) | segmentos + arquivo de config do linker | `.BANK`/`.ORG`/`.SECTION` com `.MEMORYMAP` |
| Patch sobre ROM existente | nativo: `org`, `freecode`, `autoclean`, `pushpc/pullpc` | não é o foco | não é o foco |

Fontes: [asar] manual e `arch-65816.cpp`, coluna conferida montando no asar 1.91; [ca65] seções 65816, `.SMART`, `.A8/.A16`, prefixos de endereço; [WLA-DX] `asmsyntax.rst` e `asmdiv.rst`; [WLA-DX código] tabela de instruções `i65816.c` e testes `tests/65816` (lidos, não executados). Os apelidos `DEA INA SWA TAD TAS TDA TSA` vêm da tabela de apelidos de [E&L], que também lista `BLT`/`BGE` e `JMP` long como sinônimos de `BCC`/`BCS` e `JML`.

Avisos do [ca65] que valem pra qualquer montador: `.smart` acompanha REP/SEP pela ordem do texto, não pelo fluxo de execução; depois de um desvio ou de uma sub-rotina o montador pode estar errado sobre M/X. Na dúvida, declare o tamanho.

Erro da documentação do WLA-DX: o exemplo de `.ACCU 16` em `asmdiv.rst` mostra `AND #6` como `$29 $00 $06`, mas o código (`phase_4.c`) grava o imediato de 16 bits em little-endian, o que dá `$29 $06 $00` [WLA-DX código].

Ainda sem confirmação: `COP` sem operando no WLA-DX. A tabela `i65816.c` guarda o valor $0200, que gravado em little-endian sairia `00 02` (opcode errado); o WLA-DX não foi executado aqui. Escreva sempre `COP $xx` com assinatura.

## 11. Conta sem precedência no asar 1.x

**Sintoma**: tamanho de tabela, endereço calculado ou constante sai com outro valor; o asar monta, só mostra um aviso `Wfeature_deprecated` com "xkas style left to right math".
**Causa**: por compatibilidade com o xkas, o asar 1.x faz a conta da esquerda para a direita, sem precedência de operador (`math pri off` é o padrão). `2+3*4` dá 20 e `$1000+1*$200` dá `$200200` em vez de `$1200` [asar]. O asar 2.0 vai deixar só a conta com precedência [asar].
**Conserto**:
- **Convenção desta coleção: parênteses sempre que a expressão mistura operadores** (`$1000+(1*$200)`, `(!largura*!altura)/2`). Com parênteses o valor é o mesmo com e sem `asar 1.90`, então o trecho funciona colado em qualquer projeto.
- Num projeto novo, escreva `asar 1.90` no **topo** do arquivo principal. Isso liga a precedência e também desliga o arredondamento no meio da conta (`math round off`) para o patch inteiro, inclusive os arquivos do `incsrc` [asar código].
- O número da versão tem dois dígitos depois do ponto: `asar 1.9` dá erro `Einvalid_version_number`; `asar 1.90` e `asar 1.91` valem [asar código]. Ele tem de vir antes de qualquer outro comando (comentário e linha em branco podem vir antes); depois de um comando, dá `Estart_of_file` [asar código].
- O aviso só aparece quando as duas contas dão resultados diferentes: o asar calcula também com precedência e compara [asar código]. Trate o aviso como erro (`-werror`, que no 1.91 aborta a montagem): sem aviso, o valor é o mesmo nos dois modos, salvo a divisão (abaixo).
- **Define é texto.** `!a = 1+2` seguido de `db !a*3` vira `db 1+2*3`: 9 sem `asar 1.90`, 7 com ele. Coloque o valor entre parênteses (`!a = (1+2)`) ou avalie na hora com `!a #= 1+2` [asar].
- **Divisão muda sem aviso.** Sem `asar 1.90`, cada passo é truncado (`7/2*2` dá 6); com ele, só o resultado final (`7/2*2` dá 7). A comparação do aviso não pega essa diferença. Quando o truncamento importa, escreva `floor(7/2)*2` [asar].

```asm
db 2+3*4            ; 20 sem asar 1.90 (com aviso), 14 com asar 1.90
db 2+(3*4)          ; 14 nos dois modos
dw $1000+(1*$200)   ; $1200 nos dois modos
db floor(7/2)*2     ; 6 nos dois modos
```

Conferido no asar 1.91 em 03/11/2026, numa ROM vazia própria [asar 1.91 (teste)]: sem `asar 1.90` o bloco gerou `14 0E 00 12 06` e um aviso só na primeira linha; com `asar 1.90` no topo, `0E 0E 00 12 06`. Um comentário e uma linha em branco antes do `asar 1.90` não atrapalharam, e `-werror` abortou a montagem por causa do aviso. No mesmo teste, `!a = 1+2` com `db !a*3` deu 9 e 7, `7/2*2` deu 6 e 7, e `asar 1.9` parou com `Einvalid_version_number`.

Em 03/11/2026 todos os blocos de asar das sete skills foram conferidos atrás de expressão que mistura operadores sem parênteses, inclusive depois de expandir os defines: nenhum muda de valor com `asar 1.90`. Os que fazem conta em `snes-tecnicas` usam um operador só (`#8*!fila_max`) ou parênteses com operadores do mesmo nível (`!m7_k/(!l+16)` vira `256*64/(!l+16)`, igual nos dois modos).
