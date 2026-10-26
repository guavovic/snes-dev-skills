# Exemplos em asar

Código original, escrito para esta skill, na sintaxe do asar (`asar exemplo.asm rom.sfc`). Os imediatos com rótulo levam `.w`/`.b` explícito para o asar não ter de adivinhar o tamanho. Cada trecho aplica regras documentadas nos outros arquivos; a fonte de cada regra está indicada lá.

## Esqueleto LoROM: init, DMA para a VRAM, NMI e controle

```asm
lorom

!joy_atual = $0010          ; 2 bytes na WRAM baixa
!joy_novo  = $0012          ; botões que acabaram de ser apertados

org $008000
reset:
    sei                     ; reset entra em modo emulação com I = 1
    clc
    xce                     ; agora em modo nativo
    rep #$38                ; A, X, Y em 16 bits e decimal desligado
    ldx #$1FFF
    txs                     ; stack no topo da WRAM baixa
    lda #$0000
    tcd                     ; direct page em $0000
    sep #$20                ; A em 8 bits, X e Y continuam em 16

    lda #$8F
    sta $2100               ; force blank com brilho guardado em 15
    stz $4200               ; NMI, IRQ e auto-joypad desligados

    ; DMA canal 0: grafico -> VRAM $0000
    lda #$80
    sta $2115               ; incrementa depois do byte alto ($2119)
    ldx #$0000
    stx $2116               ; endereço da VRAM, em words
    lda #$01
    sta $4300               ; A -> B, endereço incrementa, padrão 1 (+0 +1)
    lda #$18
    sta $4301               ; destino $2118/$2119
    ldx.w #grafico
    stx $4302
    lda.b #grafico>>16
    sta $4304
    ldx.w #grafico_fim-grafico
    stx $4305               ; contagem em bytes (0 seria 64K)
    lda #$01
    sta $420B               ; CPU para até o DMA acabar

    lda #$0F
    sta $2100               ; sai do force blank
    lda #$81
    sta $4200               ; NMI + auto-joypad
    cli

principal:
    wai                     ; dorme até a próxima interrupção
    bra principal

nmi:
    rep #$30
    pha
    phx
    phy
    phb
    phd
    sep #$20
    lda $4210               ; reconhece a NMI

.espera_joypad:
    lda $4212
    lsr                     ; bit0 = auto-joypad em andamento
    bcs .espera_joypad

    rep #$20
    lda !joy_atual
    eor #$FFFF
    and $4218               ; apertado agora e solto no quadro anterior
    sta !joy_novo
    lda $4218
    sta !joy_atual

    rep #$30
    pld
    plb
    ply
    plx
    pla
irq:
    rti

grafico:
    db $FF,$00,$81,$00,$81,$00,$81,$00,$81,$00,$81,$00,$81,$00,$FF,$00
grafico_fim:

org $00FFE0                 ; vetores (banco 00)
    dw 0, 0, 0, 0           ; reservado
    dw 0                    ; COP nativo   FFE4
    dw 0                    ; BRK nativo   FFE6
    dw 0                    ; ABORT nativo FFE8
    dw nmi                  ; NMI nativo   FFEA
    dw 0                    ; reservado    FFEC
    dw irq                  ; IRQ nativo   FFEE
    dw 0, 0                 ; reservado
    dw 0                    ; COP emulação FFF4
    dw 0                    ; reservado
    dw 0                    ; ABORT        FFF8
    dw 0                    ; NMI emulação FFFA
    dw reset                ; RESET        FFFC
    dw irq                  ; IRQ/BRK emul FFFE
```

Pontos que o exemplo demonstra:

- O reset sempre começa em modo emulação, com só os registradores do núcleo parcialmente definidos ([cpu-5a22.md](cpu-5a22.md)).
- Force blank com `$8F`, não `$80` ([ppu-registradores.md](ppu-registradores.md)).
- DMA com contagem em bytes e destino `$18` para a VRAM ([dma-hdma.md](dma-hdma.md)).
- A NMI lê `$4210` e espera `$4212` bit0 antes de ler `$4218` ([interrupcoes-e-timing.md](interrupcoes-e-timing.md), [controles.md](controles.md)).
- O tile de exemplo é um quadrado vazado de 2bpp (plano 0 com o desenho, plano 1 zerado), feito para este arquivo.
- O header em $00:FFC0 foi omitido para encurtar; numa ROM de verdade preencha título, $FFD5 (mapa) e checksum ([mapa-de-memoria.md](mapa-de-memoria.md)).

## Tabela de HDMA: gradiente na cor de fundo

Escreve na CGRAM a cor 0 a cada 8 linhas. Usa o padrão 3 em `$2121` (`+0 +0 +1 +1`: CGADD duas vezes, depois CGDATA duas vezes). Por envolver escrita na CGRAM no hblank, veja a divergência registrada em [ppu-registradores.md](ppu-registradores.md) e teste em emulador de precisão.

```asm
; canal 7, modo direto, padrão 3, destino $2121
    lda #$03
    sta $4370
    lda #$21
    sta $4371
    ldx.w #gradiente
    stx $4372
    lda.b #gradiente>>16
    sta $4374
    lda #$80
    sta $420C               ; liga o HDMA do canal 7 (fazer no vblank)

gradiente:                  ; contagem, CGADD, CGADD, cor baixa, cor alta
    db 8 : db $00,$00 : dw $0000
    db 8 : db $00,$00 : dw $0400
    db 8 : db $00,$00 : dw $0800
    db 8 : db $00,$00 : dw $0C00
    db 0                    ; fim da tabela
```

Cada entrada escreve uma vez e espera 8 linhas (contagem entre $01 e $80, sem repeat).
