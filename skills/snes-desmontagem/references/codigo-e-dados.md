# Separar código de dado e acompanhar M/X

## Por que é difícil no 65816

O tamanho do operando imediato depende das flags M (acumulador e memória) e X (índices). O mesmo byte pode iniciar uma instrução de 2 ou de 3 bytes, e a desmontagem linear desalinha a partir daí. A explicação das flags e das instruções `REP`/`SEP` está na skill `snes-assembly` (`references/registradores-e-flags.md` e `references/armadilhas.md`). Aqui o foco é como as ferramentas resolvem isso.

## Code/Data Logger do Mesen

Conferido no código do MesenCE [MesenCE src]:

- Cada byte da ROM tem um byte de flags no CDL. Flags gerais: `0x01` código, `0x02` dado, `0x04` destino de salto, `0x08` entrada de sub-rotina.
- Flags próprias do SNES: `0x10` índices em 8 bits (X=1), `0x20` acumulador em 8 bits (M=1), `0x40` acessado pelo GSU, `0x80` acessado pelo Cx4. Ou seja, **o CDL registra o estado de M e X com que cada byte foi executado**, que é exatamente o que falta para desmontar sem chute.
- O byte de operando recebe a mesma flag `0x01` do opcode, com M e X; destino de salto e entrada de sub-rotina ficam só no primeiro byte. Não existe flag que separe opcode de operando: para achar o começo de cada instrução, decodifique a partir do início de cada trecho de código. Conferido rodando [Teste local]: num trecho LoROM próprio, `LDA #$1234` com M=0 deu `01 01 01`, `LDA #$12` depois de `SEP #$20` deu `21 21`, o alvo de um `BRA` deu `25` (código, destino de salto, M=1), a primeira instrução da sub-rotina chamada por `JSR` deu `29` (código, entrada de sub-rotina, M=1) e o byte de tabela lido por `LDA abs` deu `02`.
- O estado gravado é o de antes da instrução: o `REP #$20` executado com M=1 fica marcado com M=1 [MesenCE src][Teste local].
- Arquivo `.cdl`: começa com o texto `CDLv2`, seguido do CRC32 da ROM em 4 bytes (cabeçalho de 9 bytes), depois um byte por byte de ROM. Arquivo antigo sem CRC carrega com aviso.
- "Generate ROM" gera uma cópia da ROM tirando o que não foi usado ou o que foi usado. Útil para ver no visualizador quais regiões o jogo nunca tocou na sessão.
- Pelo Lua, `emu.getCdlData(memType)` devolve as flags, o que permite exportar para outro formato com um script. Funciona dentro do `--testRunner`, sem janela: `emu.getCdlData(emu.memType.snesPrgRom)` num callback de `endFrame` devolveu as flags acima [Teste local]. O DiztinGUIsh não lê esse formato; ver [ferramentas.md](ferramentas.md).

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

O log pode ser condicional: o campo "Condition" da janela do trace logger usa o mesmo avaliador de expressões dos breakpoints e da watch list [MesenCE src][Mesen docs].

### Sintaxe da condição

Conferida no `ExpressionEvaluator` e no `BaseTraceLogger` do MesenCE (commit 4b8a196) e na ajuda que a própria interface mostra (`ExpressionTooltipHelper`) [MesenCE src], com a documentação antiga como segunda fonte [Mesen docs]:

- **Números**: sem prefixo é **decimal**; hexadecimal com `$` ou `0x`; binário com `%` quando vem depois de um operador (senão `%` é resto da divisão). `a == 10` compara com dez, não com $10.
- **Operadores**: os do C, com precedência do C: `* / %`, `+ -`, `<< >>`, `< <= > >=`, `== !=`, `&`, `^`, `|`, `&&`, `||`, unários `- ~ !` e parênteses.
- **Memória**: `[end]` lê 1 byte, `{end}` lê 2 bytes, `#end` lê 4 bytes, `:end` devolve o offset na ROM ou na RAM do endereço de CPU (-1 se não estiver mapeado). Pode aninhar: `[[$15] + y]`.
- **Registradores e tempo no SNES**: `a`, `x`, `y`, `ps`, `sp`, `pc` (24 bits, banco incluído), `db`, `d`, `irq`, `nmi`, `frame`, `scanline`, `cycle`, `hclock` e as flags de `ps` uma a uma: `pscarry`, `pszero`, `psinterrupt`, `psindex`, `psmemory`, `psdecimal`, `psoverflow`, `psnegative`.
- **Acesso em curso**: `address` (endereço de CPU lido ou escrito), `memaddress` (offset na ROM ou na RAM, -1 se não mapeado), `value`, `isread`, `iswrite`, `isdma`, `isdummy`, `oppc` (PC do primeiro byte da instrução). `isread` é verdadeiro em qualquer acesso que não seja escrita, inclusive a busca do opcode e dos operandos; para leitura de dado, junte com `address` ou `memaddress`.
- **Labels** carregados podem entrar no lugar de endereço. Os nomes de valor aceitam maiúscula ou minúscula (o avaliador converte), mas o label é procurado com a grafia exata.

Como o trace avalia a condição: primeiro na busca do opcode; se não bater, de novo em cada acesso seguinte da mesma instrução (operandos, leituras, escritas), e a instrução entra no log uma vez só, no primeiro acesso que bater [MesenCE src]. Por isso dá para registrar só as instruções que escrevem num endereço.

Exemplos, escritos para este guia:

| Condição | O que registra |
|---|---|
| `pc >= $808000 && pc < $808100` | Só o que roda nesse trecho do banco $80 |
| `iswrite && address == $7E0100` | Instruções que escrevem em $7E0100 por esse endereço de 24 bits |
| `psmemory == 0` | Só instruções executadas com acumulador de 16 bits |
| `frame >= 600` | Só a partir do quadro 600 |
| `[$7E0010] == 3` | Só enquanto o byte $7E0010 vale 3 |

Cuidados:

- **Condição inválida não filtra nada.** Se a expressão não compila, o núcleo descarta a condição e o trace grava tudo; a janela mostra o aviso "Condition contains invalid syntax or symbols" [MesenCE src].
- **`address` é o endereço do acesso como a CPU o fez.** A mesma variável da WRAM pode aparecer como `$000100` ou `$7E0100` conforme o banco usado (espelhos em `snes-hardware`). Para pegar todos os espelhos, use `iswrite && memaddress == $100` (offset na WRAM; o valor não diz o tipo de memória, então um offset igual na SRAM também bate) ou um breakpoint de escrita com tipo de memória Work RAM, que compara pelo offset dentro da WRAM [MesenCE src].
- A documentação online é do Mesen antigo (NES, 0.9.9) e lista valores de NES como `Sprite0Hit`; no SNES valem os nomes acima [Mesen docs][MesenCE src].
- A janela do trace logger é da interface: não há função Lua para ligar o trace nem para avaliar expressão, então a sintaxe foi conferida no código e na ajuda embutida, não executada [MesenCE src].

Trace longo cresce rápido. Ligue o trace só em volta do evento (com breakpoint) ou use a "trace mask" do bsnes-plus, que registra cada endereço uma vez só [bsnes-plus].

## Acompanhar M/X na desmontagem

Ordem de preferência:

1. **Estado registrado em execução**: flags do CDL do Mesen ou trace importado no DiztinGUIsh [MesenCE src][DiztinGUIsh].
2. **Propagação pelo desmontador**: o DiztinGUIsh segue `REP`/`SEP` e guarda M, X, DB e D por instrução [DiztinGUIsh]. Funciona bem em código linear e falha onde o estado vem da pilha (`PLP`, `RTI`) ou de quem chamou.
3. **Ajuste manual**: no Ghidra com ghidra-65816 as flags se definem à mão por região, e o plugin não atualiza o modo depois de `PLP` nem de `RTI` [ghidra-65816].

Sinal de M/X errado: instrução absurda logo depois de um imediato (`BRK`, `COP`, `WDM` ou `STP` no meio de código normal), ou desvio que cai no meio de outra instrução. O Mesen pode parar em `BRK`, `COP`, `WDM` e `STP` [MesenCE src], o que ajuda a perceber quando a execução real caiu em lixo.

Uma rotina chamada de lugares com M/X diferentes aparece no CDL com as duas marcas misturadas; nesse caso o certo é documentar o estado de entrada exigido pela rotina (ou dividir em duas entradas), não escolher um. Essa recomendação é prática de organização, não vem de uma fonte específica.
