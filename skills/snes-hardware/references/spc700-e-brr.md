# SPC700 e BRR: registradores do DSP, formato BRR e driver mínimo

Complementa [apu.md](apu.md), que cobre as portas e o protocolo da IPL. Aqui fica o lado do SPC700: como ele fala com o DSP, o formato dos samples e um driver mínimo original testado no Mesen.

Fontes: [fullsnes: APU], [SNESdev wiki: S-DSP registers], [SNESdev wiki: BRR samples] e o código do DSP no [Mesen2] (`Core/SNES/DSP/DspVoice.cpp`) e no [bsnes] (`sfc/dsp/SPC_DSP.cpp`, o núcleo de som do blargg).

## Acesso ao DSP

O SPC700 não vê os registradores do DSP direto: escreve o número do registrador em `$F2` e lê ou escreve o valor em `$F3` [fullsnes] [SNESdev wiki: S-DSP registers]. São 128 registradores; cada voz `x` (0 a 7) ocupa `$x0-$x9`.

## Registradores por voz

| Reg. | Nome | Uso |
|---|---|---|
| $x0/$x1 | VOL L/R | Volume da voz em cada lado, com sinal |
| $x2/$x3 | PITCH | 14 bits. `$1000` toca o sample na taxa original (32000 Hz); máximo `$3FFF` |
| $x4 | SRCN | Número do sample no diretório |
| $x5 | ADSR1 | Bit 7 = 1 usa ADSR; bits 6-4 decay, 3-0 attack |
| $x6 | ADSR2 | Bits 7-5 nível de sustain, 4-0 taxa de sustain |
| $x7 | GAIN | Usado com ADSR1 bit 7 = 0. Bit 7 = 0: envelope fixo em (bits 6-0) × 16 |
| $x8 | ENVX | Leitura: envelope atual (7 bits altos) |
| $x9 | OUTX | Leitura: saída atual da voz (8 bits altos, com sinal) |

## Registradores globais

| Reg. | Nome | Uso |
|---|---|---|
| $0C/$1C | MVOL L/R | Volume geral |
| $2C/$3C | EVOL L/R | Volume do eco |
| $4C | KON | Bit n liga a voz n (key on) |
| $5C | KOFF | Bit n solta a voz n (release) |
| $6C | FLG | Bit 7 reset do DSP, 6 mudo, 5 desliga a escrita do eco, 4-0 relógio do ruído. Vale `$E0` no reset |
| $7C | ENDX | Bit n = a voz n passou por um bloco com bit de fim. Qualquer escrita zera |
| $0D | EFB | Realimentação do eco |
| $2D | PMON | Modulação de pitch pela voz anterior |
| $3D | NON | Voz toca ruído em vez do sample |
| $4D | EON | Voz entra no eco |
| $5D | DIR | Página do diretório de samples (endereço = valor × $100) |
| $6D | ESA | Página do buffer de eco |
| $7D | EDL | Atraso do eco, em blocos de 2K (16 ms) |
| $xF | FIR | 8 coeficientes do filtro do eco |

Conferido em [fullsnes] e [SNESdev wiki: S-DSP registers].

**Cuidados:**

- A IPL não mexe no FLG: depois do boot ele continua em `$E0` (mudo e com reset do DSP). Escreva `$20` para tocar com o eco desligado [fullsnes] [SNESdev wiki: S-DSP registers].
- KON e KOFF são lidos a cada dois samples (16 kHz). Com duas escritas seguidas mais rápidas que isso, em geral só a segunda vale; e KOFF ligado numa voz impede o KON dela, então zere o KOFF antes [fullsnes].
- Escreva ADSR2 ou GAIN antes de ADSR1, para a voz não usar um valor velho no meio da troca [SNESdev wiki: S-DSP registers].
- Com EDL = 0 o eco ainda escreve 4 bytes em ESA. Com a escrita do eco ligada, ESA precisa apontar para uma área livre [fullsnes].

## Diretório de samples

Em `DIR × $100` fica uma tabela de 4 bytes por sample: endereço de início (2 bytes) e endereço de volta do loop (2 bytes). O SRCN da voz é o índice nessa tabela [fullsnes] [SNESdev wiki: BRR samples].

## Formato BRR

Blocos de 9 bytes: 1 byte de cabeçalho e 8 bytes com 16 amostras de 4 bits, nibble alto primeiro [fullsnes] [SNESdev wiki: BRR samples].

Cabeçalho `SSSS FFLE`:

| Bits | Uso |
|---|---|
| 7-4 | Shift (0 a 12). Com 13 a 15 a amostra vale 0 ou -2048, conforme o sinal do nibble |
| 3-2 | Filtro (0 a 3) |
| 1 | Loop |
| 0 | Fim |

Cada nibble, com sinal (-8 a 7), vira `(nibble << shift) >> 1`. Depois entra o filtro, que soma uma fração das duas amostras anteriores (`p1` e `p2`):

| Filtro | Soma |
|---|---|
| 0 | Nada |
| 1 | p1 × 15/16 |
| 2 | p1 × 61/32 - p2 × 15/16 |
| 3 | p1 × 115/64 - p2 × 13/16 |

As fórmulas inteiras exatas (com os deslocamentos que o hardware usa) estão no [fullsnes] e batem com as do [Mesen2: `DspVoice.cpp`] e do [bsnes: `SPC_DSP.cpp`]. O resultado é limitado a 16 bits com sinal.

Fim do sample, pelos bits L e E do bloco: E = 1 e L = 1 volta ao endereço de loop do diretório e marca ENDX; E = 1 e L = 0 marca ENDX e solta a voz com envelope zerado; E = 0 segue para o próximo bloco [fullsnes] [SNESdev wiki: BRR samples].

**Regras práticas** [SNESdev wiki: BRR samples] [fullsnes]:

- O primeiro bloco e o bloco de volta do loop devem usar filtro 0, porque as amostras anteriores não são as do sample.
- Mantenha os valores entre cerca de -$3FFA e +$3FF8 para o filtro não estourar.
- Shift 12 é o maior válido; 13 a 15 dão o caso especial acima.

**Detalhe dos emuladores:** o [Mesen2] e o [bsnes] guardam no buffer da voz o valor já dobrado (`clamp16(s) * 2`), e dividem por 2 ao usar como p1 e p2. Quem lê o estado no depurador vê o dobro do valor da fórmula acima.

## Driver mínimo (testado)

Programa próprio enviado pela IPL a partir de `$0200` com o protocolo de [apu.md](apu.md). O bloco tem o diretório, o sample e o código, nessa ordem, e a execução começa em `spc_inicio`. O sample é uma onda quadrada feita à mão: um bloco com nibble 7 e outro com nibble -7, shift 11, filtro 0, e o segundo com fim e loop voltando ao primeiro. São 32 amostras por ciclo, cerca de 1000 Hz com PITCH `$1000`.

```asm
; dentro da ROM do SNES, logo depois do código 65816
spc_dados:
arch spc700
base $0200
diretorio:
    dw amostra,amostra      ; sample 0: início e loop
amostra:
    db $B0,$77,$77,$77,$77,$77,$77,$77,$77   ; shift 11, filtro 0, +7
    db $B3,$99,$99,$99,$99,$99,$99,$99,$99   ; fim + loop, -7
spc_inicio:
    mov x,#$00
.reg:
    mov a,tabela+x
    mov $F2,a
    inc x
    mov a,tabela+x
    mov $F3,a
    inc x
    cmp x,#tabela_fim-tabela
    bne .reg
.le:
    mov $F2,#$08            ; ENVX da voz 0 vai para a porta 0
    mov a,$F3
    mov $F4,a
    mov $F2,#$7C            ; ENDX vai para a porta 1
    mov a,$F3
    mov $F5,a
    bra .le

tabela:                     ; pares registrador, valor
    db $6C,$20              ; FLG: sem mudo, eco sem escrita
    db $0C,$7F,$1C,$7F      ; MVOL
    db $2C,$00,$3C,$00      ; EVOL
    db $2D,$00,$3D,$00,$4D,$00
    db $5D,$02              ; DIR = $0200
    db $00,$7F,$01,$7F      ; VOL da voz 0
    db $02,$00,$03,$10      ; PITCH = $1000
    db $04,$00              ; SRCN = 0
    db $07,$7F              ; GAIN fixo $7F (antes do ADSR1)
    db $05,$00              ; ADSR1 = 0: usa GAIN
    db $5C,$00              ; KOFF
    db $4C,$01              ; KON da voz 0 por último
tabela_fim:
base off
arch 65816
spc_fim:
```

O lado 65816 envia `spc_fim-spc_dados` bytes com destino `$0200` e manda executar em `spc_inicio` (passo 5 da IPL em [apu.md](apu.md)), com `ldx #spc_inicio : stx $2142`. O asar entende `arch spc700` dentro do mesmo arquivo; os rótulos dentro do `base $0200` ficam com o endereço da ARAM [manual do asar].

**Resultado no MesenCE 2.2.1** [Teste local], lido com `emu.getState()` 30 quadros depois do reset:

- Porta 0 (`$2140`) = `$7F` (ENVX) e porta 1 (`$2141`) = `$01` (ENDX da voz 0: o sample já passou pelo bloco de fim e voltou).
- `spc.dsp.voices[0].envVolume` = 2032 (`$7F × 16`, o GAIN fixo) e `spc.dsp.dirSampleTableAddress` = 2.
- `spc.dsp.voices[0].sampleBuffer0` a `11` = 14336: o nibble 7 com shift 11 dá 7168, guardado dobrado.
- `spc.dsp.voices[0].brrAddress` = 516 (`$0204`, início do sample, depois do loop).

As chaves de estado do DSP no Mesen começam com `spc.dsp.` e as de voz com `spc.dsp.voices[n].`.
