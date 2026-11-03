# Chips de cartucho: registradores e mapa essenciais

O que a CPU principal enxerga de cada coprocessador: onde ficam as portas, o que é preciso escrever para ligar o chip e como o header o identifica. Não cobre o conjunto de instruções interno de cada chip. Para o que cada chip resolvia nos jogos, ver `snes-tecnicas/references/chips-especiais.md`.

Fontes: [fullsnes] e o código do [Mesen2] e do [bsnes] (arquivos citados em cada seção). Endereços em hexadecimal; `00-3F/80-BF` quer dizer os dois grupos de bancos.

## Como o header identifica o chip

O byte `$FFD6` (tipo de cartucho) diz se há coprocessador: quando o nibble baixo vale 3 ou mais, o nibble alto escolhe o chip [fullsnes] [Mesen2: `BaseCartridge.cpp`, `GetCoprocessorType`].

| Nibble alto de $FFD6 | Chip |
|---|---|
| 0 | DSP-n |
| 1 | GSU (Super FX) |
| 2 | OBC1 |
| 3 | SA-1 |
| 4 | S-DD1 |
| 5 | S-RTC |
| F | Decidido por `$FFBF`: `$00` = SPC7110, `$01` = ST010/011, `$02` = ST018, `$10` = CX4 |

`$FFD5` (modo de mapa) também muda: SA-1 usa `$23`, GSU usa `$20`, S-DD1 e SPC7110 usam valores de HiROM rápido [fullsnes].

## SA-1

Segundo 65C816 a 10,74 MHz dentro do cartucho [fullsnes: SA-1].

**Mapa (lado SNES):**

| Endereço | O que é |
|---|---|
| 00-3F/80-BF:2200-23FF | Portas de I/O |
| 00-3F/80-BF:3000-37FF | I-RAM (2K, interna, rápida) |
| 00-3F/80-BF:6000-7FFF | Um bloco de 8K da BW-RAM, escolhido em `$2224` |
| 00-3F/80-BF:8000-FFFF | ROM em LoROM, quatro blocos de 1 MB escolhidos em `$2220-$2223` |
| 40-4F | BW-RAM inteira |
| C0-FF | ROM em HiROM, os mesmos quatro blocos de 1 MB |

O lado SA-1 vê o mesmo mapa (sem WRAM e sem as portas do SNES), mais a I-RAM também em `0000-07FF` [fullsnes: SA-1].

**Registradores essenciais (escrita):**

| Porta | Nome | Uso |
|---|---|---|
| $2200 | CCNT | Controle do SA-1 pelo SNES. Vale `$20` no reset (bit 5 = SA-1 parado); escrever `$00` solta o SA-1 |
| $2203/04 | CRV | Vetor de reset do SA-1 (escrever antes de soltar) |
| $2205/06, $2207/08 | CNV, CIV | Vetores de NMI e IRQ do SA-1 |
| $2220-$2223 | CXB-FXB | Bloco de 1 MB de cada faixa de ROM (reset 0, 1, 2, 3) |
| $2224 | BMAPS | Bloco da BW-RAM em 6000-7FFF para o SNES |
| $2226 | SBWE | Libera escrita do SNES na BW-RAM |
| $2229 | SIWP | Proteção da I-RAM para o SNES: 1 bit por bloco de 256 bytes, 1 = libera escrita. Reset `$00` |
| $222A | CIWP | O mesmo para o SA-1. Reset `$00` |
| $2250 | MCNT | Matemática: 0 = multiplicação com sinal, 1 = divisão, 2 = multiplicação com soma acumulada |
| $2251/52, $2253/54 | MA, MB | Operandos; escrever `$2254` dispara a conta |
| $2306-$230A | MR (leitura) | Resultado |

Registradores e resets conferidos em [fullsnes: SA-1 I/O Map] e no [bsnes: `sfc/coprocessor/sa1/io.cpp`], que comenta que o CIWP vai a 0 no reset. A checagem de proteção por bloco de 256 bytes está em [bsnes: `sa1/iram.cpp`] e [Mesen2: `Sa1IRamHandler.h`].

**Armadilha:** com SIWP e CIWP zerados, nem o SNES nem o SA-1 escrevem na I-RAM. Libere antes de usar.

**Teste local** (MesenCE 2.2.1, ROM própria de 256K com header `$23`/`$34`) [Teste local]: o SNES escreve CRV e `$00` em CCNT; o SA-1 grava `$FF` em CIWP, faz `$1234 × $FFF0` em MCNT = 0 e copia o resultado para a I-RAM. O SNES leu `$FFFEDCC0` (= `$1234 × -16`) já no primeiro quadro. Sem a escrita em CIWP o SNES ficou esperando para sempre: a escrita do SA-1 na I-RAM foi ignorada, o que confirma a proteção ligada no reset.

## GSU (Super FX)

Processador RISC de 16 bits que desenha num bitmap da RAM do cartucho [fullsnes: GSU].

**Mapa (lado SNES, GSU1 e GSU2):** I/O em `00-3F/80-BF:3000-34FF` (registradores em 3000-303F, cache de código em 3100-32FF); ROM em LoROM em `00-3F:8000-FFFF` e em HiROM em `40-5F`; RAM do cartucho em `70-71`, com os primeiros 8K espelhados em `00-3F:6000-7FFF` [fullsnes: GSU Memory Map]. O header declara LoROM (`$FFD5` = `$20`), `$FFD6` entre `$13` e `$1A`, tamanho da RAM em `$FFBD` [fullsnes] [Mesen2: `BaseCartridge.cpp`].

| Porta | Nome | Uso |
|---|---|---|
| $3000-$301F | R0-R15 | Registradores do GSU; escrever o byte alto de R15 (`$301F`) dá a partida no endereço de R15 |
| $3030/31 | SFR | Status; bit 5 = GO (rodando), zerado no STOP; escrever 0 no GO para o GSU |
| $3034 | PBR | Banco do código |
| $3036 | ROMBR | Banco de leitura de ROM |
| $3037 | CFGR | Configuração (máscara de IRQ, multiplicador rápido) |
| $3038 | SCBR | Base da tela no RAM (em unidades de 1K) |
| $3039 | CLSR | Relógio: 0 = 10,7 MHz, 1 = 21,4 MHz |
| $303A | SCMR | Modo da tela: bits 0-1 cores, bits 2 e 5 altura, bit 3 RAN (GSU dono da RAM), bit 4 RON (GSU dono da ROM) |
| $303B | VCR | Versão do chip (leitura) |
| $303C | RAMBR | Banco da RAM |

Conferido em [fullsnes: GSU I/O Map] e [Mesen2: `Gsu.cpp`] / [bsnes: `sfc/coprocessor/superfx/io.cpp`].

**Armadilhas:**

- Com GO e RON ligados, a ROM sai do barramento do SNES: os vetores lidos pela CPU viram valores fixos que apontam para `$01xx`, então os handlers de NMI e IRQ precisam estar na WRAM nesse período [fullsnes: GSU Memory Map].
- Enquanto o GSU roda, só SFR, SCMR e VCR são acessíveis pelo SNES; o [Mesen2] ignora outras escritas nesse período.
- Divergência: o [fullsnes] cita VCR = 1 no primeiro modelo; o [Mesen2] devolve 4 (GSU2). Não confie em VCR para detectar o chip.

## CX4 (Hitachi HG51B169)

**Mapa:** registradores e RAM de 3K em `00-3F/80-BF:6000-7FFF`; RAM em 6000-6BFF, registradores de controle em 7F40-7FAF e 7FC0-7FEF [fullsnes: CX4] [bsnes: `sfc/coprocessor/hitachidsp/memory.cpp`]. Header: `$FFD6` = `$F3`, `$FFBF` = `$10` [Mesen2: `BaseCartridge.cpp`].

| Porta | Uso |
|---|---|
| 7F40-7F42 | Origem do DMA interno |
| 7F43-7F44 | Tamanho do DMA |
| 7F45-7F47 | Destino do DMA; escrever 7F47 dispara a cópia [fullsnes] [bsnes] |
| 7F49-7F4B | Base do programa na ROM |
| 7F4D-7F4E | Página do programa |
| 7F4F | Contador de programa; escrever dá a partida |
| 7F5E | Status (leitura) |
| 7F60-7F7F | Vetores |
| 7F80-7FAF | Registradores de uso geral |

Divergência no status `7F5E`: o [fullsnes] diz bit 6 = ocupado; o [bsnes: `hitachidsp/memory.cpp`] e o [Mesen2: `Cx4.cpp`] usam bit 6 = rodando e bit 7 = ocupado (DMA ou cache). Vale a leitura dos dois emuladores; para esperar, teste os dois bits.

## DSP-n (NEC uPD77C25), ST010 e ST011

DSP de ponto fixo com programa em ROM interna. A CPU fala com ele por dois registradores: **DR** (dado, 8 ou 16 bits) e **SR** (status, só leitura). No SR, bit 15 = RQM (o DSP está pronto para trocar um byte), bit 12 = DRS e bit 10 = DRC (largura) [fullsnes: DSP-n] [Mesen2: `NecDsp.cpp`].

| Placa | DR | SR |
|---|---|---|
| LoROM até 1 MB | 30-3F/B0-BF:8000-BFFF | 30-3F/B0-BF:C000-FFFF (bit A14) |
| LoROM 2 MB | 60-6F/E0-EF:0000-3FFF | 60-6F/E0-EF:4000-7FFF |
| HiROM | 00-1F/80-9F:6000-6FFF | 00-1F/80-9F:7000-7FFF (bit A12) |
| ST010/ST011 | 60:0000 | 60:0001; RAM do chip em 68-6F:0000-0FFF |

Header: `$FFD6` = `$03` a `$05` (DSP-n); ST010/011 usam nibble alto F em `$FFD6` e `$FFBF` = `$01` [fullsnes] [Mesen2: `BaseCartridge.cpp`]. Receita: esperar RQM = 1 em SR antes de cada leitura ou escrita em DR.

Sem teste local: o Mesen exige o firmware do chip (`dsp1.rom` etc.), que é da Nintendo e não entra neste repositório.

## S-DD1

Descompressor que age durante o DMA: um DMA lendo da ROM devolve os dados já descomprimidos [fullsnes: S-DD1] [Mesen2: `Sdd1.cpp`].

| Porta | Uso |
|---|---|
| $4800 | Liga a descompressão por canal de DMA (bit n = canal n); fica como está |
| $4801 | Liga para o próximo DMA; zera sozinho depois dele |
| $4804-$4807 | Bloco de 1 MB da ROM mapeado em C0-CF, D0-DF, E0-EF e F0-FF |

ROM em HiROM nos bancos C0-FF pelos blocos acima; vetores e header em LoROM no banco 00 [fullsnes]. O [Mesen2] observa as escritas em `$43xx` para saber origem e tamanho do DMA [Mesen2: `Sdd1.cpp`]; o [bsnes: `sfc/coprocessor/sdd1/sdd1.cpp`] faz o mesmo.

## SPC7110

Descompressor, unidade de multiplicação e divisão e acesso direto à ROM de dados, com portas em `$4800-$4842` [fullsnes: SPC7110] [Mesen2: `Spc7110.cpp`] [bsnes: `sfc/coprocessor/spc7110/`].

| Faixa | Uso |
|---|---|
| $4800-$480C | Descompressão: 4800 lê o próximo byte, 4801-4803 base do diretório, 4804 índice, 4809-480A tamanho, 480C status (bit 7 = pronto) |
| $4810-$481A | Leitura direta da ROM de dados com ponteiro e incremento |
| $4820-$482F | Multiplicação (dispara ao escrever 4825) e divisão (dispara em 4827); resultado em 4828-482B, resto em 482C-482D, 482F bit 7 = ocupado |
| $4830 | Liga a SRAM |
| $4831-$4833 | Bloco de 1 MB da ROM de dados em D0, E0 e F0 (reset 0, 1, 2) |

ROM de programa em C0-CF, SRAM em 00-3F:6000-7FFF [fullsnes]. O [Mesen2] também mapeia leituras do banco `$50` para a porta 4800 e do banco `$58` para 4808. ROMs de 3 MB e 5 MB têm checksum fora do padrão [fullsnes]. O FXPAK não roda SPC7110 (ver `snes-testes`).

## Sem teste local

Só o SA-1 foi rodado. GSU e CX4 exigiriam programa próprio no conjunto de instruções do chip (o Mesen já traz embutida a ROM de dados do CX4); S-DD1 e SPC7110 exigiriam dados comprimidos próprios; o DSP-n depende do firmware da Nintendo. Os mapas acima vêm de [fullsnes] conferido no código de dois emuladores.
