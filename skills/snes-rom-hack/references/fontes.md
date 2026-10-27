# Fontes da skill snes-rom-hack

Pesquisa feita em 26/10/2026. Cada fato técnico foi conferido em duas fontes da lista quando havia; o que não deu está marcado "não confirmado" no texto.

| Nome | Fonte | Autor / ano | Cobre | Confiança |
|---|---|---|---|---|
| [fullsnes] | nocash SNES hardware specifications, https://problemkaputt.de/fullsnes.txt | Martin Korth (nocash) | Cabeçalho interno e estendido, vetores, checksum, cabeçalhos de copiador (SWC, FIG, NSRT), mapas LoROM/HiROM, placas e SRAM, JSL/RTL, efeito de X em 8 bits | Alta |
| [SNESdev] | SNESdev wiki: "ROM header", "ROM file formats", "LoROM", "HiROM", "Memory map", https://snes.nesdev.org/wiki/ | comunidade nesdev | Campos do cabeçalho, detecção de mapeamento, checksum de tamanho não potência de 2, cabeçalho de copiador, LoROM até 4 MB, ExHiROM | Alta |
| [asar] | Manual 1.9 (https://rpghacker.github.io/asar/asar_19/manual/), manual 2.0 beta (https://rpghacker.github.io/asar/asar_2_beta/) e código `src/asar/libsmw.cpp`, `main.cpp`, `interface-cli.cpp`, `assembleblock.cpp`, https://github.com/RPGHacker/asar | RPGHacker e colaboradores | Diretivas, freespace e RATS, autoexpansão, `snestopc`, detecção de mapper, checksum | Alta (manual conferido contra o código) |
| [bsnes] | `bsnes/heuristics/super-famicom.cpp` e `bsnes/target-bsnes/resource/system/boards.bml`, https://github.com/bsnes-emu/bsnes | byuu (Near) e mantenedores | Pontuação de cabeçalho, detecção de copiador, placas LoROM/HiROM/ExLoROM/ExHiROM, tamanho de SRAM | Alta (emulador de alta precisão) |
| [flips] | README e `flips.cpp`, `libips.cpp`, `libbps.cpp`, https://github.com/Alcaro/Flips | Alcaro | Linha de comando, IPS (limite, EOF), BPS, remoção de cabeçalho SMC | Alta |
| [BPS] | Especificação BPS de byuu, cópia em https://github.com/blakesmith/rombp/blob/master/docs/bps_spec.md | byuu (Near); cópia de terceiros | Formato BPS, varint, comandos, CRC32 | Média-alta: é cópia, conferida contra `libbps.cpp` |
| [sneslab] | SNESLab wiki: JSL, RTL, JML, IPS file format, Checksum, https://sneslab.net/wiki/ | comunidade | Opcodes e bytes de JSL/RTL/JML, formato IPS e extensão de truncar | Média-alta (bate com [fullsnes] e [flips]) |
| [Epilogue] | https://www.epilogue.co/support/hardware/snes-cartridges | Epilogue | Mapeamentos suportados pelo SN Operator (não lista ExLoROM) | Média: só o ponto citado |
| [alternativeto] | https://www.alternativeto.net/news/2024/8/romhacking-net-shuts-down-after-20-years-database-has-been-moved-to-the-internet-archive/ | AlternativeTo, 08/2024 | Fechamento do romhacking.net e ida do banco pro Internet Archive | Média (notícia) |
| [timeextension] | https://www.timeextension.com/news/2024/08/romhacking-net-is-winding-down-after-almost-20-years | Time Extension, 08/2024 | Mesmo assunto, data de 01/08/2024 | Média (notícia) |
| [SMWC-2ª] | https://battleofthebits.com/lyceum/View/smw | Battle of the Bits | No SMW Central se envia patch e não ROM, BPS preferido | Baixa-média: fonte secundária |

## Não consultadas

- Página oficial de regras de envio do SMW Central: não lida; o fato de distribuição vem de [SMWC-2ª].
- Fontes em japonês sobre ROM hacking de Super Famicom: a busca só devolveu páginas em inglês; nenhuma fonte japonesa confiável lida.
- Documentação de práticas de hacks grandes específicos: não encontrada nesta rodada.
- Manuais de flash carts além do [Epilogue] (FXPak, Everdrive): não lidos; suporte a ExLoROM e SRAM fora do padrão fica não confirmado.
- Detalhe de instrução e ciclos: delegado à skill `snes-assembly`; mapa de memória e registradores: `snes-hardware`.

## Divergências registradas

| Assunto | Diz A | Diz B | Vale |
|---|---|---|---|
| Detecção do cabeçalho de copiador | [fullsnes], [SNESdev]: `tamanho mod 1024 = 512` | [bsnes]: `tamanho & $7FFF = 512` | `mod 1024`, que cobre ROM de tamanho múltiplo de 1 KB; em dump real as duas batem |
| Tamanho máximo de LoROM | [fullsnes] (resumo): 2 MB, acima disso é "BigLoROM" | [SNESdev], [bsnes] (placa LOROM): 4 MB | 4 MB, com SRAM só nos 32 KB de baixo acima de 3 MB ([fullsnes] confirma essa condição) |
| Ciclos do JSL | [fullsnes]: 4 | [sneslab]: 8 | Não citado aqui; ver `snes-assembly` |
| Map mode do ExLoROM | Ferramentas e flash carts tratam como mapeamento à parte | [bsnes]: não oficial, sem valor de map mode | Não oficial; testar no alvo |
