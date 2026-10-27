# Receita: teste automatizado de ROM hack

Objetivo: um comando que monta o hack, roda no Mesen sem interface, confere a RAM e sai com 0 (passou) ou 1 (falhou). As funções e opções estão explicadas em [mesen-linha-de-comando-e-lua.md](mesen-linha-de-comando-e-lua.md). Nada aqui foi executado na pesquisa: a receita segue o código do Mesen [MesenCE src] e o build do asar descrito em `snes-rom-hack`.

## Ideia: um endereço de resultado

O jeito mais simples de o script saber se deu certo é o código testado escrever um valor combinado num endereço de RAM que o jogo não usa. Escolha um endereço que você provou estar livre (ver `snes-desmontagem` para achar o que o jogo usa).

Fragmento original em asar, para o código de teste (ou um hook de teste) chamar quando a condição esperada acontecer:

```asm
!resultado_teste = $7E1F00
!teste_ok = $A5

marca_teste_ok:
    php
    sep #$20
    lda #!teste_ok
    sta.l !resultado_teste
    plp
    rtl
```

O `php`/`plp` preserva M e X de quem chamou, e `sta.l` grava em endereço longo, sem depender do banco de dados. Os motivos estão em `snes-assembly` (`references/armadilhas.md`) e o jeito de pendurar isso num jogo, em `snes-rom-hack` (`references/espaco-livre-e-hooks.md`). Para um teste de ROM homebrew, o esqueleto de ROM completo está em `snes-hardware` (`references/exemplos.md`).

Quando não dá pra mexer no código, o teste pode conferir uma variável do próprio jogo (vidas, fase atual) cujo endereço você achou na desmontagem.

## Script Lua de teste

Script original. Aperta Start por alguns quadros, espera o endereço de resultado receber o valor combinado e para com 0; se o limite de quadros passar, para com 1.

```lua
local ENDERECO_RESULTADO = 0x1F00
local VALOR_OK = 0xA5
local QUADRO_APERTA_START = 120
local QUADROS_SEGURANDO = 4
local QUADRO_LIMITE = 1800

local quadro = 0
local terminou = false

local function terminar(codigo, mensagem)
  if terminou then
    return
  end
  terminou = true
  print(mensagem)
  emu.stop(codigo)
end

local function aoLerControle()
  local segurandoStart = quadro >= QUADRO_APERTA_START
    and quadro < QUADRO_APERTA_START + QUADROS_SEGURANDO
  if segurandoStart then
    emu.setInput({ start = true }, 0)
  end
end

local function aoFimDoQuadro()
  if terminou then
    return
  end
  quadro = quadro + 1

  local valor = emu.read(ENDERECO_RESULTADO, emu.memType.snesWorkRam)
  if valor == VALOR_OK then
    terminar(0, string.format("ok no quadro %d", quadro))
  elseif quadro >= QUADRO_LIMITE then
    terminar(1, string.format("falhou: $7E%04X = $%02X depois de %d quadros", ENDERECO_RESULTADO, valor, quadro))
  end
end

emu.addEventCallback(aoLerControle, emu.eventType.inputPolled)
emu.addEventCallback(aoFimDoQuadro, emu.eventType.endFrame)
```

Notas sobre o script:

- `0x1F00` em `snesWorkRam` é o offset na WRAM, ou seja `$7E1F00`, o mesmo endereço do fragmento asar.
- Seguro o Start por 4 quadros porque muitos jogos só reagem à borda (soltou e apertou); quantos quadros o seu jogo precisa é coisa de conferir nele.
- 1800 quadros são uns 30 segundos de jogo em NTSC; o `--timeout` em segundos reais deve ser folgado em relação a isso, mas como o test runner roda em velocidade máxima o tempo real costuma ser menor (não medido).
- Para checar a ROM certa, compare `emu.getRomInfo().fileSha1Hash` com o hash esperado e chame `terminar(1, ...)` se não bater.

### Pular o começo com savestate

Para não repetir a abertura em todo teste, dá para criar um savestate num ponto e carregá-lo. Como `emu.createSavestate` e `emu.loadSavestate` só funcionam dentro de callback `exec` da CPU principal [MesenCE src], registre um `emu.addMemoryCallback(funcao, emu.callbackType.exec, endereco)` num endereço de código que roda todo quadro (o início da rotina de NMI, por exemplo) e faça a troca lá dentro, uma vez só. Sem `io` liberado, o savestate só vive em memória durante o script.

## Rodar

PowerShell (Windows):

```powershell
asar.exe hack.asm hack.sfc
if ($LASTEXITCODE -ne 0) { exit 1 }
& .\Mesen.exe --testRunner teste.lua hack.sfc --timeout=60 --snes.ramPowerOnState=Random
exit $LASTEXITCODE
```

bash:

```sh
asar hack.asm hack.sfc || exit 1
./Mesen --testRunner teste.lua hack.sfc --timeout=60 --snes.ramPowerOnState=Random
codigo=$?
[ "$codigo" -eq 0 ] || { echo "teste falhou ($codigo)"; exit 1; }
```

O nome do executável depende do build e do sistema (no Mesen 2 para Windows é `Mesen.exe`); confira no seu. Lembre: -1 do Mesen aparece como 255 no bash.

Antes de montar, o build do hack deve conferir o hash da ROM base, como em `snes-rom-hack` (`references/fluxo-git-e-build.md`). A ROM nunca vai pro repositório, o que vale também para o CI: um teste de hack em CI só roda onde a ROM está disponível de forma legítima (máquina própria ou runner privado com a ROM do dono).

## Vários testes

- Um script por cenário, todos com o mesmo formato de saída, e um laço no build que roda cada um e soma as falhas.
- Rode cada teste com `Random` e também com `AllZeros`: diferença de resultado entre os dois quase sempre é variável não inicializada.
- Teste de regressão de memória: compare um bloco de WRAM com valores esperados lendo byte a byte com `emu.read` no fim do cenário.
