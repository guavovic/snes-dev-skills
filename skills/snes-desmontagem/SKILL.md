---
name: snes-desmontagem
description: Desmontagem e engenharia reversa de ROM de Super Nintendo (SNES / Super Famicom) para entender o código e preparar um hack. Use quando a tarefa envolver separar código de dado (trace log, Code/Data Logger do Mesen, arquivo CDL, usage map), escolher ferramenta (debugger do Mesen 2 / MesenCE, bsnes-plus, DiztinGUIsh, Ghidra com plugin 65816, desmontador de linha de comando), acompanhar o estado das flags M e X do 65816 durante a desmontagem, achar uma variável na RAM (busca por valor, breakpoint de escrita, quem lê e quem escreve), dar nome a rotina, tabela de ponteiros, jump table e tabela de caracteres de texto (arquivo .tbl), importar ou exportar labels (.mlb, .sym), documentar mapa de RAM e de ROM ou organizar um projeto de desmontagem byte a byte (no estilo das desmontagens de Super Mario World, Zelda: A Link to the Past, Super Metroid, EarthBound e dos projetos pret). Também serve para perguntas como "onde fica a vida do jogador na RAM", "por que o desmontador mostrou lixo depois desse REP", "como acho quem escreve nesse endereço", "como monto uma tabela de texto" ou "como organizo o repositório da desmontagem".
---

# snes-desmontagem

Como transformar bytes de uma ROM em código entendido e nomeado. Este arquivo traz o fluxo, as regras que mais poupam retrabalho e o índice; o detalhe de cada ferramenta e técnica fica em `references/`. Aqui só entram organização e técnica: nenhum trecho de jogo comercial é reproduzido.

## Fluxo em quatro passos

1. **Rodar e registrar.** Jogue a parte que interessa com o Code/Data Logger do Mesen ligado (ou o usage map do bsnes-plus). O que executou vira código, o que foi lido vira dado, e no SNES o Mesen ainda grava o estado de M e X de cada byte executado [MesenCE src]. Ver `references/codigo-e-dados.md`.
2. **Achar o ponto de entrada.** Busca de valor na RAM, breakpoint de escrita, trace log em volta do momento certo [MesenCE src][bsnes-plus]. Ver `references/variaveis-e-tabelas.md`.
3. **Desmontar com estado.** Importe o CDL ou o trace num desmontador que acompanha M, X, DB e D (DiztinGUIsh faz isso) [DiztinGUIsh]. Ver `references/ferramentas.md`.
4. **Nomear e documentar.** Labels de RAM e ROM num arquivo que volta pro debugger (.mlb, .sym), mapa de RAM em texto, tabela de caracteres em .tbl [MesenCE src][Data Crystal TBL]. Ver `references/organizacao-de-projetos.md`.

## Regras de ouro

1. **Execução manda, desmontagem estática chuta.** Sem saber o estado de M e X, o mesmo byte vira instrução de 2 ou 3 bytes, e o resto da rotina sai torto. Prefira o que o CDL ou o trace registrou ao que o desmontador deduziu [MesenCE src][DiztinGUIsh]. Por que isso acontece: `snes-assembly`, `references/armadilhas.md`.
2. **Cobertura é do que você jogou.** O CDL só marca o que rodou ou foi lido na sessão. Byte sem marca não é "livre", é "não visto" [MesenCE src]. Para achar espaço livre de verdade, ver `snes-rom-hack`, `references/espaco-livre-e-hooks.md`.
3. **Um endereço, um nome, um lugar.** Guarde labels num arquivo versionado e importável (o Mesen aceita .mlb, .sym, .dbg e outros) em vez de anotar no debugger e perder [MesenCE src].
4. **Endereço de RAM no Mesen é offset do tipo de memória.** Num label `SnesWorkRam:0100:...` o número é o offset dentro da WRAM, não o endereço de barramento $7E0100 [MesenCE src].
5. **Ache a variável pelo efeito, depois pela causa.** Primeiro a busca por valor reduz a lista; depois o breakpoint de escrita mostra a rotina que muda o valor [MesenCE src][bsnes-plus].
6. **Nada de ROM nem de binário do jogo no repositório.** Projetos byte a byte sérios extraem os binários da ROM do próprio usuário e conferem por hash [jpdasm][ebsrc][pokered]. A mesma regra vale para hack: `snes-rom-hack`.
7. **Byte a byte ou não é desmontagem.** O objetivo de um projeto reassemblável é gerar uma ROM idêntica à original, conferida por checksum. Qualquer diferença indica instrução mal decodificada ou dado tratado como código [SMWDisX][jpdasm].

## Armadilhas

- **Dado no meio do código.** Tabela logo depois de um `RTS`, ponteiro em linha depois de um `JSR` e bytes que só um caminho raro executa enganam a desmontagem linear. Confie nas marcas do CDL e marque o resto como dado à mão [DiztinGUIsh][MesenCE src].
- **M/X depois de PLP e RTI.** O plugin 65816 do Ghidra não atualiza o modo depois de `PLP` ou `RTI` e pede que você ajuste as flags à mão [ghidra-65816]. Outras ferramentas também podem errar aqui: confira com o trace.
- **Banco de dados (DB) e direct page.** Endereço absoluto de 16 bits depende do DB, e acesso em direct page depende do D. O DiztinGUIsh guarda os dois por instrução; sem isso o label aponta pro lugar errado [DiztinGUIsh].
- **Jump table indexada.** `JMP (abs,X)` e `JSR (abs,X)` pulam pra endereços que nenhum desmontador linear segue. Marque a tabela como ponteiros e crie labels em cada destino. Ver `references/variaveis-e-tabelas.md`.
- **CDL de outra versão da ROM.** O arquivo CDL do Mesen guarda o CRC32 da ROM; arquivo sem CRC (formato antigo) carrega só com aviso [MesenCE src]. Revisão diferente do jogo muda endereços.
- **Leitura que tem efeito colateral.** Ler registrador de hardware num script ou janela de memória pode mudar o estado. No Lua do Mesen, os tipos `*Debug` (por exemplo `emu.memType.snesDebug`) leem sem efeito colateral [MesenCE src].
- **Tabela .tbl com código de controle.** Cada ferramenta escreve códigos de controle de um jeito; o Mesen só carrega entradas simples `HEX=texto` [Data Crystal TBL][MesenCE src].

## Índice de referências

| Arquivo | O que tem |
|---|---|
| `references/ferramentas.md` | Mesen 2 / MesenCE, bsnes-plus, DiztinGUIsh, Ghidra (ghidra-65816, ghidra-snes), desmontadores de linha de comando: o que cada um faz bem e seus limites |
| `references/codigo-e-dados.md` | CDL do Mesen (flags, formato do arquivo, Generate ROM), trace logger e formato, usage map do bsnes-plus, como acompanhar M e X |
| `references/variaveis-e-tabelas.md` | Busca de valor na RAM, breakpoints de leitura e escrita, contadores de acesso, callback de memória em Lua, tabelas de ponteiros, jump tables, tabelas de texto .tbl |
| `references/organizacao-de-projetos.md` | Labels (.mlb, .sym), mapa de RAM e de ROM, como se organizam as desmontagens de SMW, ALttP, Super Metroid, EarthBound e o estilo pret |
| `references/fontes.md` | Fontes, confiança, divergências e o que não foi confirmado |

## Relação com outras skills

- `snes-assembly`: instruções, M/X, REP/SEP, modos de endereçamento. Esta skill assume que você já lê 65816.
- `snes-hardware`: mapa de memória (LoROM, HiROM, WRAM), registradores `$21xx` e `$42xx`, para dar nome a acessos de hardware.
- `snes-rom-hack`: depois de entender a rotina, como escrever o hook, achar espaço livre e distribuir o patch.
- `snes-testes`: rodar o Mesen pela linha de comando e checar RAM por script Lua.
