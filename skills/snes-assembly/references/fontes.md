# Fontes da skill snes-assembly

Pesquisa feita em 26/10/2026. Cada fato de registrador, bit, ciclo ou endereço foi conferido em pelo menos duas fontes da lista; quando não deu, está marcado "não confirmado" no texto.

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

## Não consultadas

- "Programming the 65816" (David Eyes e Ron Lichty, 1986): não está disponível livremente; nenhum fato desta skill depende só dele.
- Primer de 65816 do 6502.org além do "65C816 Opcodes": não lido nesta rodada.
- Fontes em japonês (ex.: 65816 アセンブラ): não pesquisadas nesta rodada.
- Código do bsnes/higan: não foi preciso, o [Mesen2] resolveu os desempates.

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
| Bytes do exemplo `.ACCU 16` | [WLA-DX] mostra `$29 $00 $06` | little-endian daria `$29 $06 $00` | Provável erro da documentação; não confirmado |
