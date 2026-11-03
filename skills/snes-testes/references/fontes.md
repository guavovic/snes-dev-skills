# Fontes da skill snes-testes

Consultadas em 26/10/2026; revisão da v0.2 em 02/11/2026. Nível de confiança: **alta** = código-fonte ou documento do próprio projeto, ou execução própria; **média** = README ou wiki sem conferência no código; **baixa** = wiki de fãs, fórum ou loja, usada só com aviso. Até a v0.1 nenhum executável foi rodado; na v0.2 o que está marcado [Teste local] foi conferido em execução.

| Rótulo | Fonte | Autor | Ano | Cobre | Confiança |
|---|---|---|---|---|---|
| [MesenCE src] | MesenCE, código-fonte, commit 4b8a196: `UI/Utilities/TestRunner.cs`, `UI/Utilities/CommandLineHelper.cs`, `Core/Debugger/LuaApi.cpp`, `Core/Shared/Emulator.cpp`, `UI/Debugger/Documentation/LuaDocumentation.json`, configuração SNES; na v0.2 também `Core/Debugger/ScriptingContext.cpp`, `UI/Config/Debugger/ScriptWindowConfig.cs`, `UI/Config/Debugger/DebugConfig.cs`, `UI/Program.cs` e `UI/UI.csproj`. https://github.com/nesdev-org/MesenCE | nesdev-org (fork comunitário do Mesen 2) | 2026 (07/10/2026) | Opções de linha de comando, test runner, timeout, código de saída, API Lua, enums, sandbox, opções de RAM inicial | Alta |
| [Mesen2 src] | Mesen 2, código-fonte (arquivado). https://github.com/SourMesen/Mesen2 | Sour | 2025 | Mesmos arquivos; confirma que o fork manteve a API | Alta |
| [SNESdev Tools] | SNESdev wiki, página "Tools". https://snes.nesdev.org/wiki/Tools | comunidade nesdev | 2026 (consulta) | Avaliação do Mesen como o mais preciso e dos debuggers | Média |
| [bsnes] | README do bsnes. https://github.com/bsnes-emu/bsnes | byuu (Near) e mantenedores | 2026 (consulta) | Foco do projeto, coprocessadores em baixo nível | Média |
| [ares] | README do ares. https://github.com/ares-emulator/ares | ares team | 2026 (consulta) | Descendência do higan/bsnes, foco em precisão | Média |
| [snes9x] | Repositório oficial do snes9x. https://github.com/snes9xgit/snes9x | snes9x team | 2026 (consulta) | Projeto portátil e ativo | Média |
| [ZSNES wiki] | Emulation General Wiki, página "ZSNES". https://emulation.fandom.com/wiki/ZSNES | comunidade (wiki de fãs) | sem data | Velocidade sobre precisão, SuperFX, proibição no speedrun.com | Baixa |
| [sd2snes] | Repositório mrehkopf/sd2snes, árvore `verilog/`. https://github.com/mrehkopf/sd2snes | ikari_01 (mrehkopf) e colaboradores | 2026 | Núcleos de FPGA por chip | Alta para a lista de núcleos |
| [sd2snes CHANGELOG] | `CHANGELOG` do sd2snes, até v1.11.2. https://github.com/mrehkopf/sd2snes | ikari_01 e colaboradores | 2026 (v1.11.2) | SuperFX, SA-1, USB, save states e o limite em jogos com chip | Alta |
| [QUsb2snes] | Repositório do QUsb2snes; na v0.2, `docs/Protocol.md` e `core/usb2snes.h` no commit 49e15f1. https://github.com/Skarsnik/QUsb2snes | Skarsnik | 2026 (02/11/2026) | Servidor usb2snes no PC; porta, formato JSON, `GetAddress`, `PutAddress`, espaço de endereços, comandos de arquivo e controle, flags | Alta para o protocolo |
| [EverDrive] | Loja dragonbox.de (https://dragonbox.de/en/everdrives/snes-super-everdrive-x6) e tópico de review no elotrolado.net | vários | sem data | Suporte a DSP e ausência de SA-1, SuperFX e S-DD1; modelos antigos | Baixa |
| [Teste local] | Execução própria: MesenCE 2.2.1 (`Mesen.exe`) no Windows 11, ROM LoROM de 32 KB original montada com asar 1.91, scripts Lua de teste, PowerShell 5.1 | este repositório | 2026 (02/11/2026) | Saída do `print`, código de saída, timeout, `emu.exit`, `allowIoOsAccess`, chaves de `emu.getState()`, receita de teste, tempo por quadro | Alta para essa versão e máquina |
| [MesenCE releases] | Página da versão 2.2.1 do MesenCE e conteúdo dos zips de Windows, Linux x64 e macOS ARM64. https://github.com/nesdev-org/MesenCE/releases/tag/2.2.1 | nesdev-org | 2026 (05/06/2026) | Nome do executável em cada sistema | Alta |
| [sd2snes compat] | Página "Compatibility" do site oficial do sd2snes. https://sd2snes.de/blog/compatibility | ikari_01 (mrehkopf) | sem data (consulta 02/11/2026) | Jogos e chips incompatíveis: SPC7110, ST-011, ST-018; ressalvas de Sufami Turbo e BS-X | Alta |
| [krikzz X6] | Página oficial do Super EverDrive X6. https://krikzz.com/our-products/cartridges/super-everdrive-x6.html | krikzz | sem data (consulta 02/11/2026) | Chips suportados (DSP-1 a DSP-4), tamanho de ROM e de save RAM | Alta |
| [TASVideos SNES] | TASVideos, "SNES Accuracy Tests". https://tasvideos.org/EmulatorResources/SNESAccuracyTests | comunidade TASVideos | 2014 (última edição 27/10/2014) | Placar de testes de ROM por emulador: ZSNES, snes9x 1.43 a 1.53, higan v094, lsnes, BizHawk | Média, antiga |
| [NESdev fórum 2019] | Fórum do NESdev, tópico "The best emulator ? SNES9X ?" (arquivo). https://nesdev.nes.science/f12/t18991.xhtml | Kannagi, byuu e outros | 2019 | Medida de CPU e vblank de uma demo em vários emuladores; snes9x emula por instrução | Baixa |

## Divergências registradas

| Ponto | O que cada fonte diz | O que vale e por quê |
|---|---|---|
| Função que encerra o teste | Texto de ajuda do Mesen: `emu.exit(...)`. API Lua e documentação embutida: só existe `emu.stop(exitCode)` | **`emu.stop`.** É a função registrada em `LuaApi.cpp`; `emu.exit` não existe e daria erro de script |
| Documentação do Mesen | mesen.ca/docs descreve a versão 0.9.9 de NES; o código do Mesen 2 e do MesenCE tem outra API | **Código do MesenCE**, a versão mantida |
| Precisão do bsnes atual | [bsnes] fala em desempenho, recursos e facilidade de uso; [ares] reivindica o foco em precisão da linha higan | Tratar bsnes e ares como segunda opinião; para precisão máxima declarada, ares. Mesen continua o principal pela avaliação do [SNESdev Tools] e pelo test runner |
| Precisão do snes9x | [TASVideos SNES] (2014): snes9x 1.53 com 53 de 59, higan com 59. [NESdev fórum 2019]: numa demo, snes9x igual ao console e bsnes/Mesen-S um pouco diferentes | **Nenhuma ranqueia o snes9x atual.** Ele fica como teste de compatibilidade, não de aprovação; Mesen e bsnes/ares seguem como referência de precisão |
| Chips no EverDrive antigo | Lojas e fóruns: X5 sem chip nenhum, ou DSP-1 só com chip físico | **Não confirmado.** Só o X6 tem página oficial, com DSP-1 a DSP-4 [krikzz X6] |
| `fps` no `emu.getState()` | Código atual do MesenCE inclui `fps`; a 2.2.1 instalada não devolve essa chave | **As duas valem**: a chave entrou depois da 2.2.1. Por isso a skill manda não depender de chave de estado |
| Por que não o ZSNES | Só a fonte de confiança baixa detalha os defeitos | Mantido como recomendação, mas apoiado no fato de existirem alternativas precisas e ativas, não só na wiki de fãs |

## Não confirmado ou fora do escopo

- Comportamento do `--testRunner` no Linux e no macOS (só o nome do executável foi conferido) e o código -1 virando 255 no bash na prática.
- Chaves de `emu.getState()` com chip de cartucho (SA-1, SuperFX etc.): só ROM sem chip foi testada.
- Tempo por quadro com jogo de verdade: a medida (cerca de 6 vezes a velocidade real) foi com uma ROM trivial, numa máquina.
- Precisão do snes9x atual em relação a Mesen e bsnes: as comparações existentes são de 2014 e 2019.
- Chips suportados pelos Super EverDrive anteriores ao X6.
- Leitura de memória pelo usb2snes em hardware: só o protocolo documentado foi lido, nada foi rodado num FXPAK.
- Teste automatizado em bsnes, ares ou snes9x.
- no$sns e outros flash carts além de FXPAK e EverDrive.

Resolvido na v0.2 (antes não confirmado): saída do `print` no terminal do Windows, nome e efeito de `allowIoOsAccess`, nome do executável, chaves do `emu.getState()` no SNES, SPC7110 no FXPAK, operações de memória do usb2snes, chips do Super EverDrive X6.
