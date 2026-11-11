# Comunidade

## SMW Central

Maior comunidade de ROM hacking de SNES, centrada em Super Mario World, e de onde vem o asar [asar]. O site ao vivo pede verificação humana; as regras abaixo vêm das páginas oficiais arquivadas no Internet Archive (datas em `fontes.md`) [SMWC].

Regras de envio de hack (seção Hacks):

- **Só BPS.** O envio é um ZIP com o patch BPS, mais créditos e README opcionais. Mais de um BPS que não seja versão alternativa é rejeitado na hora, e patch quebrado ou em formato inválido também, "incluindo patches IPS" [SMWC].
- **Tem que rodar na última versão estável do bsnes ou do Snes9x**, com a configuração padrão. Parte da moderação testa em console [SMWC].
- **Pelo menos três capturas de tela** tiradas de emulador, enviadas fora do ZIP [SMWC].
- **No máximo dois envios** esperando moderação por conta; o terceiro é removido [SMWC].
- **ROM nunca.** Subir ROM ou linkar site que distribui ROM comercial é contra as regras; o BPS só carrega a diferença e quem baixa aplica na própria ROM com o Floating IPS [SMWC][flips].

A fonte secundária [SMWC-2ª] dizia "BPS preferido"; a regra oficial é mais dura: IPS é recusado.

Convenções que nasceram lá e servem fora do SMW: RATS, `autoclean`, `freecode`/`freedata` [asar].

## romhacking.net

Arquivo histórico de hacks, traduções, utilitários e documentos de todas as plataformas. Fechou pra envios em 01/08/2024, por decisão do administrador (Nightcrawler); o site ficou só leitura e o banco de dados (sem contas de usuário) foi entregue ao Internet Archive [alternativeto][timeextension]. Bom pra documento antigo e ferramenta clássica; não espere atualização.

## Etiqueta de distribuição

- Distribua patch (BPS), nunca ROM [SMWC][flips].
- Diga qual é a ROM base (nome, região, revisão e hash) no README.
- Credite patches e ferramentas de terceiros usados e respeite a permissão de quem fez.

## Comunidade japonesa (改造)

No Japão, ROM hack de Super Famicom se chama 改造 ("modificação"). A busca de 11/11/2026 (termos e descartes em `fontes.md`) achou uma comunidade antiga, quase toda em wikis anônimas e blogs pessoais, e nenhum documento técnico novo em relação ao fullsnes e ao SNESdev. O que serve:

- **Hacks de RPG por "patch base" de expansão.** Os hacks de Dragon Quest se organizam em torno de um patch que só aumenta limites (mais itens, mais monstros, mais mensagens) sem mudar o jogo, e os outros hacks são feitos em cima dele. O autor do DQ6 Extended registra três lições: ampliar uma tabela de 8 pra 9 bits quebra a compatibilidade com o save original; um jogo que já usa quase toda a ROM tem pouco espaço livre, e é preciso reservar parte dele pra dado de tamanho variável (gráfico, mapa) e pra código; e, com a ROM maior, ele tirou a compressão Huffman do texto e gravou o texto sem compressão, trocando espaço por simplicidade [DQ6Ext].
- **O gargalo nem sempre é a ROM.** A página "ROM拡張" da DQバイナリ改造 @Wiki (anônima, 2006) lembra que aumentar o número de personagens registrados esbarra na WRAM (`$7E`), que precisa de espaço antes de qualquer expansão de ROM; e que, em HiROM, a SRAM aumentada continua no banco seguinte (`$30:6000-7FFF`, depois `$31:6000-7FFF`), não em endereço contínuo [DQwiki]. Isso bate com o mapa de 8 KB por banco do [bsnes] e do [fullsnes] (ver `mapeamento-e-expansao.md`).
- **A comunidade de Super Mario World aponta pro SMW Central.** A マリオ４改造 @wiki, wiki japonesa de SMW com páginas editadas até 2024, manda o iniciante pros tutoriais em inglês do SMW Central, que chama de mais atualizados, e usa as mesmas ferramentas (Lunar Magic, PIXI, GPS, UberASM) [SM4wiki]. Pra hack de SMW, a fonte de verdade continua sendo o SMW Central.

## Hacks grandes como referência

Projeto aberto serve de modelo de organização. Aqui só a documentação e a estrutura pública dos repositórios (pastas, scripts de build, arquivos de configuração e de mapa da ROM), sem código de jogo nem ROM. Lidos em 11/11/2026, exceto o z3randomizer (02/11/2026).

**z3randomizer** (base em asm do randomizador de A Link to the Past, licença MIT) [z3randomizer]:

- **Um arquivo por recurso** (`boots.asm`, `hud.asm`, `save.asm`...) e um arquivo raiz que inclui todos.
- **Hooks separados** num `hooks.asm`, longe da lógica nova: dá pra ver de uma vez tudo o que muda no código original.
- **Endereços em arquivo próprio:** `ram.asm`, `sram.asm`, `registers.asm` e `vanillalabels.asm` (rótulos do jogo original) concentram os números mágicos.
- **ROM fora do repositório:** o `build.sh` copia `../alttp.sfc` pra `../working.sfc` e roda o asar nessa cópia, o mesmo princípio de `fluxo-git-e-build.md`.

**Super Metroid Map Rando** (randomizador de mapa, licença MIT; o asm fica em `patches/`) [MapRando]:

- **Um patch por recurso, cada um virando um IPS próprio.** `patches/src/` tem mais de cem `.asm` (`fast_doors.asm`, `escape_timer.asm`, `credits.asm`...); `patches/ips/` guarda o resultado, e os patches sem fonte publicada ficam à parte em `ips/no source/`. O randomizador aplica só os IPS das opções escolhidas.
- **Build sem ROM:** o `python/scripts/build_patches.py` roda o asar com `--fix-checksum=off --no-title-check --ips <saida>.ips <patch>.asm dummy.smc`, ou seja, monta cada patch sobre um arquivo de mentira e fica só com o IPS.
- **Livro-razão do espaço livre.** `patches/rom_map/` tem um `Bank NN.txt` por banco, com cada faixa usada e o patch dono (`96B0 - 97C1: ; extended_msg_boxes.asm`) ou `[FREE]`; um `vanilla_hooks.txt` lista, banco por banco, cada trecho do código original sobrescrito; `RAM.txt` e `SRAM.txt` fazem o mesmo com a memória, com uma seção "expanded SRAM" separada do layout original. O `dump_rom_map.py` lê os IPS e regenera essas listas, e o build acusa conflito quando o IPS de um patch cai numa faixa que já é de outro.
- **Espaço livre com `org` e `warnpc`, não `freespace`.** Cada patch define início e fim da sua faixa (`!bank_80_freespace_start` / `_end`), começa com `org` nessa faixa e termina com `warnpc` no fim. Faz sentido porque os IPS são combinados em qualquer ordem, sem o asar enxergar a ROM final.
- **asar como submódulo** (um fork próprio), pra todo mundo montar com a mesma versão.

**VARIA Randomizer** (randomizador, solver e tracker de Super Metroid, licença MIT) [VARIA]:

- **Variantes do jogo em pastas irmãs:** `patches/common/`, `patches/vanilla/` e `patches/mirror/`, cada uma com `src/`, `ips/` e `sym/`. O que vale pra todas fica em `common`.
- **Make em vez de script solto:** o `tools/build.mk` transforma cada `src/*.asm` em `ips/*.ips` com `--fix-checksum=off --no-title-check --symbols=wla`, gera as dependências entre arquivos incluídos e só remonta o que mudou.
- **Símbolos pra três usos:** do `.sym` do asar saem um JSON (pro randomizador em Python achar endereços), um `.asm` de símbolos (pra um patch usar rótulo de outro) e um arquivo de rótulos do Mesen (`.msl` e `.mlb`) pra depurar com nomes.
- **Checagem de sobreposição:** `make check` roda o `tools/ips_check.py` sobre todos os IPS de cada variante e acusa faixa escrita por dois patches; patches que sobrescrevem de propósito ficam numa lista de exceção (`IPS_CHECK_FILTER`).
- **Refatoração registrada em texto:** `doc/base_asm_refactor.txt` anota dependências circulares entre patches e o plano pra quebrá-las (boot e save num `base.asm`, rotinas comuns num `utils.asm`, opções em defines num include comum).

**Super Metroid Practice Hack** (licença Unlicense) [SMPractice]:

- **Versão do asar fixada** no README (1.81) e na primeira linha do `main.asm` (`asar 1.81`).
- **Variantes por define na linha de comando:** o mesmo `main.asm` monta três patches (`-DFEATURE_SD2SNES=1`, `-DFEATURE_TINYSTATES=1` ou nenhum dos dois), e o `main.asm` declara cada opção com `?=` e um valor padrão. O README diz qual variante serve pra qual alvo (FXPAK, EverDrive e emulador, Virtual Console).
- **Código gerado antes do asar:** scripts em Python transformam listas de texto (nomes de sala, layout) em `.asm` dentro de `src/`.
- **Espaço livre por banco com macros:** `src/freespace.asm` define o início e o fim da área livre de cada banco (uma área por banco, com comentário do porquê de cada limite). As macros `%startfree(80)` e `%endfree(80)` abrem e fecham a área, guardam onde o próximo arquivo continua, conferem com `assert` que ninguém esqueceu de fechar nem fechou o banco errado e fazem `warnpc` no limite; `%printfreespace()` imprime o uso de cada banco no fim do build.
- **IPS sem a ROM, com dois arquivos de mentira:** o build monta o mesmo código sobre um arquivo de 4 MB só de `$00` e outro só de `$FF`, e o `resources/create_ips.py` grava no IPS só os bytes iguais nos dois, que são os que o asar escreveu. Detalhe e ressalvas em `fluxo-git-e-build.md`.

**ALTTP + Super Metroid Combo Randomizer** (mudanças na ROM do randomizador que junta os dois jogos, licença MIT) [SMZ3]:

- **Dois jogos numa ROM ExHiROM:** o `src/main.asm` começa com `exhirom` e inclui `z3/`, `sm/` e o que é comum (`common.asm`, `sram.asm`, `credits.asm`) a partir de pastas separadas, um `incsrc` por linha com comentário do que cada um faz.
- **Mapa da ROM escrito à mão:** o `banks.txt` diz, banco por banco, o que é de cada jogo, onde estão os espelhos, o que é código novo (com a faixa exata) e o que ainda está livre. É o papel do `rom_map/` do Map Rando, sem gerador.
- **Mesmo truque do Practice Hack:** o `build.sh` monta sobre os arquivos de `$00` e de `$FF` e gera um único `zsm.ips`.

**O que se repete nos cinco:**

- Um `.asm` por recurso, um arquivo raiz que inclui todos, e hooks, RAM e SRAM em arquivos separados da lógica.
- Mapa do espaço usado mantido no repositório (gerado ou à mão), com o dono de cada faixa. Com muitos patches, é o que evita dois patches no mesmo byte.
- Espaço livre decidido por quem conhece a ROM (faixa fixa por banco, fechada com `warnpc` ou `assert`), não pela busca do `freespace`. O `freespace` com RATS continua sendo o padrão do SMW Central, onde patches de autores diferentes precisam conviver na mesma ROM [asar][SMWC].
- Versão do asar fixada (submódulo ou `asar 1.81` no código).
- Símbolos (`--symbols=wla`) gerados em todo build, pra depurar no emulador.
- ROM nunca no repositório; o que sai é patch.

Atenção ao formato: os quatro projetos de Super Metroid e de A Link to the Past distribuem IPS, porque os patches são aplicados por programa próprio ou sobre uma ROM conhecida. Pra hack distribuído ao público, o SMW Central recusa IPS e a regra desta skill continua sendo BPS [SMWC][flips].
