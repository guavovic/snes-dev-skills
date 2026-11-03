asar 1.90
lorom
optimize dp always

; ROM de teste para medir no console real o que a skill snes-hardware
; documentou só por emulador (issue #27). Código original, sem conteúdo de jogo.
;
; Montar: crie um arquivo de 32 KB zerado (teste.sfc) e rode
;   asar --no-title-check teste-console.asm teste.sfc
; Rodar no console com flashcart e filmar ou capturar a tela.
;
; A tela mostra só a cor de fundo (CGRAM 0), em faixas:
;   linhas 1-100    cinza, referência
;   linha 100       IRQ liga o HDMA do canal 7 no meio do quadro, com a
;                   receita A2A = tabela + 1 e NLTR = primeira contagem
;                   (gradiente de 4 cores de 8 linhas: vermelho, verde,
;                   azul, amarelo)
;   linhas 151-166  a CPU escreve a CGRAM 0 logo no começo de cada hblank,
;                   alternando vermelho e azul
;   linha 190       IRQ de H e V no ponto 80 liga o force blank ($8F)
; Botão A alterna o canal 6 (tabela vazia ligada desde o vblank), que muda
; o estado da flag interna do HDMA.
;
; O que o MesenCE 2.2.1 mostra (canal 6 ligado, padrão):
;   gradiente nas linhas 101-132, cinza de novo a partir da 133
;   faixas de 1 linha alternadas nas linhas 151-166, sem pontos soltos
;   escrita em $2100 no ponto 177 da linha 190; preto a partir do pixel
;   156 dessa linha e na tela toda daí para baixo
; Com o canal 6 desligado (botão A), o Mesen não mostra o gradiente.
;
; O que anotar no console: linha onde o gradiente começa (e se aparece com
; o canal 6 desligado), se a faixa de 151-166 sai limpa ou com pontos e
; cores fora do lugar, e o pixel onde o preto começa na linha 190, com
; qualquer lixo antes dele.

estado = $10
canal6 = $11
botao_ant = $12
cor_alt = $14

org $008000
reset:
    sei
    clc
    xce
    rep #$38
    ldx #$1FFF
    txs
    lda #$0000
    tcd
    sep #$20
    lda #$8F
    sta $2100
    stz $4200
    stz $420C
    stz $212C
    stz $212D
    stz $2130
    stz $2131
    stz $2121
    lda #$10
    sta $2122
    lda #$42
    sta $2122               ; cor 0 = cinza ($4210)

    lda #$00
    sta $4360               ; canal 6: modo 0, 1 byte
    lda #$FF
    sta $4361               ; destino sem efeito ($21FF)
    rep #$20
    lda.w #tabela_vazia
    sta $4362
    sep #$20
    stz $4364

    lda #$03
    sta $4370               ; canal 7: modo 3 (a a b b) em CGADD/CGDATA
    lda #$21
    sta $4371
    rep #$20
    lda.w #gradiente
    sta $4372
    sep #$20
    stz $4374
    stz $4377

    lda #$01
    sta canal6
    stz botao_ant
    stz estado
    rep #$20
    lda #$001F
    sta cor_alt
    sep #$20

    lda #$0F
    sta $2100
    lda #$81
    sta $4200
    cli
.laco:
    wai
    bra .laco

nmi:
    rep #$30
    pha
    phx
    sep #$20
    lda $4210
    lda #$0F
    sta $2100
    stz $2121
    lda #$10
    sta $2122
    lda #$42
    sta $2122
    lda canal6
    beq +
    lda #$40
+
    sta $420C               ; canal 6 ligado na linha 0 (ou nada)
.joy:
    lda $4212
    and #$01
    bne .joy
    lda $4218
    and #$80                ; botão A
    tax
    eor botao_ant
    and #$80
    beq +
    txa
    beq +
    lda canal6
    eor #$01
    sta canal6
+
    txa
    sta botao_ant
    stz estado
    rep #$20
    lda.w #100
    sta $4209
    sep #$20
    lda #$A1                ; NMI, IRQ de V, auto-joypad
    sta $4200
    rep #$30
    plx
    pla
    rti

irq:
    rep #$30
    pha
    phx
    sep #$20
    lda $4211
    lda estado
    beq .liga_hdma
    cmp #$01
    beq .cgram
    lda #$8F
    sta $2100               ; force blank no meio da linha 190
    lda #$81
    sta $4200
    bra .sai

.liga_hdma:
    rep #$20
    lda.w #gradiente+1
    sta $4378               ; A2A = início da tabela + 1
    sep #$20
    lda gradiente
    sta $437A               ; NLTR = primeira contagem
    lda canal6
    beq +
    lda #$40
+
    ora #$80
    sta $420C
    inc estado
    rep #$20
    lda.w #150
    sta $4209
    sep #$20
    bra .sai

.cgram:
    ldx.w #16
.linha:
    lda $4212
    and #$40
    bne .linha              ; espera sair do hblank
.hb:
    lda $4212
    and #$40
    beq .hb                 ; espera começar o hblank
    stz $2121
    lda cor_alt
    sta $2122
    lda cor_alt+1
    sta $2122
    rep #$20
    lda cor_alt
    eor #$7C1F              ; alterna vermelho ($001F) e azul ($7C00)
    sta cor_alt
    sep #$20
    dex
    bne .linha
    stz $2121
    lda #$10
    sta $2122
    lda #$42
    sta $2122
    inc estado
    rep #$20
    lda.w #190
    sta $4209
    lda.w #80
    sta $4207
    sep #$20
    lda #$B1                ; NMI, IRQ de H e V, auto-joypad
    sta $4200

.sai:
    rep #$30
    plx
    pla
    rti

tabela_vazia:
    db $00

gradiente:
    db $08 : db $00,$00 : dw $001F
    db $08 : db $00,$00 : dw $03E0
    db $08 : db $00,$00 : dw $7C00
    db $08 : db $00,$00 : dw $03FF
    db $01 : db $00,$00 : dw $4210
    db $00

org $00FFC0
    db "TESTE CONSOLE 27     "
    db $20,$00,$05,$00,$01,$00,$00
    dw $FFFF,$0000
org $00FFE4
    dw 0,0,0,nmi,0,irq
org $00FFF4
    dw 0,0,0,0,reset,0
