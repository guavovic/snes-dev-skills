# Mesen: linha de comando e Lua para teste

Tudo conferido no código do MesenCE (commit 4b8a196, 07/10/2026) e comparado com o Mesen 2 arquivado [MesenCE src][Mesen2 src]. Nada foi executado: é o que o código faz, não o que foi visto rodando.

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

A opção `--debug.scriptWindow.allowIoOsAccess=true` deveria liberar `io` e `os` para o script, pela forma como a configuração é aplicada no código, mas **não foi confirmada** em execução.

## O `--testRunner` passo a passo

Pelo código de `TestRunner.cs` [MesenCE src]:

1. Desliga a gravação das configurações.
2. Exige exatamente uma ROM; com zero ou mais de uma, devolve -1.
3. Inicia o emulador sem vídeo, áudio nem entrada, em modo console, e carrega a ROM. Se a ROM não carregar, devolve -1.
4. Carrega o workspace de debug (labels) e os scripts Lua passados.
5. Liga a velocidade máxima e solta a emulação.
6. A cada 100 ms confere se a emulação parou. Parou: o código de saída é o valor passado para `emu.stop`. Passou do timeout: -1.

O valor volta como código de saída do processo. No PowerShell, `-1` aparece como `-1` em `$LASTEXITCODE`; no bash, um código negativo aparece como 255 (o shell só guarda 8 bits). Esse detalhe dos shells é comportamento geral do sistema, não do Mesen.

### `emu.stop` contra `emu.exit`

O texto de ajuda diz "use emu.exit(...) to stop execution", mas a API Lua só tem `emu.stop(exitCode)`, descrita como a função que para a emulação e devolve o código usado pelo `--testRunner` [MesenCE src]. É a divergência mais importante desta skill: escreva `emu.stop`.

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

### Entrada

- `emu.setInput(tabela, porta, subporta)`: botões em `a b x y l r start select up down left right`; a porta 0 é o jogador 1. O estado vale até o próximo `inputPolled`; botão não citado fica com o jogador.
- `emu.getInput(porta, subporta)`: estado atual.

### Savestate, tela e outros

- `emu.createSavestate()` devolve uma string binária; `emu.loadSavestate(s)` carrega. **Só dentro de callback `exec` da CPU principal.**
- `emu.takeScreenshot()` devolve um PNG como string; não grava arquivo.
- `emu.getState()` devolve uma tabela com chaves como `frameCount` e `masterClock`; os nomes podem mudar entre versões.
- `emu.getRomInfo()` devolve nome, caminho e SHA-1 do arquivo: útil para o teste recusar ROM errada.
- `emu.reset()` só funciona dentro de callback.
- `emu.addCheat`, `emu.clearCheats`, `emu.getAccessCounters`, `emu.getCdlData` também existem.
- O MesenCE acrescenta `getCpuState`, `setCpuState`, `getCpuCycleCount`, `getMasterClock`, `drawPixels` e `getPressedKeys`.

## Sandbox do script

- Sem acesso liberado (padrão), as bibliotecas `io`, `os` e `package` não são carregadas [MesenCE src].
- Cada execução tem limite de tempo, `ScriptTimeout`, padrão 1 segundo [MesenCE src].
- `print` é o do Lua (saída padrão do processo). `emu.log` vai para a janela de log do script (500 linhas). `emu.displayMessage` vai para as mensagens do emulador, que `--enableStdout` manda para a saída padrão [MesenCE src].
