# Fontes da skill snes-desmontagem

Consultadas em 26/10/2026. Nível de confiança: **alta** = código-fonte ou documentação do próprio projeto; **média** = README ou wiki sem conferência no código; **apoio** = só para contexto ou desempate. Nenhum executável foi rodado: o que vem de código foi lido, não testado.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [MesenCE src] | MesenCE, código-fonte, commit 4b8a196. https://github.com/nesdev-org/MesenCE | nesdev-org (fork comunitário do Mesen 2) | 2026 (07/10/2026) | CDL (flags, formato, Generate ROM), trace logger, Memory Search, breakpoints e opções de parada, import e export de labels (.mlb, .sym, .dbg), loader de .tbl, API Lua | Alta |
| [Mesen2 src] | Mesen 2, código-fonte (repositório arquivado). https://github.com/SourMesen/Mesen2 | Sour | 2025 | Mesmas áreas; usado para confirmar que o fork mantém os nomes | Alta |
| [Mesen docs] | Documentação do Mesen. https://www.mesen.ca/docs/ | Sour | sem data (versão 0.9.9, NES) | Sintaxe de condição do trace logger e dos breakpoints | Apoio: é de outra versão |
| [SNESdev Tools] | SNESdev wiki, página "Tools". https://snes.nesdev.org/wiki/Tools | comunidade nesdev | 2026 (consulta) | Avaliação dos emuladores e debuggers | Média |
| [bsnes-plus] | README do bsnes-plus. https://github.com/devinacker/bsnes-plus | devinacker e colaboradores | 2025 (push em 22/03/2025) | Destaque de código e dado, breakpoints espelhados, SA-1 e SuperFX, formatos de símbolos, trace mask | Média |
| [DiztinGUIsh] | README do DiztinGUIsh. https://github.com/IsoFrieze/DiztinGUIsh | IsoFrieze e colaboradores | 2026 (consulta) | Rastreio de M, X, DB e D, importação de trace, usage map e CDL, projeto em XML, saída para asar | Média |
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
| Super Metroid reassemblável | [PJ bank logs] são documentação, não montam; a página aponta uma versão reassemblável de outro autor | Tratar os logs como documentação; a versão reassemblável **não foi conferida** |

## Não confirmado ou fora do escopo

- Importação direta do CDL do Mesen no DiztinGUIsh: o README lista CDL do BizHawk e usage map do BSNES, não o do Mesen.
- Sintaxe exata das condições do trace logger no Mesen 2 (conferido só que o campo existe).
- Nomes das chaves de `emu.getState()` para ler o PC dentro de callback.
- Descrição oficial da técnica de busca relativa para tabelas de texto.
- Versão reassemblável do Super Metroid e as desmontagens de MathOnNapkins (citadas, não abertas).
- no$sns como debugger (citado pelo [SNESdev Tools], não estudado aqui).
- Comparação prática entre as ferramentas: nada foi executado.
- Código ou dado de qualquer jogo comercial: fora do escopo por regra do repositório.
