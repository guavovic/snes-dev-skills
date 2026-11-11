# Fontes da skill snes-assembly

Pesquisa feita em 26/10/2026. Cada fato de registrador, bit, ciclo ou endereço foi conferido em pelo menos duas fontes da lista; quando não deu, está marcado "não confirmado" no texto. Revisão de 02/11/2026: WLA-DX conferido no código, livro de Eyes e Lichty, tutorial de interrupções do 6502.org, temporização no código do bsnes, e todos os exemplos montados no asar 1.91 (o de MVN também rodado no Mesen 2).

| Nome | Fonte | Autor / ano | Cobre | Confiança |
|---|---|---|---|---|
| [WDC] | W65C816S 8/16-bit Microprocessor Datasheet, https://www.westerndesigncenter.com/wdc/documentation/w65c816s.pdf | Western Design Center, revisão de 13/03/2024 | Registradores, reset, modos de endereçamento, vetores, tabela de opcodes e ciclos, caveats (seção 7) | Alta. Fonte primária, mas tem uma contradição interna (JMP (a,x), ver abaixo) |
| [Clark] | "65C816 Opcodes", http://www.6502.org/tutorials/65c816opcodes.html (lido via web.archive.org) | Bruce Clark, 6502.org | Tabela completa de opcodes com fórmulas de bytes e ciclos, flags, cada instrução em detalhe, modo emulação | Alta. Tutorial revisado da comunidade 6502.org, base da tabela de instruções |
| [fullsnes] | nocash SNES hardware specifications, https://problemkaputt.de/fullsnes.txt | Martin Korth (nocash) | Registradores e apelidos da CPU no SNES, velocidade de memória, $420D, vetores no SNES | Alta para o hardware do SNES; a lista simplificada de ciclos da CPU tem resquícios de 6502, preferir [WDC]/[Clark] |
| [SFC wiki] | "65816 Reference", https://wiki.superfamicom.org/65816-reference | superfamicom.org (wiki colaborativa) | Tabela de opcodes com ciclos base e notas | Média. Bate com [Clark] em 253 de 256 opcodes; erros em WDM, MVN/MVP e no vetor BRK de emulação |
| [asar] | Manual do asar (`docs/manual/index.html`) e `src/asar/arch-65816.cpp`, https://github.com/RPGHacker/asar | RPGHacker e colaboradores | Sintaxe 65816 do asar, sufixos `.b/.w/.l`, `bank`, `optimize`, `org`, `freecode`, `autoclean`, ordem do MVN, bytes do BRK | Alta para o asar (manual conferido contra o código) |
| [ca65] | ca65 Users Guide, https://cc65.github.io/doc/ca65.html | projeto cc65 | `.a8/.a16/.i8/.i16`, `.smart`, prefixos `z:/a:/f:`, MVN, BRK, apelidos | Alta para o ca65 |
| [WLA-DX] | Documentação em https://github.com/vhelin/wla-dx/tree/master/doc (`asmsyntax.rst`, `asmdiv.rst`) | Ville Helin e colaboradores | Sufixos `.b/.w/.l` no operando, `.ACCU`, `.INDEX` | Média: só os pontos citados foram lidos |
| [Mesen2] | `Core/SNES/SnesCpu.Instructions.h`, https://github.com/SourMesen/Mesen2 | Sour (Mesen) | Desempate: banco do ponteiro de JMP (a,x), MVN, sequência de interrupção, vetor BRK em emulação | Alta (emulador de alta precisão) |
| [WLA-DX código] | `wla-65816` no commit ef73ebe: tabela `i65816.c`, `decode.c`, `phase_4.c` e testes `tests/65816/all_instructions_test`, https://github.com/vhelin/wla-dx | Ville Helin e colaboradores | Ordem do MVN, pulo long, BRK, apelidos, bytes do `.ACCU 16` | Alta para o WLA-DX; conferido rodando o v10.7 em 11/11/2026 ([Teste local: WLA-DX]) |
| [Teste local: WLA-DX] | WLA-DX v10.7 oficial (`wla_dx_v10.7_Win64.zip` da página de releases), `wla-65816` + `wlalink -r`, um arquivo por caso, 11/11/2026 | este repositório | `mvn $12,$34` = `54 34 12`; `jml $123456` e `jmp $123456.l` = `5C 56 34 12`; `brk $00` = `00 00`; `dea ina swa tad tas tda tsa` = `3A 1A EB 5B 1B 7B 3B`; `.ACCU 16` + `and #6` = `29 06 00`; `cop` = `00 02` (errado); `cop $12` = `02 12` | Alta para o que foi medido |
| [E&L] | "Programming the 65816, Including the 65C02 and 65802", scan em https://archive.org/details/0893037893ProgrammingThe65816 | David Eyes e Ron Lichty, 1986 | MVN/MVP (sintaxe, interrupção no meio, DB), tabela de apelidos padrão, `JMP >` long | Alta: livro de referência feito com a WDC; o texto vem de OCR, e a sneslab.net/wiki/Eyes_%26_Lichty lista errata do PDF antigo |
| [6502.org int] | "Investigating 65C816 Interrupts", http://6502.org/tutorials/65c816interrupts.html (lido via web.archive.org) | BCS Technology (BigDumbDinosaur), 1994-2015 | Ciclos da entrada na interrupção, latência, `WAI` com `SEI` | Alta: tutorial revisado do 6502.org, só modo nativo |
| [bsnes] | `bsnes/sfc/cpu/timing.cpp`, `irq.cpp`, `cpu.cpp`, `io.cpp`, commit 78474e5d, https://github.com/bsnes-emu/bsnes | byuu (Near) e colaboradores | Refresh da DRAM, ponto do NMI e do H-IRQ, teste de interrupção no penúltimo ciclo, `irqLock`, `WAI` | Alta (emulador de precisão de ciclo) |
| [Anomie timing] | "Timing", https://wiki.superfamicom.org/timing | anomie | Refresh, NMI, H-IRQ, saída do `WAI` | Média: o próprio texto marca parte como teoria; bate com o [bsnes] |
| [SNESdev timing] | "Timing", https://snes.nesdev.org/wiki/Timing | comunidade SNESdev | Clocks por linha, refresh de 40 clocks | Alta |
| [asar código] | Código do asar na tag v1.91 (commit 6a6dbda): `src/asar/assembleblock.cpp` (comando `asar`, `math pri`, `math round`), `src/asar/asar_math.cpp` (conta nos dois modos e aviso), `src/asar/main.cpp` (padrão por patch), https://github.com/RPGHacker/asar/tree/v1.91 | RPGHacker e colaboradores | Precedência, arredondamento, formato do número da versão, `Estart_of_file`, quando o aviso aparece | Alta |
| asar 1.91 (teste) | Montagem real dos exemplos e da coluna de sintaxe da tabela de instruções, numa ROM vazia própria; em 03/11/2026, conta com e sem `asar 1.90` e todos os blocos das sete skills montados nos dois modos | este repositório, 02/11/2026 e 03/11/2026 | Bytes gerados, avisos, apelidos, `autoclean`, precedência, divisão, define, `-werror` | Alta para o asar 1.91 |

## Não consultadas

- Fontes em japonês: buscadas em 02/11/2026 (65816 命令表, サイクル, スーパーファミコン アセンブラ, Wikipédia japonesa). Só apareceu o verbete geral "65816 (コンピュータ)" e páginas que repetem material em inglês; nenhuma fonte técnica primária em japonês de acesso livre. Descartado.
- Um "primer" de 65816 no 6502.org: não existe com esse nome. O que o site tem são o "65C816 Opcodes" [Clark] e o tutorial de interrupções [6502.org int], os dois usados aqui.
- asar 2.0: que ele só faz conta com precedência vem do manual [asar]; a versão beta não foi montada aqui.

## Divergências registradas

| Assunto | Diz A | Diz B | Vale |
|---|---|---|---|
| Banco do ponteiro de JMP (a,x) / JSR (a,x) | [WDC 3.5.2]: banco 0 | [WDC 7.9], [Clark 5.5], [Mesen2]: PB | PB |
| Vetor BRK no modo emulação | [SFC wiki]: $FFF6 | [WDC tabela 5-2], [Clark], [Mesen2]: $FFFE (mesmo do IRQ) | $FFFE |
| Bytes do BRK | [SFC wiki]: 2 | [Clark]: 1 + assinatura | Os dois descrevem o mesmo: 1 opcode + 1 assinatura pulada |
| Ciclos do WDM | [SFC wiki]: 0 | [Clark]: 2 | 2; reservado pela [WDC 7.16] |
| Ciclos do MVN/MVP | [SFC wiki]: célula corrompida | [Clark], [fullsnes], [Mesen2]: 7 por byte | 7 por byte |
| Parada do MVN/MVP | [WDC 3.5.9] simplifica ("decrementa C se maior que zero") | [Clark], [fullsnes], [Mesen2]: repete até C=$FFFF | até C=$FFFF (move C+1 bytes) |
| Ordem dos operandos do MVN | [WDC], [ca65]: origem, destino | [asar]: destino, origem | Depende do montador; bytes de máquina sempre `op dst src` |
| Bytes do exemplo `.ACCU 16` | [WLA-DX] `asmdiv.rst` mostra `$29 $00 $06` | [WLA-DX código] `phase_4.c` grava em little-endian: `$29 $06 $00`, confirmado montando no v10.7 | Erro da documentação deles |
| Ordem do MVN no WLA-DX | (não havia fonte) | [WLA-DX código] teste `mvn $12,$34` = `54 34 12` | origem, destino, como WDC e ca65 |
| Posição do refresh da DRAM na linha | [Anomie timing]: ~536, o primeiro em 538, "teoria" | [bsnes]: 530 na CPU rev. 1, 538 na rev. 2 | Depende da revisão; os 40 clocks batem em todas |
| `COP` sem operando | [asar] 1.91 testado: `02 00` | [WLA-DX código]: valor $0200 na tabela, possível `00 02` | Resolvido rodando o WLA-DX v10.7: sai `00 02`, bug deles; escrever sempre `COP $xx` |
| Versão que liga a precedência | [asar] manual 1.9 e 1.91: "`asar 1.9` ou maior" | [asar código] exige dois dígitos depois do ponto; `asar 1.9` dá `Einvalid_version_number` [asar 1.91 (teste)] | `asar 1.90` |
