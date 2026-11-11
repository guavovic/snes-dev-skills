# Fontes da skill snes-rom-hack

Pesquisa feita em 26/10/2026, revisada em 02/11/2026 (issue #13) e ampliada em 11/11/2026 com fontes em japonês e mais hacks grandes (issue #29). Cada fato técnico foi conferido em duas fontes da lista quando havia; o que não deu está marcado "não confirmado" no texto.

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
| [MapRando] | Documentação e estrutura de https://github.com/blkerby/MapRandomizer (licença MIT, commit d04f606 de 06/11/2026): `README.md`, `patches/README.md`, `patches/rom_map/` (README, `Bank NN.txt`, `vanilla_hooks.txt`, `SRAM.txt`), `python/scripts/build_patches.py` e `dump_rom_map.py`, e as diretivas `org`/`warnpc` de três patches; acesso em 11/11/2026 | maddo, kyleb e colaboradores | Um IPS por patch montado sem ROM, mapa de espaço livre por banco com dono de cada faixa, checagem de conflito, asar como submódulo | Média: só estrutura, scripts de build e diretivas, sem ler código de jogo |
| [VARIA] | Documentação e estrutura de https://github.com/theonlydude/RandomMetroidSolver (licença MIT, commit 5ce97e1 de 05/08/2026): `README.md`, `patches/Makefile`, `tools/build.mk`, `tools/ips_check.py`, `doc/base_asm_refactor.txt`; acesso em 11/11/2026 | theonlydude e colaboradores | Variantes em pastas irmãs, build com make, símbolos pra JSON, asm e Mesen, checagem de sobreposição de IPS | Média: só estrutura e build |
| [SMPractice] | Documentação e estrutura de https://github.com/tewtal/sm_practice_hack (Unlicense, commit e67f52f de 17/10/2026): `README.md`, `build.sh`, `resources/create_ips.py`, `resources/create_dummies.py`, cabeçalho de `src/main.asm` e `src/freespace.asm` (só as macros e os limites); acesso em 11/11/2026 | tewtal e colaboradores | Versão do asar fixada, variantes por define, espaço livre por banco com macros e `assert`, IPS gerado de dois arquivos de `$00` e `$FF` | Média: só estrutura, build e macros de espaço livre |
| [SMZ3] | Documentação e estrutura de https://github.com/tewtal/alttp_sm_combo_randomizer_rom (licença MIT, commit 5f9eaf6 de 11/11/2024): `banks.txt`, `build.sh`, lista de `incsrc` do `src/main.asm`; acesso em 11/11/2026 | tewtal e colaboradores | Dois jogos numa ROM ExHiROM, mapa da ROM escrito à mão, mesmo método de IPS do [SMPractice] | Média: só estrutura e build |
| [DQ6Ext] | "DQ6 Extended(拡張ベースパッチ)作成にあたっての考慮点" (https://retrogamehackers.net/dq6-extended-001/, 20/05/2015, revisto em 13/06/2015) e parte 2 (https://retrogamehackers.net/dq6-extended-002/, 12/06/2015), em japonês; acesso em 11/11/2026 | dq_492 (Retro Game Hackers) | Patch base de expansão, save incompatível ao ampliar tabela, pouco espaço livre, texto descomprimido na ROM maior | Média-baixa: relato pessoal de um autor de hack, sem fonte técnica; usado só como experiência de organização |
| [DQwiki] | Página "ROM拡張" da DQバイナリ改造 @Wiki, https://w.atwiki.jp/dq_binary/pages/20.html (última edição 01/07/2006, anônima), em japonês; acesso em 11/11/2026 | anônimo | Passos de expansão HiROM e ExHiROM, SRAM de HiROM crescendo de banco em banco, WRAM como gargalo | Baixa-média: anônima e antiga; só o que bate com [bsnes] e [fullsnes] foi usado |
| [SM4wiki] | マリオ４改造 @wiki, páginas "Lunar Magic" (https://w.atwiki.jp/sm4wiki_mix/pages/16.html, editada em 25/09/2023), "用語集" (pages/30.html, 11/08/2024) e "使い方" (pages/39.html, 25/05/2024), em japonês; acesso em 11/11/2026 | anônimos | Ferramentas usadas na comunidade japonesa de SMW e a indicação dos tutoriais do SMW Central como mais atuais | Baixa-média: usada só pra descrever a comunidade |
| [RGLab] | "スーパーファミコンのLoROMイメージのHiROMイメージ化について", https://www.retrogamelaboratory.com/2024/06/loromhirom.html (01/06/2024), em japonês; acesso em 11/11/2026 | 井上ジャンゴ (Retro Game Laboratory) | Conversão de LoROM em HiROM intercalando 32 KB vazios e mudando `$FFD5` | Baixa: testado só em emulador não identificado, um caso falhou e o relato da SRAM não bate com o mapa HiROM; entra marcado "não confirmado" |
| [Teste local] | asar 1.91 e MesenCE 2.2.1 (`--testRunner`), ROM base própria de bytes zerados, 02/11/2026 | esta pesquisa | Projeto mínimo montado e rodado, autoexpansão, checksum de tamanhos irregulares por quatro métodos, espelho de ROM no Mesen; em 03/11/2026, define com conta montado com e sem `asar 1.90` | Alta pro que foi rodado |

## Não consultadas

- Site ao vivo do SMW Central: responde 403 com verificação humana; as regras vêm das cópias do Internet Archive em [SMWC]. Regra mudada depois da última captura não está aqui.
- Fontes em japonês sobre ROM hacking de Super Famicom (改造): duas rodadas de busca (26/10 e 02/11/2026) só devolveram páginas em inglês. A terceira, em 11/11/2026, está na seção "Busca em japonês" abaixo.
- Super EverDrive: firmware fechado e manual sem mapa de ExLoROM nem limite de SRAM; não confirmado.
- Teste em hardware real (FXPAK, EverDrive, cartucho): não feito; o que está escrito do FXPAK é leitura do código [sd2snes].
- flips: o download do binário foi barrado nesta rodada, então o passo de gerar o `.bps` do build de exemplo não foi rodado.
- Hacks grandes: lidas a documentação e a estrutura do [z3randomizer], [MapRando], [VARIA], [SMPractice] e [SMZ3], sem código de jogo. Nenhum deles foi montado nem rodado aqui (seria preciso baixar o asar de cada um e a ROM original); o método de IPS com dois arquivos de mentira está descrito pela leitura dos scripts, e as ressalvas em `fluxo-git-e-build.md` são dedução, sem teste.
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
| SRAM de LoROM convertida em HiROM | [RGLab]: a SRAM funcionou depois da conversão | [bsnes], [fullsnes]: SRAM de HiROM fica em `$20-$3F:6000-7FFF`, não em `$70` | Não confirmado; pelo mapa, o código que acessa a SRAM precisaria mudar |
| SRAM do ExLoROM | Memorando do blog boldowa's nest (ver "Busca em japonês"): `$B0:6000-$BF:FFFF` | [bsnes]: SRAM como LoROM | [bsnes]; o memorando foi descartado |

## Busca em japonês (11/11/2026)

Termos usados, com e sem restrição a domínios japoneses (atwiki, hatena, qiita, zenn, fc2, seesaa, note, github.io): `スーファミ 改造 ROM拡張 LoROM SRAM`; `SMW 改造 ROM 拡張 Lunar Magic wiki`; `SMW改造 asar 使い方 freespace RATS`; `SFC ハック SRAM 拡張 パッチ セーブ`; `Lunar Expand 使い方 ROM容量 拡張 4MB ExLoROM`; `スーパーファミコン ROMハック 拡張 ヘッダ チェックサム 65816 アセンブラ`; `"ROM拡張" SFC 改造 FF6 OR DQ6 OR DQ5 バンク 空き領域`; `スーパーマリオワールド 改造 wiki 拡張 ROM Lunar Magic 日本語 解説 SA-1`; `retrogamehackers ExHiROM`.

Resultado: a comunidade japonesa de 改造 de Super Famicom vive em wikis anônimas e blogs pessoais, a maioria com mais de dez anos. Nada trouxe regra técnica nova em relação a [fullsnes], [SNESdev] e [bsnes]. Entraram [DQ6Ext], [DQwiki], [SM4wiki] e [RGLab] (tabela acima), pelo que acrescentam de experiência e de comunidade.

Lidas e não usadas como fonte:

- "SNES逆汗解析･改造入門" (autor 546, cópia em https://wiki.superfamicom.org/snes-%E9%80%86%E6%B1%97%E8%A7%A3%E6%9E%90-%E6%94%B9%E9%80%A0%E5%85%A5%E9%96%80, sem data, incompleto): a fórmula de LoROM bate com a do [asar]; as ferramentas citadas (Geiger's Snes9x Debugger, TRaCER) são antigas; e escolhe espaço livre por "trecho cheio de vazio", o que a regra 2 de `espaco-livre-e-hooks.md` não aceita como prova.
- 改造ドンキーの館, "SNES技術資料 メモリマッピング" (https://donkeyhacks.zouri.jp/html/Ja-jp/snes/memmap.html, Karaage, 2011-2017): confirma os mapas de SRAM de LoROM e HiROM, sem nada novo.

Descartadas:

- Memorando sobre cartuchos do blog boldowa's nest (https://boldowa.github.io/snes/2018/06/06/snescartridge, 06/06/2018): o próprio autor diz que é informal e pode ter erro, e o mapa de SRAM do ExLoROM diverge do [bsnes].
- Página "ゲーム解析講座" da DQバイナリ改造 @Wiki (pages/43.html): respondeu 403.
- Manual em japonês do Lunar Expand: não encontrado.
- Tópicos do SMW Central que apareceram na busca: em inglês, já cobertos por [SMWC].
- Material de análise de SPC (som): fora do escopo desta skill.
