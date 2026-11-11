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
- Pelo Lua, `emu.getCdlData(memType)` devolve as flags, o que permite exportar para outro formato com um script. Funciona dentro do `--testRunner`, sem janela: `emu.getCdlData(emu.memType.snesPrgRom)` num callback de `endFrame` devolveu as flags acima [Teste local]. O DiztinGUIsh não lê esse formato; para levar o CDL até ele, ver a conversão logo abaixo.

Como usar bem:

1. Comece o CDL limpo (Reset) logo antes da parte que interessa, ou acumule várias sessões para cobrir o jogo inteiro.
2. Passe por todos os caminhos: menus, mortes, fim de fase, opções. Rotina que não rodou não é marcada.
3. Salve o `.cdl` junto do projeto (ele não contém a ROM, só flags e CRC) [MesenCE src].

### Converter o CDL do Mesen para o DiztinGUIsh

O DiztinGUIsh só importa o CDL do BizHawk (ver [ferramentas.md](ferramentas.md)). O script próprio `references/cdl_mesen_para_bizhawk.py` (Python 3, sem dependências, código original deste repositório) faz a conversão:

```
python cdl_mesen_para_bizhawk.py jogo.cdl jogo.sfc jogo-bizhawk.cdl
```

A ROM entra porque o CDL do Mesen só tem flags: o tamanho de cada instrução sai do byte do opcode na ROM e do M e do X gravados no CDL. Depois, no DiztinGUIsh, o arquivo gerado é importado como CDL do BizHawk.

O que o script faz, com a fonte de cada regra:

- **Lê o `.cdl` do Mesen**: com cabeçalho `CDLv2` e CRC32 (9 bytes) ou no formato antigo, sem cabeçalho, como o próprio Mesen aceita (`CodeDataLogger.cpp`) [MesenCE src]. Avisa quando o CRC32 da ROM não bate com o gravado. O Mesen calcula esse CRC sobre a PRG ROM já sem o cabeçalho de copiadora de 512 bytes (`SnesDebugger.cpp`, `BaseCartridge.cpp`), e o script também tira esse cabeçalho (tamanho com resto 512 na divisão por 1024) antes de comparar.
- **Acha o começo de cada instrução** do mesmo jeito que o Mesen reconstrói a própria desmontagem a partir do CDL (`SnesCodeDataLogger::RebuildPrgCache`): percorre a ROM, e cada byte marcado como código que não está dentro da instrução anterior é um opcode. O tamanho vem do opcode e das flags `0x20` (M=1) e `0x10` (X=1) desse byte, pela tabela de modos de `SnesDisUtils.cpp` [MesenCE src]. A tabela do script foi conferida contra a do Mesen (os 256 opcodes, nos quatro estados de M e X) e, pelo teste automatizado, contra a coluna de bytes da tabela de opcodes da skill `snes-assembly` (`references/instrucoes.md`, montada no asar) [Teste local].
- **Escreve as flags do BizHawk**: `0x01` no primeiro byte, junto com o M e o X (`0x20` e `0x10`), `0x02` nos bytes de operando e `0x04` no byte que o Mesen marcou como dado. São os valores do `eCDLog_Flags` do libsnes do BizHawk, que grava o M e o X só no primeiro byte (`op_readpcfirst`) [BizHawk src]; o importador do DiztinGUIsh lê o M e o X do primeiro byte e repete nos operandos [DiztinGUIsh src].
- **Monta o arquivo** como o `CodeDataLog.Save` do BizHawk: string `BIZHAWK-CDL-2`, sistema `SNES` completado com espaços até 15 caracteres, quantidade de blocos e cada bloco com nome e tamanho. Strings no formato do `BinaryWriter` do .NET (tamanho em 7 bits por byte, depois UTF-8), inteiros de 32 bits little-endian [BizHawk src]. Só vai o bloco `CARTROM`, o único que o DiztinGUIsh usa [DiztinGUIsh src].

O que se perde ou fica de fora:

- Destino de salto (`0x04`) e entrada de sub-rotina (`0x08`) do Mesen não têm equivalente no CDL do BizHawk e são descartados [BizHawk src].
- Byte com a marca do GSU (`0x40`) ou do Cx4 (`0x80`) não vira código do 65816: é código de outro processador, e o Mesen também o trata assim ao reconstruir a desmontagem [MesenCE src]. Se tiver a marca de dado, sai como dado.
- O BizHawk não abre o arquivo gerado: ao carregar, ele exige os mesmos blocos que ele mesmo cria (`CARTROM-DB`, `WRAM`, `APURAM` e outros) [BizHawk src]. O arquivo é para o DiztinGUIsh.
- **M e X misturados.** O Mesen junta as flags com OU a cada execução [MesenCE src]: um byte executado uma vez com M=1 e outra com M=0 fica com M=1, e o script decodifica como 8 bits. Quando isso faz o operando cair num byte que o Mesen não marcou como código, o script avisa (`byte(s) de operando sem a marca de código`). Nesse trecho, confira à mão no DiztinGUIsh.

Testado com ROM e CDL sintéticos montados no próprio teste, sem ROM comercial: `python -m unittest test_cdl_mesen_para_bizhawk -v` nesta pasta (17 testes) [Teste local]. O teste lê o arquivo gerado com uma cópia em Python da lógica do importador do DiztinGUIsh (`BizHawkCdlImporter`), mas a abertura no programa de verdade ainda não foi feita (não confirmado).

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
