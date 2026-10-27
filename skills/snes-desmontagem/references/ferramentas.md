# Ferramentas de desmontagem

Resumo do que cada ferramenta faz, conferido no código ou no README do projeto em 26/10/2026. Nenhum executável foi rodado nesta pesquisa: comportamento descrito vem da fonte, não de teste.

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

Desmontador interativo para SNES, de IsoFrieze [DiztinGUIsh]. É o mais citado pelos projetos de desmontagem (o jpdasm credita o DiztinGUIsh) [jpdasm].

- Acompanha as flags M e X, o Data Bank e o Direct Page de cada instrução, com avanço manual ou automático.
- Permite marcar bytes como tipos de dado e dar labels e comentários.
- Importa trace log do BSNES e do BizHawk, usage map do BSNES e CDL do BizHawk, e captura trace em tempo real de um build próprio do BSNES por socket.
- Projeto salvo em XML pensado para merge em git; tem um visualizador da ROM por cobertura.
- Exporta assembly que monta no asar.

A lista de formatos de importação acima é a do README; importação direta do CDL do Mesen não aparece lá (não confirmado).

## Ghidra com 65816

- **ghidra-65816** (achan1989, MIT, sem manutenção): adiciona o processador 65816. As flags M, X e E são definidas em "Processor Options...", e DBR, DP e PBR em "Set Register Values...". Limites declarados no README: `PLP` e `RTI` não atualizam o modo, a virada de banco está errada, os vetores não viram pontos de entrada e a descompilação não é utilizável [ghidra-65816].
- **ghidra-snes-loader** (achan1989, sem manutenção): carregador de ROM SNES para o plugin acima [ghidra-65816].
- **ghidra-snes** (joshleaves, MIT, ativo, push em 28/05/2026): carregador derivado do ghidra-65816 com LoROM, HiROM, ExHiROM, SA-1, GSU, Cx4, DSP e OBC1 (S-DD1 e SPC7110 parciais), linguagem `65816:LE:24:snes` e labels de MMIO e de vetores [ghidra-snes].

Use o Ghidra para navegar referências cruzadas e anotar; para gerar assembly reassemblável, as desmontagens conhecidas usam DiztinGUIsh ou ferramenta própria [jpdasm][SMWDisX].

## Desmontadores de linha de comando

Existem vários, todos pequenos e com pouca adoção, por isso entram aqui só como opção para script, sem recomendação [PJBoy disasm][disperry][specter][gilgamesh]:

- **PJBoy/snes-disassembler**.
- **boldowa/disperry**: front-end para o Dispel.
- **retroscribe/specter**: escrito em Go.
- **AndreaOrru/gilgamesh**: kit de engenharia reversa com recompilação estática.

O problema comum a todos é o mesmo da regra de ouro 1: sem trace ou CDL, eles precisam adivinhar M e X.

## Qual usar

| Tarefa | Ferramenta |
|---|---|
| Achar variável e rotina, breakpoint, trace | Mesen (ou bsnes-plus) |
| Registrar código e dado jogando | CDL do Mesen ou usage map do bsnes-plus |
| Produzir assembly que reassembla | DiztinGUIsh |
| Navegar referências cruzadas num jogo grande | Ghidra com ghidra-snes |
| Automatizar por script | Lua do Mesen (skill `snes-testes`) |

Escolha por função descrita nas fontes acima, não por teste comparativo.
