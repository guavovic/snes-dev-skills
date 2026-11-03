# Fontes da skill snes-rom-hack

Pesquisa feita em 26/10/2026 e revisada em 02/11/2026 (issue #13). Cada fato técnico foi conferido em duas fontes da lista quando havia; o que não deu está marcado "não confirmado" no texto.

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
| [SMWC-2ª] | https://battleofthebits.com/lyceum/View/smw | Battle of the Bits | No SMW Central se envia patch e não ROM, BPS preferido | Baixa-média: fonte secundária, superada por [SMWC] |
| [SMWC] | Páginas oficiais lidas pelo Internet Archive, porque o site ao vivo pede verificação humana: "Submission Guidelines: All Hacks" (captura de 25/07/2025, https://web.archive.org/web/20250725214811/https://www.smwcentral.net/?p=guidelines&page=1633980-all-hacks), FAQ "BPS Files" (captura de 24/12/2025, https://web.archive.org/web/20251224111131/https://www.smwcentral.net/?p=faq&page=1219815-bps-files) e FAQ "ROM Files and Emulators" (captura de 10/02/2026, https://web.archive.org/web/20260210080804/https://www.smwcentral.net/?p=faq&page=1219813-rom-files-and-emulators) | SMW Central | Regras de envio de hack: um BPS por envio, IPS rejeitado, teste no bsnes e no Snes9x, ZIP, capturas de tela; proibição de ROM | Alta (página oficial, cópia arquivada) |
| [MesenCE] | `Core/SNES/BaseCartridge.cpp`, commit 4b8a196 (07/10/2026), https://github.com/nesdev-org/MesenCE | Sour e colaboradores | Pontuação de cabeçalho, ExLoROM, espelho de ROM de tamanho irregular, tamanho e mapa da SRAM | Alta (código lido e conferido em teste) |
| [snes9x] | `memmap.cpp`, commit 1bcc369, https://github.com/snes9xgit/snes9x | equipe do Snes9x | Checksum espelhado recursivo, mapa ExLoROM (`Map_JumboLoROMMap`), buffer e mapa da SRAM | Alta |
| [sd2snes] | Firmware `src/smc.c` e FPGA `verilog/sd2snes_base/address.v`, commit b081ff9 (01/11/2026), https://github.com/mrehkopf/sd2snes | ikari_01 (mrehkopf) | Como o FXPAK/sd2snes detecta o mapeamento, mapeia ExLoROM e dimensiona a SRAM | Alta pro que o código faz; sem teste em hardware |
| [LunarExpand] | Lunar Expand 1.20, https://fusoya.eludevisibility.org/le/ | FuSoYa, atualizado em 01/07/2022 | Suporte a ExLoROM por versão do Snes9x e do ZSNES | Média-alta (autor da ferramenta de expansão mais usada) |
| [z3randomizer] | Estrutura pública do repositório, https://github.com/KatDevsGames/z3randomizer (licença MIT, último commit em 30/11/2025) | KatDevsGames e colaboradores | Exemplo de hack grande organizado em asar: um arquivo por recurso, hooks e RAM em arquivos próprios, ROM base fora do repositório | Média: só a estrutura e o script de build, sem ler código de jogo |
| [Teste local] | asar 1.91 e MesenCE 2.2.1 (`--testRunner`), ROM base própria de bytes zerados, 02/11/2026 | esta pesquisa | Projeto mínimo montado e rodado, autoexpansão, checksum de tamanhos irregulares por quatro métodos, espelho de ROM no Mesen; em 03/11/2026, define com conta montado com e sem `asar 1.90` | Alta pro que foi rodado |

## Não consultadas

- Site ao vivo do SMW Central: responde 403 com verificação humana; as regras vêm das cópias do Internet Archive em [SMWC]. Regra mudada depois da última captura não está aqui.
- Fontes em japonês sobre ROM hacking de Super Famicom (改造): duas rodadas de busca (26/10 e 02/11/2026), em japonês, só devolveram páginas em inglês. Fica pra issue #29.
- Super EverDrive: firmware fechado e manual sem mapa de ExLoROM nem limite de SRAM; não confirmado.
- Teste em hardware real (FXPAK, EverDrive, cartucho): não feito; o que está escrito do FXPAK é leitura do código [sd2snes].
- flips: o download do binário foi barrado nesta rodada, então o passo de gerar o `.bps` do build de exemplo não foi rodado.
- Hacks grandes: só a estrutura do [z3randomizer] foi lida. Super Metroid Map Rando, VARIA e outros não foram lidos.
- Detalhe de instrução e ciclos: delegado à skill `snes-assembly`; mapa de memória e registradores: `snes-hardware`.

## Divergências registradas

| Assunto | Diz A | Diz B | Vale |
|---|---|---|---|
| Detecção do cabeçalho de copiador | [fullsnes], [SNESdev]: `tamanho mod 1024 = 512` | [bsnes]: `tamanho & $7FFF = 512` | `mod 1024`, que cobre ROM de tamanho múltiplo de 1 KB; em dump real as duas batem |
| Tamanho máximo de LoROM | [fullsnes] (resumo): 2 MB, acima disso é "BigLoROM" | [SNESdev], [bsnes] (placa LOROM): 4 MB | 4 MB, com SRAM só nos 32 KB de baixo acima de 3 MB ([fullsnes] confirma essa condição) |
| Ciclos do JSL | [fullsnes]: 4 | [sneslab]: 8 | Não citado aqui; ver `snes-assembly` |
| Map mode do ExLoROM | Ferramentas e flash carts tratam como mapeamento à parte | [bsnes]: não oficial, sem valor de map mode | Não oficial; testar no alvo |
| Checksum de tamanho que não é soma de duas potências de 2 (ex.: 1344 KB, 1792 KB) | [asar]: primeira parte + resto repetido `primeira / resto` vezes (arredonda pra baixo) | [snes9x]: espelho recursivo herdado do NSRT; [SNESdev]: resto completado com zeros até a próxima potência de 2 | Nenhum; os três dão valores diferentes [Teste local]. Mesen e bsnes não recalculam, então não reclamam. Use tamanho regular |
| Snes9x e ExLoROM de 64 Mbit | [snes9x] atual: mapa ExLoROM completo | [LunarExpand]: 1.50 a 1.53 limitam a 48 Mbit | Versão atual roda; versão antiga pode não rodar |
