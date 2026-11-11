# Ferramentas de desmontagem

Resumo do que cada ferramenta faz, conferido no código ou no README do projeto em 26/10/2026 e revisado em 02/11/2026. Na v0.1 nada foi executado; na v0.2 o CDL do Mesen e o Capstone foram rodados contra uma ROM própria montada no asar (marcado [Teste local]). O resto vem da fonte, não de teste.

## Mesen 2 e MesenCE

O repositório SourMesen/Mesen2 foi arquivado (última versão por volta da 2.1.1, em 2025) e o desenvolvimento segue no fork comunitário **MesenCE**, em nesdev-org/MesenCE [Mesen2 src][MesenCE src]. A documentação em mesen.ca/docs é da versão antiga, só de NES (0.9.9), então nomes de menu e de opção aqui vêm do código.

O SNESdev wiki descreve o Mesen como em desenvolvimento ativo, com debugger completo e provavelmente o emulador mais preciso disponível hoje [SNESdev Tools].

Recursos do debugger que importam pra desmontagem [MesenCE src]:

- **Code/Data Logger**: menu com Reset, Load, Save (`.cdl`) e "Generate ROM" (gera uma ROM só com o que foi usado ou só com o que não foi). Detalhe em [codigo-e-dados.md](codigo-e-dados.md).
- **Trace logger**: formato configurável por tags (`[PC]`, `[ByteCode]`, `[Disassembly]`, `[EffectiveAddress]`, `[MemoryValue]`, registradores, `[Scanline]`, `[FrameCount]` e outras) e log condicional.
- **Memory Search**: busca comparando com o valor anterior, com um valor fixo ou com outro endereço, com os operadores igual, diferente, menor, maior, menor ou igual e maior ou igual, em byte, word ou dword. A lista mostra contagem de leitura, escrita e execução e o último acesso de cada endereço.
- **Breakpoints**: tipos Execute, Read, Write e Forbid, com condição. Opções de parada específicas do SNES: leitura de memória não inicializada, `BRK`, `COP`, `WDM`, `STP`, acesso inválido ao PPU e leitura durante o auto-joypad.
- **Labels**: importa `.mlb`, `.sym` (inclusive o formato do WLA-DX), `.dbg` do ca65, `.fns`, `.elf` e `.cdb`; exporta `.mlb`. Formato em [organizacao-de-projetos.md](organizacao-de-projetos.md).
- **Tabela de caracteres**: carrega `.tbl` no visualizador de memória, só com entradas simples.
- **Lua**: callbacks de leitura, escrita e execução, leitura de memória sem efeito colateral, CDL acessível por `emu.getCdlData`. A API completa está na skill `snes-testes`.

## bsnes-plus

Fork do bsnes com foco em depuração, de devinacker, licença GPLv2, último push em 22/03/2025 [bsnes-plus]. Pontos fortes segundo o README:

- O editor de memória destaca em tempo real o que foi executado ou lido como dado, e permite procurar regiões conhecidas e regiões ainda não exploradas.
- Breakpoints espelhados por todo o espaço de endereços (um breakpoint em um espelho pega os outros).
- Desmontagem de SA-1 e SuperFX, além da CPU principal.
- Lê arquivos de símbolos do WLA-DX, do FMA e labels no formato do VICE.
- O tracer tem uma "trace mask" que registra cada endereço só uma vez, bom para trace longo sem repetição.

## DiztinGUIsh

Desmontador interativo para SNES, criado por IsoFrieze; o repositório hoje fica em DizTools/DiztinGUIsh (o endereço antigo redireciona) [DiztinGUIsh][DiztinGUIsh src]. É o mais citado pelos projetos de desmontagem (o jpdasm credita o DiztinGUIsh) [jpdasm].

- Acompanha as flags M e X, o Data Bank e o Direct Page de cada instrução, com avanço manual ou automático.
- Permite marcar bytes como tipos de dado e dar labels e comentários.
- Importa trace log do BSNES e do BizHawk, usage map do BSNES e CDL do BizHawk, e captura trace em tempo real de um build próprio do BSNES por socket.
- Projeto salvo em XML pensado para merge em git; tem um visualizador da ROM por cobertura.
- Exporta assembly que monta no asar.

### CDL do Mesen no DiztinGUIsh: não importa direto

Conferido no código do DiztinGUIsh (commit 7484b87, 09/08/2026) [DiztinGUIsh src]: os importadores são só três, CDL do BizHawk, usage map do BSNES e trace log do BSNES, além de labels em CSV. Não há leitor do formato do Mesen, e os dois arquivos são incompatíveis:

| | CDL do BizHawk (o que o DiztinGUIsh lê) | CDL do Mesen |
|---|---|---|
| Cabeçalho | Strings com prefixo de tamanho: `BIZHAWK-CDL-2`, depois o sistema `SNES`, depois blocos com nome (o importador usa o bloco `CARTROM`) | Texto `CDLv2` e CRC32 da ROM, 9 bytes no total |
| Opcode e operando | Flags separadas: `0x01` primeiro byte executado, `0x02` byte de operando | Uma flag só, `0x01` código, para todos os bytes da instrução |
| M e X | `0x20` M=1 e `0x10` X=1, lidos só no primeiro byte | Mesmos bits, `0x20` e `0x10`, gravados em todos os bytes |
| Dado | `0x04` lido pela CPU, `0x08` lido por DMA | `0x02` dado |

Fontes da tabela: importador do BizHawk no DiztinGUIsh [DiztinGUIsh src] e `CodeDataLogger` e `SnesDebugger` do MesenCE [MesenCE src]. Que o Mesen marca operando com a mesma flag do opcode foi conferido rodando [Teste local]: num `LDA #$1234` com M=0 os três bytes vieram `0x01`, e depois de `SEP #$20` os dois bytes de `LDA #$12` vieram `0x21`.

Caminhos que funcionam:

1. **Usar a fonte que o DiztinGUIsh já lê**: usage map ou trace do bsnes-plus, ou CDL do BizHawk.
2. **Converter por script**: ler o `.cdl` do Mesen (ou `emu.getCdlData` no Lua) e gerar o formato do BizHawk. Como o Mesen não separa opcode de operando, o script precisa decodificar o tamanho de cada instrução a partir do primeiro byte de cada trecho de código, com o M e o X gravados; é o mesmo laço do exemplo do Capstone abaixo. O script `cdl_mesen_para_bizhawk.py` faz isso, com testes automatizados em arquivos sintéticos; uso e limites em [codigo-e-dados.md](codigo-e-dados.md). A importação do arquivo gerado no DiztinGUIsh ainda não foi feita na interface (não confirmado).

No repositório há um pedido aberto de suporte a CDL do Mesen 2, só para NES (issue 127, de 06/01/2026), e a PR 134, aberta em 24/09/2026, renomeia a captura ao vivo "em antecipação à integração com o Mesen" [DiztinGUIsh src]. Ou seja, é plano, não recurso lançado.

## Ghidra com 65816

- **ghidra-65816** (achan1989, MIT, sem manutenção): adiciona o processador 65816. As flags M, X e E são definidas em "Processor Options...", e DBR, DP e PBR em "Set Register Values...". Limites declarados no README: `PLP` e `RTI` não atualizam o modo, a virada de banco está errada, os vetores não viram pontos de entrada e a descompilação não é utilizável [ghidra-65816].
- **ghidra-snes-loader** (achan1989, sem manutenção): carregador de ROM SNES para o plugin acima [ghidra-65816].
- **ghidra-snes** (joshleaves, MIT, ativo, push em 28/05/2026): carregador derivado do ghidra-65816 com LoROM, HiROM, ExHiROM, SA-1, GSU, Cx4, DSP e OBC1 (S-DD1 e SPC7110 parciais), linguagem `65816:LE:24:snes` e labels de MMIO e de vetores [ghidra-snes].

Use o Ghidra para navegar referências cruzadas e anotar; para gerar assembly reassemblável, as desmontagens conhecidas usam DiztinGUIsh ou ferramenta própria [jpdasm][SMWDisX].

## Desmontadores de linha de comando

Os específicos de SNES são pequenos e com pouca adoção (dados do GitHub em 02/11/2026) [PJBoy disasm][disperry][specter][gilgamesh]:

| Projeto | Linguagem | Último push | Observação |
|---|---|---|---|
| PJBoy/snes-disassembler | C++ | 16/03/2020 | Sem release; precisa compilar |
| boldowa/disperry | C++ | 26/08/2017 | Front-end do Dispel; release só com zip de binário |
| retroscribe/specter | Go | 26/01/2026 | Precisa do Go para compilar |
| AndreaOrru/gilgamesh | C++ | 26/09/2021 | Kit de engenharia reversa com recompilação estática |

Nenhum desses foi rodado: a máquina do teste não tem compilador de C++ nem Go, e o único binário pronto (zip do disperry, de 2017, sem estrelas) não foi baixado por precaução.

### Capstone: avaliado de verdade

O Capstone é um motor de desmontagem multiarquitetura com pacote oficial no PyPI (`pip install capstone`). A arquitetura `CS_ARCH_MOS65XX` inclui o 65816 [Capstone]. Rodado na versão 5.0.7 contra uma ROM própria de 32 KB montada no asar 1.91, com `REP`, `SEP`, `JSR`, `BRA` e uma tabela logo depois do `RTS` [Teste local]:

- **O modo é fixo por instância.** Há modos para M e X de 16 bits (`..._65816_LONG_M`, `..._LONG_X`, `..._LONG_MX`) e o tamanho do imediato depende só do modo escolhido; o código do Capstone não acompanha `REP` nem `SEP` [Capstone]. Desmontando tudo em `LONG_MX`, o `LDA #$12` depois de `SEP #$20` saiu como `lda #$2012` e o `JSR` seguinte virou `ora [$80],y` [Teste local].
- **O modo de M e X em 8 bits é recusado na 5.0.7.** `CS_MODE_MOS65XX_65816` dá `CS_ERR_MODE` na criação e `CS_ERR_OPTION` na troca de modo, porque a máscara de modos válidos em `cs.c` não inclui esse bit [Capstone][Teste local]. Contorno: cada imediato depende só de M ou só de X, então com M=1 e X=1 use `LONG_M` nos imediatos de índice (`LDX`, `LDY`, `CPX`, `CPY`) e `LONG_X` no resto.
- **Dado vira código.** O byte `$EA` da tabela saiu como `nop`.
- Hexadecimal sai como `0x` por padrão; `syntax = CS_OPT_SYNTAX_MOTOROLA` troca para `$`.

Combinado com o CDL do Mesen, o resultado ficou certo: um script que lê as flags de cada trecho de código, escolhe o modo pelo M e X gravados no primeiro byte, avança pelo tamanho da instrução e escreve `db` nos bytes marcados como dado reproduziu a rotina inteira sem erro [Teste local]. É uma boa base para script; para gerar fonte que reassembla, o DiztinGUIsh continua mais completo, porque também guarda DB, D e labels.

O problema comum a todos os desmontadores de linha de comando é o da regra de ouro 1: sem trace ou CDL, eles precisam adivinhar M e X.

## Qual usar

| Tarefa | Ferramenta |
|---|---|
| Achar variável e rotina, breakpoint, trace | Mesen (ou bsnes-plus) |
| Registrar código e dado jogando | CDL do Mesen ou usage map do bsnes-plus |
| Produzir assembly que reassembla | DiztinGUIsh |
| Navegar referências cruzadas num jogo grande | Ghidra com ghidra-snes |
| Automatizar por script | Lua do Mesen (skill `snes-testes`); Capstone guiado pelo CDL para desmontar |

Escolha por função descrita nas fontes acima; só o Capstone e o CDL do Mesen foram testados, não houve comparação entre ferramentas.
