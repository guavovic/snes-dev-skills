# Fontes da skill snes-desmontagem

Consultadas em 26/10/2026; revisão da v0.2 em 02/11/2026. Nível de confiança: **alta** = código-fonte ou documentação do próprio projeto, ou execução própria; **média** = README ou wiki sem conferência no código; **apoio** = só para contexto ou desempate. Na v0.1 nenhum executável foi rodado; na v0.2 o que está marcado [Teste local] foi conferido em execução.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [MesenCE src] | MesenCE, código-fonte, commit 4b8a196. https://github.com/nesdev-org/MesenCE | nesdev-org (fork comunitário do Mesen 2) | 2026 (07/10/2026) | CDL (flags, formato, Generate ROM; na v0.2 `SnesDebugger.cpp` e `CodeDataLogger.h` para a marcação de operando), trace logger e condição (`BaseTraceLogger.h`, `ExpressionEvaluator.cpp`, `ExpressionEvaluator.Snes.cpp`, `ExpressionTooltipHelper.cs`, `Breakpoint.cpp`), Memory Search, breakpoints e opções de parada, import e export de labels (.mlb, .sym, .dbg), loader de .tbl, API Lua; na #31 `CodeDataLogger.cpp`, `SnesCodeDataLogger.h` (`RebuildPrgCache`), `SnesDisUtils.cpp` (tabela de modos e tamanhos), `SnesDebugger.cpp` e `BaseCartridge.cpp` (CRC e cabeçalho de copiadora) para o conversor. Os mesmos arquivos no Mesen2 original (SourMesen/Mesen2, commit b9fa69d) só diferem em formatação | Alta |
| [Mesen2 src] | Mesen 2, código-fonte (repositório arquivado). https://github.com/SourMesen/Mesen2 | Sour | 2025 | Mesmas áreas; usado para confirmar que o fork mantém os nomes | Alta |
| [Mesen docs] | Documentação do Mesen, página "Debugger", seções Syntax e Breakpoint configuration. https://www.mesen.ca/docs/debugging/debugger.html | Sour | sem data (versão 0.9.9, NES) | Sintaxe de expressão: `$`, `%`, `[ ]`, `{ }`, `:`, operadores do C, valores especiais | Apoio: é de outra versão; confirma a base da sintaxe |
| [SNESdev Tools] | SNESdev wiki, página "Tools". https://snes.nesdev.org/wiki/Tools | comunidade nesdev | 2026 (consulta) | Avaliação dos emuladores e debuggers | Média |
| [bsnes-plus] | README do bsnes-plus. https://github.com/devinacker/bsnes-plus | devinacker e colaboradores | 2025 (push em 22/03/2025) | Destaque de código e dado, breakpoints espelhados, SA-1 e SuperFX, formatos de símbolos, trace mask | Média |
| [DiztinGUIsh] | README do DiztinGUIsh. https://github.com/IsoFrieze/DiztinGUIsh | IsoFrieze e colaboradores | 2026 (consulta) | Rastreio de M, X, DB e D, importação de trace, usage map e CDL, projeto em XML, saída para asar | Média |
| [DiztinGUIsh src] | DiztinGUIsh, código-fonte, commit 7484b87 (`Diz.Import/src/bizhawk/BizHawkCdlImporter.cs`, `Diz.Controllers/.../IControllers.cs`), issue 127 e PR 134. https://github.com/DizTools/DiztinGUIsh | IsoFrieze, DizTools e colaboradores | 2026 (09/08/2026) | Importadores existentes, formato e flags do CDL do BizHawk, pedidos de suporte ao Mesen | Alta |
| [Capstone] | Capstone 5.0.7: pacote `capstone` do PyPI e código (`cs.c`, `include/capstone/capstone.h`, `arch/MOS65XX/MOS65XXDisassembler.c`, `MOS65XXModule.c`). https://github.com/capstone-engine/capstone | equipe do Capstone | 2026 (consulta) | Modos 65816, tamanho do imediato, máscara de modos válidos, sintaxe com `$` | Alta |
| [sm_disassembly] | README, `info.txt`, `LICENSE.txt`, scripts de build e estrutura. https://github.com/InsaneFirebat/sm_disassembly | InsaneFirebat | 2026 (push em 05/10/2026) | Existência e organização da versão do Super Metroid que monta | Alta para a estrutura |
| [BizHawk src] | BizHawk, código-fonte, commit d148601 (`src/BizHawk.Emulation.Common/Base Implementations/CodeDataLog.cs`, `.../SNES/LibsnesCore.ICodeDataLogger.cs`, `.../SNES/LibsnesApi.cs`, `src/BizHawk.Client.EmuHawk/tools/CDL.cs`, `waterbox/libsnes/bsnes/base/base.hpp` e `.../snes/cpu/core/memory.hpp`). https://github.com/TASEmulators/BizHawk | TASEmulators e colaboradores | 2026 (10/11/2026) | Formato do arquivo CDL (cabeçalho, blocos, strings do .NET), flags do CDL de SNES e onde o M e o X são gravados, checagem de blocos ao carregar | Alta |
| [Teste local] | Execução própria: MesenCE 2.2.1 com `--testRunner` e Lua, Capstone 5.0.7 em Python 3.14, ROM LoROM de 32 KB original montada com asar 1.91, Windows 11 | este repositório | 2026 (02/11/2026) | Flags do CDL por byte, `emu.getCdlData` sem janela, saída do Capstone por modo, desmontagem guiada pelo CDL; em 11/11/2026 (#31), testes do conversor de CDL com ROM e CDL sintéticos em Python 3.14.7, o conversor rodado num CDL salvo pelo MesenCE e importado no DiztinGUIsh 2.5.1.0, e as condições do trace logger rodadas à mão na janela do MesenCE | Alta para essas versões |
| [ghidra-65816] | README do ghidra-65816 e do ghidra-snes-loader. https://github.com/achan1989/ghidra-65816 | achan1989 | sem manutenção | Configuração de flags e registradores, limitações declaradas | Média |
| [ghidra-snes] | README do ghidra-snes. https://github.com/joshleaves/ghidra-snes | joshleaves | 2026 (push em 28/05/2026) | Loader SNES, mapas e chips suportados, linguagem | Média |
| [SMWDisX] | README e estrutura do repositório. https://github.com/IsoFrieze/SMWDisX | IsoFrieze e colaboradores | 2026 (consulta) | Organização, regras de formato, versões, asar 1.91 | Alta para a estrutura |
| [jpdasm] | README e estrutura do repositório. https://github.com/spannerisms/jpdasm | spannerisms | 2026 (consulta) | Organização, extração de binários, hashes, convenções de label | Alta para a estrutura |
| [ebsrc] | README e estrutura do repositório. https://github.com/Herringway/ebsrc | Herringway e colaboradores | 2026 (consulta) | Organização, ebbinex, ca65 | Alta para a estrutura |
| [PJ bank logs] | Super Metroid bank logs. https://patrickjohnston.org/bank/ | Patrick Johnston (PJBoy) | 2026 (consulta) | Logs anotados por banco, mapas de RAM, VRAM e SRAM | Média |
| [pokered] | README e estrutura do repositório. https://github.com/pret/pokered | pret | 2026 (consulta) | Organização estilo pret, hashes, layout | Apoio (Game Boy) |
| [snesrev] | Repositórios zelda3, sm e smw. https://github.com/snesrev | snesrev | 2026 (consulta) | Reimplementações em C | Apoio |
| [Data Crystal TBL] | "Table file". https://datacrystal.tcrf.net/wiki/Table_file | comunidade Data Crystal | sem data | Formato .tbl, comentários, fim de texto e quebra de linha | Média |
| [PJBoy disasm] | https://github.com/PJBoy/snes-disassembler | PJBoy | sem data | Desmontador de linha de comando | Apoio |
| [disperry] | https://github.com/boldowa/disperry | boldowa | sem data | Front-end do Dispel | Apoio |
| [specter] | https://github.com/retroscribe/specter | retroscribe | sem data | Desmontador em Go | Apoio |
| [gilgamesh] | https://github.com/AndreaOrru/gilgamesh | Andrea Orru | sem data | Kit de engenharia reversa com recompilação estática | Apoio |

## Divergências registradas

| Ponto | O que cada fonte diz | O que vale e por quê |
|---|---|---|
| Documentação do Mesen | [Mesen docs] descreve a versão 0.9.9 (NES); [Mesen2 src] e [MesenCE src] têm outros menus e opções | **Código do MesenCE.** É a versão mantida; a documentação online não acompanha o Mesen 2 |
| Projeto ativo | [Mesen2 src] está arquivado; [MesenCE src] continua o desenvolvimento | Indicar o **MesenCE** e citar o Mesen 2 como origem; nomes de opção conferidos nos dois |
| Sintaxe de fim de texto no .tbl | [Data Crystal TBL] define marcadores para fim de texto e quebra; [MesenCE src] só aceita `HEX=texto` | As duas valem cada uma no seu contexto: escreva a tabela simples para o Mesen e use os marcadores só na ferramenta de tradução que os entende |
| Super Metroid reassemblável | [PJ bank logs] são documentação, não montam; a página aponta uma versão que monta, de InsaneFirebat [sm_disassembly] | Logs como documentação e [sm_disassembly] como a versão que monta (asar 1.81, teste byte a byte no próprio projeto); só a estrutura foi conferida, não o build |
| Modo 65816 de 8 bits no Capstone | `capstone.h` define `CS_MODE_MOS65XX_65816` (M e X de 8 bits); a máscara de `cs.c` não o aceita e a 5.0.7 recusa o modo [Capstone][Teste local] | **Vale o que roda:** o modo é recusado; usar `LONG_M` ou `LONG_X` conforme a instrução |
| Valores especiais da condição | [Mesen docs] lista valores de NES (`Sprite0Hit`, `Branched`, `PreviousOpPC`); [MesenCE src] lista os do SNES e acrescenta `#`, `0x`, `memaddress`, `isdma`, `isdummy` | **Código do MesenCE** para o SNES; a documentação antiga só confirma a base comum |

## Não confirmado ou fora do escopo

- Conversor do CDL do Mesen para o formato do BizHawk (`cdl_mesen_para_bizhawk.py`): escrito e testado com arquivos sintéticos e com uma cópia em Python do importador do DiztinGUIsh; falta abrir o arquivo gerado no DiztinGUIsh de verdade, que só tem interface gráfica.
- Condição do trace logger em execução: a sintaxe foi conferida no código e na ajuda embutida; o trace logger é só da interface e não tem função Lua, então nenhuma condição foi rodada.
- Desmontadores de linha de comando específicos de SNES (PJBoy, disperry, specter, gilgamesh): não rodados, sem compilador de C++ ou Go na máquina do teste e sem binário confiável.
- Build do [sm_disassembly]: exige a ROM comercial, fora do escopo.
- Nomes das chaves de `emu.getState()` para ler o PC dentro de callback.
- Descrição oficial da técnica de busca relativa para tabelas de texto.
- Desmontagens de MathOnNapkins (citadas, não abertas).
- no$sns como debugger (citado pelo [SNESdev Tools], não estudado aqui).
- Comparação prática entre as ferramentas: só o CDL do Mesen e o Capstone foram executados.
- Código ou dado de qualquer jogo comercial: fora do escopo por regra do repositório.
