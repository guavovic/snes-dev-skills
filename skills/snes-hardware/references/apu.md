# APU: SPC700, DSP e portas $2140-$2143 (visão geral)

O som é um subsistema separado, com processador, RAM e relógio próprios. A CPU principal só conversa com ele por 4 portas de 8 bits [fullsnes: APU] [SNESdev wiki: Booting the SPC700]. A programação do driver de som fica para uma skill própria; aqui vai o que a CPU principal precisa saber.

## Componentes

- **SPC700** (Sony): CPU de 8 bits a ~1,024 MHz, registradores A, X, Y, SP, PSW e o par YA de 16 bits [fullsnes].
- **S-DSP**: 8 vozes de samples comprimidos em BRR, envelope ADSR ou GAIN, eco com filtro FIR de 8 taps, ruído e modulação de pitch; saída a 32 kHz [fullsnes] [SNESdev wiki].
- **Sound RAM (ARAM)**: 64K, compartilhada entre o código do SPC700, os samples e o buffer de eco.
- Oscilador de 24,576 MHz. O [SNESdev wiki] observa que a taxa real do DAC varia de console para console, entre cerca de 32000 e 32160 Hz.

## Mapa de memória do SPC700

| Faixa | Uso |
|---|---|
| $0000-$00EF | RAM (direct page 0) |
| $00F0-$00FF | Registradores de I/O |
| $0100-$01FF | RAM (stack) |
| $0200-$FFBF | RAM |
| $FFC0-$FFFF | Boot ROM de 64 bytes (IPL) ou RAM, conforme $F1 bit7 |

Registradores de I/O [fullsnes]:

| End. | Nome | Função |
|---|---|---|
| $F0 | TEST | Teste; não mexer |
| $F1 | CONTROL | bits 2-0: liga os timers 0-2; bit4: zera as entradas $F4/$F5; bit5: zera $F6/$F7; bit7: IPL ROM em $FFC0 (escrita vai sempre para a RAM). Valor no reset: $B0 |
| $F2 | DSPADDR | Índice do registrador do DSP |
| $F3 | DSPDATA | Lê ou escreve o registrador do DSP indicado |
| $F4-$F7 | CPUIO0-3 | As portas do lado do SPC700 (= $2140-$2143 do lado da CPU) |
| $FA-$FC | T0DIV-T2DIV | Divisores dos timers 0, 1 (8 kHz) e 2 (64 kHz) |
| $FD-$FF | T0OUT-T2OUT | Contadores dos timers, 4 bits, zeram na leitura |

## Registradores do DSP (resumo)

128 índices. Por voz (x = 0-7, índice `$x0-$x9`): VOL esquerdo e direito, PITCH (14 bits, em $x2/$x3), SRCN (número do sample no diretório), ADSR1/ADSR2, GAIN, ENVX e OUTX (leitura). Globais: MVOL e EVOL (volumes mestre e de eco), KON e KOFF (liga e desliga notas), FLG (reset, mudo, eco, frequência do ruído), ENDX, EFB (feedback do eco), PMON, NON, EON, DIR (página do diretório de samples), ESA e EDL (endereço e tamanho do eco) e os 8 coeficientes FIR [fullsnes] [SNESdev wiki].

## Portas do lado da CPU

| Reg. | Função |
|---|---|
| $2140-$2143 | APUIO0-3. Escrever envia um byte para o SPC700 ler em $F4-$F7; ler devolve o que o SPC700 escreveu nas mesmas portas |

- São 8 portas físicas: 4 em cada direção. Escrever em $2140 não muda o que se lê em $2140 [fullsnes].
- As portas se espelham em $2144-$217F [fullsnes].
- **Escreva em 8 bits.** O [fullsnes] alerta para um glitch de hardware em que uma escrita de 16 bits em $2140/$2141 pode destruir $2143, em situações como cartucho com muita carga no barramento.
- Ler enquanto o outro lado escreve pode devolver uma mistura (OR) do valor velho com o novo; protocolos sérios leem duas vezes ou usam eco [fullsnes].
- Não há interrupção entre as duas CPUs: a comunicação é por polling.
- O DMA da CPU não alcança a ARAM. Tudo passa pelas portas, byte a byte (ou com DMA para as portas, se o driver do SPC700 acompanhar).

## Protocolo de upload da IPL

No reset, o SPC700 roda a boot ROM, que espera um programa pela porta. O protocolo, descrito em [fullsnes] e [SNESdev wiki: Booting the SPC700], é:

1. Esperar ler `$AA` em $2140 e `$BB` em $2141 (sinal de pronto).
2. Escrever o endereço de destino em $2142/$2143, um valor não zero em $2141 ("vem dado"), e `$CC` em $2140. Esperar $2140 ecoar `$CC`.
3. Para cada byte: dado em $2141, índice do byte (8 bits baixos, começando em 0) em $2140. Esperar $2140 ecoar o índice.
4. Para começar outro bloco: novo endereço em $2142/3, valor não zero em $2141 e, em $2140, um valor pelo menos 2 acima do último índice (e diferente de zero). Esperar o eco.
5. Para executar: endereço de entrada em $2142/3, `$00` em $2141 e o mesmo tipo de "chute" em $2140. Esperar o eco; o SPC700 salta para o endereço. É comum carregar e rodar a partir de `$0200`.

Cuidados:

- O eco do último byte é breve: desligue NMI e IRQ durante o upload para não perdê-lo [fullsnes].
- O código interno da boot ROM é da Nintendo; esta skill descreve só o protocolo e não reproduz o código.

## Armadilhas

- Supor que o SPC700 respondeu sem esperar o eco: as duas CPUs rodam em relógios independentes.
- Usar a porta de saída como confirmação sem cuidar do caso de leitura no meio da escrita.
- Esquecer que a área do eco ocupa ARAM (EDL × 2K bytes, até 30K; EDL = 0 ainda usa 4 bytes) [fullsnes] e pode sobrescrever samples ou código se ESA estiver mal posicionado.
