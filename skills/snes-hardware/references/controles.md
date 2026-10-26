# Controles

Fontes: [fullsnes: Controllers] [SNESdev wiki: MMIO registers].

## Leitura automática (recomendada)

1. Ligar `NMITIMEN` ($4200) bit0 (junto com a NMI: `lda #$81 : sta $4200`).
2. O hardware lê os controles no começo de cada vblank. Leva cerca de 4224 master clocks (~3 linhas) [fullsnes] [SNESdev wiki: Timing].
3. Esperar `HVBJOY` ($4212) bit0 voltar a 0 antes de ler.
4. Ler `JOY1` ($4218/9) a `JOY4` ($421E/F), 16 bits cada.

Formato de JOYn (1 = apertado):

| Bit | Botão |
|---|---|
| 15 | B |
| 14 | Y |
| 13 | Select |
| 12 | Start |
| 11 | Cima |
| 10 | Baixo |
| 9 | Esquerda |
| 8 | Direita |
| 7 | A |
| 6 | X |
| 5 | L |
| 4 | R |
| 3-0 | Identificação do aparelho (0000 no controle padrão) |

JOY3 e JOY4 só têm dado com multitap (bit1 de $4016/$4017).

## Leitura manual

1. Escrever 1 e depois 0 em `$4016` bit0 (strobe): os controles travam o estado dos botões.
2. Ler `$4016` (porta 1) ou `$4017` (porta 2) 16 vezes; cada leitura devolve um bit no bit0, na ordem B, Y, Select, Start, Cima, Baixo, Esquerda, Direita, A, X, L, R, e depois os 4 bits de identificação.
3. Acesso a `$4016/$4017` leva 12 master clocks.

Com o auto-joypad ligado, deixe `$4016` bit0 em 0 e não leia manualmente durante a leitura automática [fullsnes] [SNESdev wiki].

## Padrão de uso no jogo

- Guardar o estado do quadro anterior e calcular "acabou de apertar" com `novo AND NOT antigo`. Isso é lógica de software, não do hardware.
- Ler JOYn depois do auto-joypad, dentro da NMI ou logo depois dela, e guardar em RAM para o resto do quadro.

## Outros aparelhos (visão)

O mouse, a light gun (Super Scope) e o multitap usam as mesmas portas com protocolos próprios; a light gun trava o contador H/V via `$4201` bit7 e `$2137`. Detalhe fica fora desta skill [fullsnes].
