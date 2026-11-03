# Mesen: linha de comando e Lua para teste

Tudo conferido no código do MesenCE (commit 4b8a196, 07/10/2026) e comparado com o Mesen 2 arquivado [MesenCE src][Mesen2 src]. Os pontos marcados com [Teste local] foram conferidos rodando o MesenCE 2.2.1 no Windows 11 com uma ROM própria de 32 KB montada pelo asar; o resto é o que o código faz.

## Executável

O nome é `Mesen` em todos os sistemas: o projeto da interface gera o assembly `Mesen` [MesenCE src], e os pacotes da versão 2.2.1 trazem `Mesen.exe` no Windows, `Mesen` no Linux e `Mesen.app/Contents/MacOS/Mesen` no macOS, cada um num zip de um arquivo só [MesenCE releases]. No Windows o arquivo diz versão 2.2.1, produto "Mesen" [Teste local].

## Opções de linha de comando

O Mesen aceita opção com `--`, `-` ou `/`, sem diferença de maiúscula e minúscula [MesenCE src].

| Opção | O que faz |
|---|---|
| `--testRunner` | Roda o script Lua sem interface e devolve o código de saída (detalhe abaixo) |
| `--timeout=N` | Só no test runner: limite em segundos, padrão 100 |
| `--novideo`, `--noaudio`, `--noinput` | Desligam vídeo, áudio e entrada |
| `--enableStdout` | Escreve o conteúdo da janela de log do emulador na saída padrão |
| `--doNotSaveSettings` | Não grava no disco as opções passadas pela linha de comando |
| `--fullscreen`, `--loadLastSession`, `--recordMovie="arquivo.mmo"` | Tela cheia, retomar a última sessão, gravar movie |

Arquivo terminado em `.lua` é tratado como script; o outro arquivo é a ROM [MesenCE src].

### Opções de configuração

Qualquer propriedade da configuração pode ser passada como `--caminho.propriedade=valor`; o Mesen lista as válidas no texto de ajuda [MesenCE src]. As úteis para teste de SNES:

| Opção | Valores | Para quê |
|---|---|---|
| `--snes.ramPowerOnState=` | `AllZeros`, `AllOnes`, `Random` | Estado inicial da RAM; `Random` pega variável não inicializada |
| `--snes.enableRandomPowerOnState=` | `true`, `false` | Aleatoriza também outros estados de power on |
| `--snes.enableStrictBoardMappings=` | `true`, `false` | Mapeamento de placa mais estrito |

### Liberar `io` e `os`: `--debug.scriptWindow.allowIoOsAccess=true`

O nome bate com a configuração `ScriptWindow.AllowIoOsAccess` da interface, que vira `ScriptAllowIoOsAccess` no núcleo [MesenCE src]. Com ela ligada, o núcleo carrega `io`, `os` e `package`, permite carregar arquivo e acrescenta a pasta do script ao `package.path` (para `require`) [MesenCE src]. Conferido [Teste local]:

- Sem a opção, `io`, `os` e `package` são `nil`. Com ela, as três são tabelas e `io.open` grava arquivo.
- Caminho relativo **não** é relativo à pasta de onde você rodou: o Mesen troca a pasta atual para a pasta home dele na inicialização [MesenCE src], e o arquivo de teste foi parar em `Documentos\MesenCE\`. Use caminho absoluto ou `emu.getScriptDataFolder()`, que só devolve pasta (`LuaScriptData\<nome do script>` dentro da home) quando o acesso está liberado [MesenCE src].
- No `--testRunner` a opção vale só naquela execução: a rodada seguinte sem ela voltou com `io` em `nil`, porque o test runner não grava configuração [MesenCE src].
- Acesso à rede (LuaSocket) é outra opção, `AllowNetworkAccess`, e só vale junto com esta [MesenCE src].

## O `--testRunner` passo a passo

Pelo código de `TestRunner.cs` [MesenCE src]:

1. Desliga a gravação das configurações.
2. Exige exatamente uma ROM; com zero ou mais de uma, devolve -1.
3. Inicia o emulador sem vídeo, áudio nem entrada, em modo console, e carrega a ROM. Se a ROM não carregar, devolve -1.
4. Carrega o workspace de debug (labels) e os scripts Lua passados.
5. Liga a velocidade máxima e solta a emulação.
6. A cada 100 ms confere se a emulação parou. Parou: o código de saída é o valor passado para `emu.stop`. Passou do timeout: -1.

O valor volta como código de saída do processo. Conferido [Teste local]: `emu.stop(7)` saiu com 7, e um script que nunca chama `emu.stop` saiu com -1 depois do `--timeout`. No PowerShell, `-1` aparece como `-1` no `.ExitCode` do `Start-Process -Wait -PassThru` [Teste local] (a chamada direta com `&` não espera o Mesen: ver a receita); no bash, um código negativo aparece como 255 (o shell só guarda 8 bits). Esse detalhe dos shells é comportamento geral do sistema, não do Mesen.

### `emu.stop` contra `emu.exit`

O texto de ajuda diz "use emu.exit(...) to stop execution", mas a API Lua só tem `emu.stop(exitCode)`, descrita como a função que para a emulação e devolve o código usado pelo `--testRunner` [MesenCE src]. É a divergência mais importante desta skill: escreva `emu.stop`. Na prática [Teste local], um script com `emu.exit(5)` imprimiu o que vinha antes, parou com erro na chamada e o processo terminou em -1 por timeout, não em 5.

Outros dois detalhes do código [MesenCE src]:

- Se já existe um código diferente de zero guardado, uma segunda chamada não o substitui.
- A parada acontece em outra thread; o script pode continuar recebendo callbacks por alguns instantes. Use uma flag `terminou`.

## API Lua usada em teste

Nomes conferidos em `LuaApi.cpp` e na documentação embutida `LuaDocumentation.json` [MesenCE src].

### Memória

| Função | Uso |
|---|---|
| `emu.read(endereco, tipo, comSinal)` | Lê 1 byte |
| `emu.read16`, `emu.read32` | Lê 2 ou 4 bytes (`readWord` é apelido) |
| `emu.write(endereco, valor, tipo)`, `write16`, `write32` | Escreve |
| `emu.getMemorySize(tipo)` | Tamanho de um tipo de memória |
| `emu.convertAddress(endereco, tipo, cpu)` | Converte entre endereço de barramento e offset |
| `emu.getLabelAddress(nome)` | Endereço de um label carregado, ou nil |

Tipos de memória em `emu.memType`, com o nome em lowerCamel: `snesMemory` (barramento da CPU), `snesPrgRom`, `snesWorkRam`, `snesSaveRam`, `snesVideoRam`, `snesSpriteRam`, `snesCgRam`, `snesRegister`. Tipos relativos têm uma variante `...Debug` (por exemplo `snesDebug`) que lê sem efeito colateral, importante quando o endereço é registrador de hardware.

Em `snesWorkRam`, o endereço é o offset dentro da WRAM: `0x0100` é o byte em `$7E0100`.

`emu.getLabelAddress` permite que o teste use o nome definido no código em vez de um número fixo, se os labels forem carregados pelo workspace de debug.

### Eventos

`emu.addEventCallback(funcao, tipo)` devolve uma referência para `emu.removeEventCallback`. Tipos em `emu.eventType`: `nmi`, `irq`, `startFrame`, `endFrame`, `reset`, `scriptEnded`, `inputPolled`, `stateLoaded`, `stateSaved`, `codeBreak` [MesenCE src].

`emu.addMemoryCallback(funcao, tipo, inicio, fim, cpu, memoria)` chama a função com endereço e valor. Tipo em `emu.callbackType`: `read`, `write`, `exec`. Leitura dispara depois da leitura, escrita antes da escrita; devolver um inteiro troca o valor [MesenCE src].

**DMA e HDMA disparam os mesmos callbacks.** No SNES, cada byte copiado pelo DMA geral ou pelo HDMA passa por `SnesMemoryManager::WriteDma`, que registra a operação como `DmaWrite`; no `ScriptManager`, `Write`, `DummyWrite` e `DmaWrite` caem no callback `write`, e `DmaRead` cai no `read` [MesenCE src][Mesen2 src]. A função Lua recebe só endereço e valor, sem o tipo da operação, então não dá para separar CPU de DMA pelo argumento. Teste de 03/11/2026 numa ROM própria [Teste local]: HDMA no canal 0, modo 2, em `$210D`, tabela de 4 entradas de 16 linhas, e a CPU escrevendo `$210D` duas vezes no vblank. O callback de escrita em `$210D` rodou 10 vezes por quadro (8 do HDMA, nas linhas 0, 16, 32 e 48, e 2 da CPU, na linha 225); um DMA geral de 4 bytes para `$2180` disparou 4 vezes. Nas escritas do HDMA, `cpu.pc` era o da instrução que a CPU estava executando naquele momento. O callback de leitura também disparou nas leituras da tabela do HDMA.

Para conferir só o que a CPU escreveu:

- filtre pela posição: `emu.getState()["ppu.scanline"]`, sabendo em que linhas o HDMA roda;
- use um callback `exec` no endereço da instrução que grava e leia o valor ali;
- desligue o HDMA (`$420C` = 0) no teste que não depende dele;
- confira o valor esperado em vez de contar chamadas.

### Entrada

- `emu.setInput(tabela, porta, subporta)`: botões em `a b x y l r start select up down left right`; a porta 0 é o jogador 1. O estado vale até o próximo `inputPolled`; botão não citado fica com o jogador.
- `emu.getInput(porta, subporta)`: estado atual.

### Savestate, tela e outros

- `emu.createSavestate()` devolve uma string binária; `emu.loadSavestate(s)` carrega. **Só dentro de callback `exec` da CPU principal.**
- `emu.takeScreenshot()` devolve um PNG como string; não grava arquivo.
- `emu.getState()`: ver a seção abaixo.
- `emu.getRomInfo()` devolve nome, caminho e SHA-1 do arquivo: útil para o teste recusar ROM errada.
- `emu.reset()` só funciona dentro de callback.
- `emu.addCheat`, `emu.clearCheats`, `emu.getAccessCounters`, `emu.getCdlData` também existem.
- O MesenCE acrescenta `getCpuState`, `setCpuState`, `getCpuCycleCount`, `getMasterClock`, `drawPixels` e `getPressedKeys`.

### O que o `emu.getState()` devolve no SNES

O núcleo serializa o console inteiro num mapa e acrescenta alguns valores próprios do Lua [MesenCE src]. O resultado é uma tabela **plana**, com o caminho no nome da chave: `s["cpu.a"]` funciona, `s.cpu` é `nil`. Na 2.2.1 com uma ROM LoROM simples vieram 602 chaves [Teste local]:

| Grupo | Exemplos de chave |
|---|---|
| Valores do Lua | `frameCount`, `masterClock`, `clockRate` (21477270 em NTSC), `consoleType` (`Snes`), `region` (`Ntsc`) |
| `cpu.` | `cpu.a`, `cpu.x`, `cpu.y`, `cpu.sp`, `cpu.d`, `cpu.dbr`, `cpu.k`, `cpu.pc`, `cpu.ps`, `cpu.emulationMode`, `cpu.cycleCount` |
| `ppu.` | `ppu.bgMode`, `ppu.forcedBlank`, `ppu.screenBrightness`, `ppu.scanline`, `ppu.frameCount`, `ppu.vramAddress`, `ppu.layers[0].hscroll`, `ppu.mode7.matrix[0]`, `ppu.window[0].left` |
| `spc.` | `spc.a`, `spc.x`, `spc.y`, `spc.pc`, `spc.sp`, `spc.ps`, `spc.timer0.target`, `spc.dsp.voices[0].envVolume` |
| `dmaController.` | `dmaController.channel[0].srcAddress`, `...transferSize`, `...hdmaTableAddress`, `dmaController.hdmaChannels` |
| `internalRegisters.` | `internalRegisters.enableNmi`, `...hCounter`, `...vCounter`, `...controllerData[0]`, `...aluMulDiv.multOperand1` |
| `memoryManager.`, `controlManager.` | `memoryManager.cpuSpeed`, `memoryManager.registerHandlerB.wramPosition`, `controlManager.pollCounter` |

Detalhes que pegam:

- Os valores são números ou booleanos, não texto em hexa: `cpu.pc=32768` é `$8000`.
- O `frameCount` começa em 0: no décimo callback `endFrame` ele valia 9 [Teste local].
- Só ROM sem chip de cartucho foi testada; se um jogo com SA-1 ou SuperFX acrescenta chaves, não foi conferido.
- O código atual do MesenCE, posterior à 2.2.1, acrescenta `fps` aos valores do Lua [MesenCE src]; na 2.2.1 essa chave não existe [Teste local]. É o exemplo concreto de que o conjunto muda entre versões: para o teste decidir, continue preferindo `emu.read` num endereço combinado.

## Sandbox do script

- Sem acesso liberado (padrão), as bibliotecas `io`, `os` e `package` não são carregadas [MesenCE src][Teste local]. Como liberar: seção "Liberar `io` e `os`" acima.
- Cada execução tem limite de tempo, `ScriptTimeout`, padrão 1 segundo [MesenCE src].
- `print` é o do Lua (saída padrão do processo). No Windows, rodando o `--testRunner` pelo PowerShell, a saída aparece no terminal e também pode ser redirecionada para arquivo (`Start-Process ... -RedirectStandardOutput saida.txt`, ou `>` no `cmd`) [Teste local]. `emu.log` vai para a janela de log do script (500 linhas). `emu.displayMessage` vai para as mensagens do emulador, que `--enableStdout` manda para a saída padrão [MesenCE src].
