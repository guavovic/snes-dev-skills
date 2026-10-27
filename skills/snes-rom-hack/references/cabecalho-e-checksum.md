# Cabeçalho interno, copiador e checksum

## Onde fica

O cabeçalho interno ocupa `$00:FFC0-$00:FFDF` no espaço da CPU, e os vetores vêm logo depois, até `$FFFF` [fullsnes][SNESdev]. No arquivo (sem cabeçalho de copiador):

| Mapeamento | Offset do cabeçalho (`$FFC0`) |
|---|---|
| LoROM | `$007FC0` |
| HiROM | `$00FFC0` |
| ExHiROM | `$40FFC0` |
| ExLoROM | `$407FC0` (não oficial, ver `mapeamento-e-expansao.md`) [bsnes] |

Com cabeçalho de copiador, some `$200` em tudo [fullsnes].

## Campos (`$FFC0-$FFDF`)

| Endereço | Tam. | Campo | Observação |
|---|---|---|---|
| `$FFC0` | 21 | Título | ASCII `$20-$7E`, completado com espaço. Na prática é JIS: `$5C` é o iene, não a barra invertida [fullsnes] |
| `$FFD4` | (1) | Último byte do título | `$00` aqui indica o cabeçalho estendido antigo [fullsnes] |
| `$FFD5` | 1 | Map mode e velocidade | Bits 7-6 = 0, bit 5 = 1, bit 4 = velocidade (0 lenta 200 ns, 1 rápida 120 ns = FastROM), bits 3-0 = mapa: `0` LoROM ("Mode 20"), `1` HiROM ("Mode 21"), `2` LoROM + S-DD1, `3` LoROM + SA-1, `5` ExHiROM ("Mode 25"), `A` HiROM + SPC7110 [fullsnes][SNESdev] |
| `$FFD6` | 1 | Chipset | `00` só ROM, `01` ROM+RAM, `02` ROM+RAM+bateria, `x3`-`x6` combinações com coprocessador. Nibble alto: `0` DSP, `1` GSU (Super FX), `2` OBC1, `3` SA-1, `4` S-DD1, `5` S-RTC, `E` outro, `F` custom (subtipo em `$FFBF`) [fullsnes] |
| `$FFD7` | 1 | Tamanho da ROM | `1 << n` KB, arredondado pra cima. `$08` = 256 KB, `$09` = 512 KB, `$0A` = 1 MB, `$0B` = 2 MB, `$0C` = 4 MB [fullsnes][SNESdev] |
| `$FFD8` | 1 | Tamanho da SRAM | `1 << n` KB. `0` = sem SRAM, `1` = 2 KB, `3` = 8 KB, `5` = 32 KB [fullsnes][SNESdev] |
| `$FFD9` | 1 | País / região | `00` Japão, `01` América do Norte, `02` Europa, e outros [fullsnes] |
| `$FFDA` | 1 | Desenvolvedor | `$33` = existe cabeçalho estendido novo em `$FFB0` [fullsnes][SNESdev] |
| `$FFDB` | 1 | Versão | `00` = primeira [fullsnes] |
| `$FFDC` | 2 | Complemento | Checksum XOR `$FFFF`, little-endian [fullsnes][SNESdev] |
| `$FFDE` | 2 | Checksum | Soma de 16 bits, little-endian [fullsnes][SNESdev] |

Homebrew costuma deixar `0000,0000` ou `FFFF,0000` no par complemento/checksum [fullsnes]. O console não confere, mas emulador e ferramenta usam esse par pra detectar o mapeamento, então o certo é calcular.

## Cabeçalho estendido (`$FFB0-$FFBF`, quando `$FFDA = $33`)

| Endereço | Tam. | Campo |
|---|---|---|
| `$FFB0` | 2 | Código do fabricante (ASCII) |
| `$FFB2` | 4 | Código do jogo (ASCII) |
| `$FFB6` | 6 | Reservado (`00`) |
| `$FFBC` | 1 | Tamanho da flash de expansão |
| `$FFBD` | 1 | Tamanho da RAM de expansão (usada pelo GSU, por exemplo) |
| `$FFBE` | 1 | Versão especial |
| `$FFBF` | 1 | Subtipo do chipset (quando `$FFD6` tem nibble alto `F`) |

Fonte: [fullsnes][SNESdev].

## Vetores

| Modo nativo | | Modo emulação | |
|---|---|---|---|
| COP | `$FFE4` | COP | `$FFF4` |
| BRK | `$FFE6` | ABORT | `$FFF8` |
| ABORT | `$FFE8` | NMI | `$FFFA` |
| NMI | `$FFEA` | RESET | `$FFFC` |
| IRQ | `$FFEE` | IRQ / BRK | `$FFFE` |

A CPU sempre liga em modo emulação, então o RESET vem de `$FFFC` [fullsnes][SNESdev]. O NMI que o jogo usa durante a partida é o nativo, `$FFEA`. Pra hook no NMI, ver `espaco-livre-e-hooks.md`.

## Como detectar o mapeamento

Ninguém lê um campo só. As ferramentas pontuam os candidatos e escolhem o maior.

**bsnes** (`scoreHeader`) testa os offsets `$7FB0`, `$FFB0`, `$407FB0` e `$40FFB0` [bsnes]:

- Vetor de RESET abaixo de `$8000`: candidato descartado (pontuação 0).
- Primeiro opcode no RESET: +8 pra `SEI`, `CLC`, `SEC`, `STZ`, `JMP`, `JML`; +4 pra `REP`, `SEP`, `LDA`, `LDX`, `LDY`, `JSR`, `JSL`; -4 pra `RTI`, `RTS`, `RTL`, `CMP`, `CPX`, `CPY`; -8 pra `BRK`, `COP`, `STP`, `WDM` e `$FF`.
- +4 se checksum + complemento = `$FFFF`.
- +2 se o map mode de `$FFD5` bate com o offset.
- Os candidatos `$40xxxx` (ROM acima de 4 MB) ganham +4.

**asar** (`setmapper`) dá pontos pros caracteres do título que parecem texto e descarta candidato cujo complemento não bate; sem vencedor, fica em LoROM [asar].

O SNESdev lista as mesmas pistas: título legível, map mode coerente, checksum + complemento = `$FFFF` e vetor de RESET plausível [SNESdev].

Na prática: olhe os dois offsets (`$7FC0` e `$FFC0`), veja qual tem título legível e `$FFD5` coerente, e confirme no debugger que o vetor de RESET aponta pra código que faz sentido.

## Cabeçalho de copiador (512 bytes)

Copiadores dos anos 90 (Super Wild Card, Pro Fighter e outros) gravavam 512 bytes de cabeçalho antes da ROM [fullsnes][SNESdev]. Esses bytes não têm nada que sirva pro jogo; hoje o padrão é arquivo sem cabeçalho [SNESdev].

- **Detecção:** `tamanho mod 1024 = 512` [fullsnes][SNESdev]. O bsnes usa `tamanho & $7FFF = 512` [bsnes] (divergência registrada em `fontes.md`; em dump real as duas batem).
- **Formatos conhecidos:** SWC (bytes 0-1 = tamanho em blocos de 8 KB, byte 2 = modo, bytes 8-9 = `AA BB`, byte `$0A` = tipo de arquivo), FIG (Pro Fighter) e o NSRT, que grava "NSRT" em `$1E8` [fullsnes].
- **Extensão:** `.sfc` costuma ser sem cabeçalho e `.smc` com; o asar segue essa convenção e acusa erro se o arquivo não bate com a extensão [asar].
- **Patch:** o flips tira o cabeçalho SMC por padrão ao criar e aplicar BPS; `--exact` desliga isso [flips].
- **Remover:** é só descartar os primeiros 512 bytes. Em Python: `open("limpa.sfc", "wb").write(open("rom.smc", "rb").read()[512:])`.

## Checksum

**ROM de tamanho potência de 2** [fullsnes][SNESdev]:

1. Escreva `FF FF` no complemento (`$FFDC`) e `00 00` no checksum (`$FFDE`). Esses 4 bytes somam `$1FE`, o mesmo que somam com os valores certos (checksum + complemento é sempre `$FFFF`).
2. Some todos os bytes da ROM e guarde só 16 bits.
3. Grave a soma em `$FFDE` e a soma XOR `$FFFF` em `$FFDC`.

**ROM que não é potência de 2** (ex.: 10 Mbit, 3 MB): a maior potência de 2 vem primeiro; o resto é repetido até ocupar o mesmo tamanho dessa primeira parte, e a soma é feita sobre esse espaço espelhado [fullsnes][SNESdev]. Exemplo: 10 Mbit = 8 Mbit + 2 Mbit, então soma 8 Mbit + 4 vezes os 2 Mbit finais. O asar faz o mesmo em `getchecksum`: primeira parte = maior potência de 2 abaixo do tamanho, repetições = primeira parte / resto [asar].

Script de conferência (Python, ROM sem cabeçalho de copiador, `offset_cabecalho` = offset de `$FFC0` conforme o mapeamento):

```python
def checksum_snes(rom: bytes, offset_cabecalho: int) -> int:
    dados = bytearray(rom)
    complemento = offset_cabecalho + 0x1C
    dados[complemento:complemento + 4] = b"\xFF\xFF\x00\x00"
    tamanho = len(dados)
    primeira = 1 << (tamanho.bit_length() - 1)
    if primeira == tamanho:
        return sum(dados) & 0xFFFF
    resto = dados[primeira:]
    repeticoes = primeira // len(resto)
    return (sum(dados[:primeira]) + sum(resto) * repeticoes) & 0xFFFF
```

Ele cobre o caso "potência de 2 + uma potência de 2 menor", que é o de toda ROM comercial e o que o asar trata. Resto que não é potência de 2: não confirmado; prefira expandir pra um tamanho regular.

No asar o checksum é corrigido automaticamente, a não ser em `norom` ou modo xkas; `--fix-checksum=on|off` força [asar].
