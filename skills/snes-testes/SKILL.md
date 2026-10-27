---
name: snes-testes
description: Testar ROM e ROM hack de Super Nintendo (SNES / Super Famicom), em emulador e em console real. Use quando a tarefa envolver rodar o Mesen 2 / MesenCE pela linha de comando, o modo --testRunner (Lua sem interface, código de saída), escrever script Lua de teste com a API emu.* (emu.read, emu.stop, emu.setInput, addEventCallback, addMemoryCallback, savestate por script), montar teste automatizado de ROM hack (montar com asar, rodar N quadros, conferir RAM, sair com 0 ou 1, rodar no CI), escolher emulador pela precisão (Mesen, bsnes, higan, ares, snes9x, e por que não o ZSNES), estado inicial da RAM aleatório para pegar variável não inicializada, ou testar em console com flash cart (SD2SNES, FXPAK, FXPAK Pro, Super EverDrive, usb2snes) e seus limites com chips especiais. Também serve para perguntas como "como testo meu hack sem abrir o emulador", "o emu.exit não existe", "por que funciona no ZSNES e não no console", "qual emulador é o mais preciso" ou "o FXPAK roda SuperFX".
---

# snes-testes

Como provar que uma ROM ou um hack funciona: teste automático no Mesen, escolha de emulador e teste no console. Este arquivo traz as regras e o índice; opções, API e receitas ficam em `references/`. Nenhum executável foi rodado na pesquisa desta skill: nomes de opção e de função vêm do código-fonte do Mesen, e o comportamento descrito é o que o código faz.

## Regras de ouro

1. **O teste termina com `emu.stop(codigo)`, não com `emu.exit`.** O texto de ajuda do Mesen cita `emu.exit(...)`, mas essa função não existe na API; a que define o código de saída do `--testRunner` é `emu.stop` [MesenCE src]. Ver `references/mesen-linha-de-comando-e-lua.md`.
2. **Sempre passe `--timeout`.** O padrão é 100 segundos; se o script não chamar `emu.stop` a tempo, o processo devolve -1 [MesenCE src]. Erro de script não para o emulador, então ele também acaba como timeout.
3. **Teste em emulador preciso antes de chamar de pronto.** Mesen é apontado como provavelmente o mais preciso hoje [SNESdev Tools]; bsnes e ares descendem da linha de precisão do higan [bsnes][ares]. ZSNES fica fora: prioriza velocidade e esconde bug que quebra no console [ZSNES wiki]. Ver `references/emuladores.md`.
4. **Ligue o estado inicial aleatório da RAM no teste.** No Mesen, `--snes.ramPowerOnState=Random` faz a RAM começar com lixo, o que expõe variável lida antes de ser escrita [MesenCE src]. O console real também não começa zerado; os detalhes do hardware estão em `snes-hardware`.
5. **Um quadro, uma decisão.** Leia a RAM e decida no callback de fim de quadro, com uma flag que impede chamar `emu.stop` duas vezes. O stop é assíncrono e o primeiro código diferente de zero vence [MesenCE src].
6. **Entrada simulada vai no `inputPolled`.** `emu.setInput` vale até o próximo `inputPolled`, e a documentação recomenda chamá-lo dentro desse callback [MesenCE src].
7. **Console real no fim, não no começo.** Flash cart testa timing e hardware de verdade, mas tem limites: save state só em jogo sem chip especial no SD2SNES/FXPAK [sd2snes CHANGELOG], e suporte a chip varia por modelo. Ver `references/console-real-flashcart.md`.

## Teste mínimo

```
Mesen.exe --testRunner teste.lua hack.sfc --timeout=30 --snes.ramPowerOnState=Random
```

Código de saída: o que o script passou para `emu.stop`, ou -1 em timeout, ROM que não carregou ou número errado de ROMs [MesenCE src]. Script completo e receita com asar em `references/receita-teste-automatizado.md`.

## Armadilhas

- **Script sem `io` nem `os`.** Por padrão o Lua do Mesen roda sem as bibliotecas `io`, `os` e `package`; gravar arquivo exige liberar o acesso nas configurações do script [MesenCE src]. Use o código de saída e `print` para o resultado.
- **Callback demorado.** Cada execução de script tem limite de 1 segundo por padrão (`ScriptTimeout`); passar disso gera erro [MesenCE src]. Nada de laço longo dentro do callback.
- **`emu.log` não vai pro terminal.** Ele escreve na janela de log do script. `print` é o do Lua e escreve na saída padrão do processo; se o seu terminal no Windows mostra essa saída não foi confirmado [MesenCE src].
- **Savestate por script tem lugar certo.** `emu.createSavestate` e `emu.loadSavestate` só funcionam dentro de um callback de execução (`exec`) da CPU principal [MesenCE src].
- **Mesen 2 arquivado.** O repositório original foi arquivado e o desenvolvimento segue no MesenCE; a documentação em mesen.ca é da versão antiga de NES [Mesen2 src][MesenCE src].
- **Nome de chave do `emu.getState()` muda.** Prefira `emu.read` em endereço de RAM combinado a depender de chave de estado [MesenCE src].
- **Teste que passa no emulador e falha no console.** Acesso a VRAM fora do vblank e DMA no momento errado são clássicos; confira as regras em `snes-hardware` e as opções de parada do debugger em `snes-desmontagem`.

## Índice de referências

| Arquivo | O que tem |
|---|---|
| `references/mesen-linha-de-comando-e-lua.md` | Opções de linha de comando, `--testRunner` passo a passo, opções de configuração por `--caminho=valor`, API Lua usada em teste (memória, eventos, entrada, savestate, enums) e o sandbox |
| `references/receita-teste-automatizado.md` | Montar com asar, rodar N quadros, conferir RAM, sair com 0 ou 1; script Lua original completo; como rodar em PowerShell, bash e CI |
| `references/emuladores.md` | Mesen, bsnes, higan, ares, snes9x e ZSNES: para que serve cada um em teste e por que o ZSNES não serve |
| `references/console-real-flashcart.md` | SD2SNES, FXPAK, FXPAK Pro, Super EverDrive: chips suportados, save state, USB, o que não dá pra testar |
| `references/fontes.md` | Fontes, confiança, divergências e o que não foi confirmado |

## Relação com outras skills

- `snes-rom-hack`: montar o hack com asar e gerar o patch; a receita de teste chama esse build.
- `snes-hardware`: regras de timing e acesso que o teste no emulador preciso e no console pegam.
- `snes-desmontagem`: debugger, breakpoints e CDL do Mesen para investigar um teste que falhou.
- `snes-assembly`: o código que está sendo testado.
