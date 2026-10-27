# Separar código de dado e acompanhar M/X

## Por que é difícil no 65816

O tamanho do operando imediato depende das flags M (acumulador e memória) e X (índices). O mesmo byte pode iniciar uma instrução de 2 ou de 3 bytes, e a desmontagem linear desalinha a partir daí. A explicação das flags e das instruções `REP`/`SEP` está na skill `snes-assembly` (`references/registradores-e-flags.md` e `references/armadilhas.md`). Aqui o foco é como as ferramentas resolvem isso.

## Code/Data Logger do Mesen

Conferido no código do MesenCE [MesenCE src]:

- Cada byte da ROM tem um byte de flags no CDL. Flags gerais: `0x01` código, `0x02` dado, `0x04` destino de salto, `0x08` entrada de sub-rotina.
- Flags próprias do SNES: `0x10` índices em 8 bits (X=1), `0x20` acumulador em 8 bits (M=1), `0x40` acessado pelo GSU, `0x80` acessado pelo Cx4. Ou seja, **o CDL registra o estado de M e X com que cada byte foi executado**, que é exatamente o que falta para desmontar sem chute.
- Arquivo `.cdl`: começa com o texto `CDLv2`, seguido do CRC32 da ROM em 4 bytes (cabeçalho de 9 bytes), depois um byte por byte de ROM. Arquivo antigo sem CRC carrega com aviso.
- "Generate ROM" gera uma cópia da ROM tirando o que não foi usado ou o que foi usado. Útil para ver no visualizador quais regiões o jogo nunca tocou na sessão.
- Pelo Lua, `emu.getCdlData(memType)` devolve as flags, o que permite exportar para outro formato com um script.

Como usar bem:

1. Comece o CDL limpo (Reset) logo antes da parte que interessa, ou acumule várias sessões para cobrir o jogo inteiro.
2. Passe por todos os caminhos: menus, mortes, fim de fase, opções. Rotina que não rodou não é marcada.
3. Salve o `.cdl` junto do projeto (ele não contém a ROM, só flags e CRC) [MesenCE src].

## Usage map do bsnes-plus

O bsnes-plus marca em tempo real, no editor de memória, o que foi executado e o que foi lido, e permite procurar regiões ainda não exploradas [bsnes-plus]. O DiztinGUIsh importa o usage map do BSNES [DiztinGUIsh].

## Trace logger

O trace grava instrução por instrução com o estado dos registradores. No Mesen o formato é montado por tags; o padrão do SNES mostra A, X, Y, S, D e DB depois da instrução [MesenCE src]. Tags úteis para desmontagem:

| Tag | Para quê |
|---|---|
| `[PC]`, `[ByteCode]`, `[Disassembly]` | Onde está e o que executou |
| `[EffectiveAddress]`, `[MemoryValue]` | Endereço final de acessos indexados ou indiretos e o valor lido |
| `[Scanline]`, `[FrameCount]` | Situar o trecho no tempo (vblank, quadro) |
| `P` | Flags, inclusive M e X, a cada instrução |

O log pode ser condicional, com a mesma sintaxe de expressão dos breakpoints [Mesen docs] (documentação da versão antiga; a existência do campo de condição foi conferida no código, a sintaxe exata não).

Trace longo cresce rápido. Ligue o trace só em volta do evento (com breakpoint) ou use a "trace mask" do bsnes-plus, que registra cada endereço uma vez só [bsnes-plus].

## Acompanhar M/X na desmontagem

Ordem de preferência:

1. **Estado registrado em execução**: flags do CDL do Mesen ou trace importado no DiztinGUIsh [MesenCE src][DiztinGUIsh].
2. **Propagação pelo desmontador**: o DiztinGUIsh segue `REP`/`SEP` e guarda M, X, DB e D por instrução [DiztinGUIsh]. Funciona bem em código linear e falha onde o estado vem da pilha (`PLP`, `RTI`) ou de quem chamou.
3. **Ajuste manual**: no Ghidra com ghidra-65816 as flags se definem à mão por região, e o plugin não atualiza o modo depois de `PLP` nem de `RTI` [ghidra-65816].

Sinal de M/X errado: instrução absurda logo depois de um imediato (`BRK`, `COP`, `WDM` ou `STP` no meio de código normal), ou desvio que cai no meio de outra instrução. O Mesen pode parar em `BRK`, `COP`, `WDM` e `STP` [MesenCE src], o que ajuda a perceber quando a execução real caiu em lixo.

Uma rotina chamada de lugares com M/X diferentes aparece no CDL com as duas marcas misturadas; nesse caso o certo é documentar o estado de entrada exigido pela rotina (ou dividir em duas entradas), não escolher um. Essa recomendação é prática de organização, não vem de uma fonte específica.
