# Fontes da skill snes-testes

Consultadas em 26/10/2026. Nível de confiança: **alta** = código-fonte ou documento do próprio projeto; **média** = README ou wiki sem conferência no código; **baixa** = wiki de fãs, fórum ou loja, usada só com aviso. Nenhum executável foi rodado: comportamento descrito a partir do código.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [MesenCE src] | MesenCE, código-fonte, commit 4b8a196: `UI/Utilities/TestRunner.cs`, `UI/Utilities/CommandLineHelper.cs`, `Core/Debugger/LuaApi.cpp`, `Core/Shared/Emulator.cpp`, `UI/Debugger/Documentation/LuaDocumentation.json`, configuração SNES. https://github.com/nesdev-org/MesenCE | nesdev-org (fork comunitário do Mesen 2) | 2026 (07/10/2026) | Opções de linha de comando, test runner, timeout, código de saída, API Lua, enums, sandbox, opções de RAM inicial | Alta |
| [Mesen2 src] | Mesen 2, código-fonte (arquivado). https://github.com/SourMesen/Mesen2 | Sour | 2025 | Mesmos arquivos; confirma que o fork manteve a API | Alta |
| [SNESdev Tools] | SNESdev wiki, página "Tools". https://snes.nesdev.org/wiki/Tools | comunidade nesdev | 2026 (consulta) | Avaliação do Mesen como o mais preciso e dos debuggers | Média |
| [bsnes] | README do bsnes. https://github.com/bsnes-emu/bsnes | byuu (Near) e mantenedores | 2026 (consulta) | Foco do projeto, coprocessadores em baixo nível | Média |
| [ares] | README do ares. https://github.com/ares-emulator/ares | ares team | 2026 (consulta) | Descendência do higan/bsnes, foco em precisão | Média |
| [snes9x] | Repositório oficial do snes9x. https://github.com/snes9xgit/snes9x | snes9x team | 2026 (consulta) | Projeto portátil e ativo | Média |
| [ZSNES wiki] | Emulation General Wiki, página "ZSNES". https://emulation.fandom.com/wiki/ZSNES | comunidade (wiki de fãs) | sem data | Velocidade sobre precisão, SuperFX, proibição no speedrun.com | Baixa |
| [sd2snes] | Repositório mrehkopf/sd2snes, árvore `verilog/`. https://github.com/mrehkopf/sd2snes | ikari_01 (mrehkopf) e colaboradores | 2026 | Núcleos de FPGA por chip | Alta para a lista de núcleos |
| [sd2snes CHANGELOG] | `CHANGELOG` do sd2snes, até v1.11.2. https://github.com/mrehkopf/sd2snes | ikari_01 e colaboradores | 2026 (v1.11.2) | SuperFX, SA-1, USB, save states e o limite em jogos com chip | Alta |
| [QUsb2snes] | Repositório do QUsb2snes. https://github.com/Skarsnik/QUsb2snes | Skarsnik | 2026 (consulta) | Servidor usb2snes no PC | Média |
| [EverDrive] | Loja dragonbox.de (https://dragonbox.de/en/everdrives/snes-super-everdrive-x6) e tópico de review no elotrolado.net | vários | sem data | Suporte a DSP e ausência de SA-1, SuperFX e S-DD1 | Baixa |

## Divergências registradas

| Ponto | O que cada fonte diz | O que vale e por quê |
|---|---|---|
| Função que encerra o teste | Texto de ajuda do Mesen: `emu.exit(...)`. API Lua e documentação embutida: só existe `emu.stop(exitCode)` | **`emu.stop`.** É a função registrada em `LuaApi.cpp`; `emu.exit` não existe e daria erro de script |
| Documentação do Mesen | mesen.ca/docs descreve a versão 0.9.9 de NES; o código do Mesen 2 e do MesenCE tem outra API | **Código do MesenCE**, a versão mantida |
| Precisão do bsnes atual | [bsnes] fala em desempenho, recursos e facilidade de uso; [ares] reivindica o foco em precisão da linha higan | Tratar bsnes e ares como segunda opinião; para precisão máxima declarada, ares. Mesen continua o principal pela avaliação do [SNESdev Tools] e pelo test runner |
| Por que não o ZSNES | Só a fonte de confiança baixa detalha os defeitos | Mantido como recomendação, mas apoiado no fato de existirem alternativas precisas e ativas, não só na wiki de fãs |

## Não confirmado ou fora do escopo

- Se a saída de `print` aparece no terminal do Windows quando o Mesen roda como aplicativo gráfico.
- A opção `--debug.scriptWindow.allowIoOsAccess=true` (deduzida do código, não testada).
- Tempo real que o test runner leva por quadro em velocidade máxima.
- Nome do executável do MesenCE em cada sistema.
- Ausência de suporte a SPC7110 no FXPAK (deduzida da falta de núcleo na árvore).
- Operações de leitura de memória do usb2snes / QUsb2snes.
- Precisão do snes9x em relação a Mesen e bsnes.
- Teste automatizado em bsnes, ares ou snes9x.
- no$sns e outros flash carts além de FXPAK e EverDrive.
