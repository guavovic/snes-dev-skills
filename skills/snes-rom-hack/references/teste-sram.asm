asar 1.90
lorom
optimize dp always
optimize address mirrors

; ROM de teste para ver no flashcart (FXPAK, Super EverDrive) quanta SRAM
; ele dá a uma LoROM que pede mais de 32 KB no cabeçalho, onde ela aparece
; e se ela sobrevive ao reset e ao desligar (issue #29). Código original,
; sem conteúdo de jogo.
;
; Montar (o asar cria o arquivo; não precisa de ROM base):
;   asar --no-title-check teste-sram.asm teste-sram.sfc
; Isso gera ROM de 32 KB com $FFD8 = $07 (128 KB, o máximo do Super
; EverDrive X6). Variantes, por define:
;   -DSRAM=n      $FFD8 = n (5 = 32 KB, 6 = 64 KB, 7 = 128 KB, 8 = 256 KB)
;   -DROM4MB=1    ROM de 4 MB ($FFD7 = $0C): a SRAM de LoROM vai só para
;                 a metade de baixo dos bancos, no Mesen (ROM de 2 MB ou
;                 mais) e no FXPAK (ROM acima de 2 MB) [MesenCE][sd2snes]
; Não versionar a .sfc. Teste no emulador: teste-sram.lua, ao lado.
;
; Como funciona: primeiro o contador de boot, em $70:0010-$0013 (valor e
; complemento): se o complemento confere, soma 1; se não, começa em 1.
; Depois a ROM grava uma marca diferente (número da sonda e número XOR $A5)
; no começo de cada metade de banco $70:0000, $70:8000, $71:0000 ...
; $7D:8000 (28 sondas de 32 KB) e em $F0:0000 e $FF:0000, nessa ordem, e
; relê tudo. Duas sondas que são o mesmo byte físico ficam com a marca da
; última gravada; sonda que não é RAM (ROM, open bus) não guarda marca.
; Cada sonda recebe uma classe: o número da primeira sonda com a mesma
; marca ("--" se não guardou). Classe igual à própria sonda = 32 KB novos;
; classe menor = espelho daquela sonda. Por fim, dentro do banco $70, grava
; marcas em $4000, $2000, $1000, $0800 e $0000 e vê qual desses espelha o
; $0000, para medir SRAM menor que 32 KB.
;
; A tela (16x16) mostra:
;   linha 1      D7 e o valor de $FFD7, D8 e o valor de $FFD8 desta ROM
;   linhas 2-8   uma linha para cada dois bancos: banco par ($70, $72 ...
;                $7C) e as classes de par:0000, par:8000, ímpar:0000 e
;                ímpar:8000
;   linha 9      F0 e a classe de $F0:0000, FF e a classe de $FF:0000
;   linha 10     SRAM distinta vista, em KB decimal (sondas novas x 32, ou
;                o tamanho dentro do banco se for menor que 32), e o
;                tamanho dentro do banco $70 (0, 2, 4, 8, 16 ou 32 KB)
;   linha 12     contador de boot (hexa)
; Na WRAM: $7E0080 $FFD7, $81 $FFD8, $82 KB no banco, $83-$84 KB total,
; $85-$86 contador, $87 1 se o contador veio da SRAM, $88 sondas novas,
; $8F = $A5 quando acaba; $7E0200-$021D marca lida em cada sonda ($FF =
; nenhuma) e $7E0220-$023D a classe.
;
; O que o MesenCE 2.2.1 mostra (ROM de 32 KB, SRAM 128 KB):
;   D7 05   D8 07
;   70 00 01 02 03
;   72 00 01 02 03      (e assim até o 7C)
;   F0 00   FF 02
;   128K   032K
;   0001                (0002 depois do reset; o Mesen grava o .srm ao
;                        fechar, então a execução seguinte mostra 0003)
; Ou seja: banco inteiro ($0000-$FFFF) de SRAM, 64 KB por banco, e os
; 128 KB se repetem a cada 2 bancos.
; Com -DROM4MB=1 (a metade de cima de cada banco é ROM, sem marca):
;   D7 0C   D8 07
;   70 00 -- 02 --
;   72 04 -- 06 --
;   74 00 -- 02 --      (repete a cada 4 bancos)
;   F0 00   FF 06
;   128K   032K
; Com -DSRAM=8 (256 KB): 72 04 05 06 07, repete a cada 4 bancos, FF 06,
; 256K. -DSRAM=9 dá o mesmo (o Mesen corta em 256 KB). -DSRAM=5: todas as
; classes 00, 032K 032K. -DSRAM=1 e 3: classes 00, 002K 002K e 008K 008K.
; -DSRAM=0: tudo "--", 000K 000K, e o contador fica sempre em 0001.
;
; O que anotar no flashcart: a tela inteira de cada variante; depois
; apertar reset e ver se o contador soma 1; depois desligar o console, ligar
; de novo e ver se soma 1 (bateria ou save no cartão) ou volta a 0001.
; Anote o modelo, o firmware e se o menu do cartucho salvou a SRAM no
; cartão antes de desligar.

!SRAM ?= 7
!ROM4MB ?= 0
NSONDAS = 30

ptr = $00
i = $03
tmp = $04
g = $05
q = $06
lin = $07
base_f = $08
distintos = $09
kb_banco = $0A
total = $0C
cont = $0E
end16 = $10
res = $80
leitura = $0200
classe = $0220

macro pos(l, c)
    lda #<l>
    sta lin
    lda #<c>
    sta q
    jsr posiciona
endmacro

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
    sep #$30
    pha
    plb
    lda #$8F
    sta $2100
    stz $4200
    stz $420B
    stz $420C
    stz res+15

    lda #$70
    sta ptr+2
    rep #$20
    lda.w #$0010
    sta ptr
    ldy #$02
    lda [ptr],y
    eor.w #$FFFF
    cmp [ptr]
    bne .novo
    lda [ptr]
    inc a
    ldx #$01
    bra .grava
.novo:
    lda.w #$0001
    ldx #$00
.grava:
    sta [ptr]
    sta cont
    eor.w #$FFFF
    sta [ptr],y
    sep #$20
    stx res+7

    ldx #$00
    stz i
.escreve:
    jsr carrega_sonda
    lda i
    sta [ptr]
    eor #$A5
    ldy #$01
    sta [ptr],y
    inc i
    lda i
    cmp #NSONDAS
    bne .escreve

    ldx #$00
    stz i
.rele:
    jsr carrega_sonda
    ldy #$01
    lda [ptr],y
    eor #$A5
    sta tmp
    lda [ptr]
    cmp tmp
    bne .sem_marca          ; open bus devolve o mesmo byte duas vezes: nunca passa
    cmp #NSONDAS
    bcc .guarda
.sem_marca:
    lda #$FF
.guarda:
    phx
    ldx i
    sta leitura,x
    plx
    inc i
    lda i
    cmp #NSONDAS
    bne .rele

    ldx #$00
.classe:
    lda leitura,x
    sta tmp
    cmp #$FF
    beq .poe
    ldy #$00
.procura:
    lda leitura,y
    cmp tmp
    beq .achou
    iny
    bra .procura
.achou:
    tya
.poe:
    sta classe,x
    inx
    cpx #NSONDAS
    bne .classe

    stz distintos
    ldx #$00
.conta:
    txa
    cmp classe,x
    bne +
    inc distintos
+
    inx
    cpx #28
    bne .conta

    lda #$70
    sta ptr+2
    ldx #$04
.escreve_banco:
    txa
    asl
    tay
    rep #$20
    lda tam_desloc,y
    sta ptr
    sep #$20
    txa
    sta [ptr]
    eor #$5A
    ldy #$01
    sta [ptr],y
    dex
    bpl .escreve_banco
    stz ptr
    stz ptr+1
    jsr le_banco
    cmp #$00
    beq .tem_sram
    stz kb_banco
    bra .total
.tem_sram:
    ldx #$01
.mede:
    txa
    asl
    tay
    rep #$20
    lda tam_desloc,y
    sta ptr
    sep #$20
    jsr le_banco
    cmp #$00
    beq .espelho
    inx
    cpx #$05
    bne .mede
    lda #32
    sta kb_banco
    bra .total
.espelho:
    lda tam_kb,x
    sta kb_banco

.total:
    stz kb_banco+1
    lda kb_banco
    cmp #32
    bcs .por_sonda
    rep #$20
    lda kb_banco
    sta total
    sep #$20
    bra .resultado
.por_sonda:
    rep #$20
    lda distintos
    and.w #$00FF
    asl
    asl
    asl
    asl
    asl
    sta total
    sep #$20

.resultado:
    lda $FFD7
    sta res
    lda $FFD8
    sta res+1
    lda kb_banco
    sta res+2
    lda total
    sta res+3
    lda total+1
    sta res+4
    lda cont
    sta res+5
    lda cont+1
    sta res+6
    lda distintos
    sta res+8
    lda #$A5
    sta res+15

    jsr prepara_tela

    %pos(1, 1)
    lda #$0D
    jsr digito
    lda #$07
    jsr digito
    %pos(1, 4)
    lda res
    jsr hex2
    %pos(1, 8)
    lda #$0D
    jsr digito
    lda #$08
    jsr digito
    %pos(1, 11)
    lda res+1
    jsr hex2

    stz g
.linha_banco:
    lda g
    inc a
    inc a
    sta lin
    lda #1
    sta q
    jsr posiciona
    lda g
    asl
    clc
    adc #$70
    jsr hex2
    lda g
    asl
    asl
    sta i                   ; primeira sonda da linha
    lda #4
    sta q
.sonda_linha:
    jsr posiciona
    ldx i
    jsr mostra_classe
    inc i
    lda q
    clc
    adc #3
    sta q
    cmp #16
    bcc .sonda_linha
    inc g
    lda g
    cmp #7
    bne .linha_banco

    %pos(9, 1)
    lda #$F0
    jsr hex2
    %pos(9, 4)
    ldx #28
    jsr mostra_classe
    %pos(9, 8)
    lda #$FF
    jsr hex2
    %pos(9, 11)
    ldx #29
    jsr mostra_classe

    %pos(10, 1)
    rep #$20
    lda total
    jsr decimal3
    lda #17
    jsr glifo
    %pos(10, 8)
    rep #$20
    lda kb_banco
    jsr decimal3
    lda #17
    jsr glifo

    %pos(12, 1)
    lda cont+1
    jsr hex2
    lda cont
    jsr hex2

    jsr liga_tela
.fim:
    bra .fim

carrega_sonda:              ; i -> ptr
    lda i
    asl
    clc
    adc i
    tax
    lda sondas,x
    sta ptr
    lda sondas+1,x
    sta ptr+1
    lda sondas+2,x
    sta ptr+2
    rts

le_banco:                   ; marca do teste dentro do banco, ou $FF
    ldy #$01
    lda [ptr],y
    eor #$5A
    sta tmp
    lda [ptr]
    cmp tmp
    bne .nada
    cmp #$05
    bcc .ok
.nada:
    lda #$FF
.ok:
    rts

mostra_classe:              ; X = sonda
    lda classe,x
    cmp #$FF
    beq .traco
    jmp hex2
.traco:
    lda #16
    jsr glifo
    lda #16
    jmp glifo

decimal3:                   ; A (16 bits, até 999) em três dígitos; volta com A em 8 bits
    ldx #$00
-
    cmp.w #100
    bcc +
    sbc.w #100
    inx
    bra -
+
    stx tmp
    ldx #$00
-
    cmp.w #10
    bcc +
    sbc.w #10
    inx
    bra -
+
    sep #$20
    pha
    phx
    lda tmp
    jsr digito
    pla
    jsr digito
    pla
    jmp digito

tam_desloc:
    dw $0000,$0800,$1000,$2000,$4000
tam_kb:
    db 0,2,4,8,16

sondas:
!b = 0
while !b < 14
    dl $700000+(!b*$10000),$708000+(!b*$10000)
    !b #= !b+1
endwhile
    dl $F00000,$FF0000

; ---- tela: fonte própria 8x8 dobrada em tiles de 16x16, igual à de
; ---- teste-exlorom.asm e de snes-hardware/references/teste-refresh.asm

NGLIFOS = 23
TILE_VAZIO = $70

prepara_tela:
    lda #$80
    sta $2115
    rep #$30
    stz $2116
    ldx #$1000
-
    stz $2118               ; tiles zerados
    dex
    bne -
    ldx #$0400
    lda.w #TILE_VAZIO
-
    sta $2118               ; mapa todo com o tile vazio
    dex
    bne -
    sep #$30
    stz g
.glifo:
    stz q
.quadrante:
    ldx g
    lda tile_glifo,x
    ldx q
    clc
    adc quad_desloc,x
    rep #$20
    and.w #$00FF
    asl
    asl
    asl
    sta $2116               ; tile * 8 palavras
    sep #$20
    lda g
    asl
    asl
    asl
    sta base_f
    lda q
    and #$02
    asl
    clc
    adc base_f
    sta base_f              ; linha da fonte: glifo * 8, + 4 na metade de baixo
    stz lin
.linha:
    lda lin
    lsr
    clc
    adc base_f
    tax
    lda fonte,x
    tay
    lda q
    lsr
    bcs .direita
    tya
    lsr
    lsr
    lsr
    lsr
    bra .dobra
.direita:
    tya
    and #$0F
.dobra:
    tax
    lda dobra,x
    sta $2118               ; plano 0: cor 1
    stz $2119               ; plano 1 vazio
    inc lin
    lda lin
    cmp #8
    bne .linha
    inc q
    lda q
    cmp #4
    bne .quadrante
    inc g
    lda g
    cmp #NGLIFOS
    bne .glifo
    rts

liga_tela:
    stz $2121
    stz $2122
    stz $2122               ; cor 0: preto
    lda #$FF
    sta $2122
    lda #$7F
    sta $2122               ; cor 1: branco
    lda #$10
    sta $2105               ; modo 0, BG1 com tiles de 16x16
    lda #$10
    sta $2107               ; mapa do BG1 em $1000, 32x32
    stz $210B               ; tiles do BG1 em $0000
    stz $210D
    stz $210D
    stz $210E
    stz $210E
    lda #$01
    sta $212C
    stz $212D
    stz $2130
    stz $2131
    stz $2133
    lda #$0F
    sta $2100
    rts

posiciona:                  ; lin, q -> endereço do mapa ($1000 + lin * 32 + q)
    rep #$20
    lda lin
    and.w #$00FF
    asl
    asl
    asl
    asl
    asl
    clc
    adc.w #$1000
    sta end16
    lda q
    and.w #$00FF
    clc
    adc end16
    sta $2116
    sep #$20
    rts

hex2:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr digito
    pla
digito:
    and #$0F
glifo:
    tax
    lda tile_glifo,x
    sta $2118
    stz $2119
    rts

vazio:
    rti

tile_glifo:
    db 0,2,4,6,8,10,12,14,32,34,36,38,40,42,44,46,64,66,68,70,72,74,76
quad_desloc:
    db 0,1,16,17
dobra:
    db $00,$03,$0C,$0F,$30,$33,$3C,$3F,$C0,$C3,$CC,$CF,$F0,$F3,$FC,$FF
fonte:
    db $7C,$C6,$CE,$D6,$E6,$C6,$7C,$00   ; 0
    db $18,$38,$18,$18,$18,$18,$7E,$00   ; 1
    db $7C,$C6,$06,$1C,$70,$C0,$FE,$00   ; 2
    db $7C,$C6,$06,$3C,$06,$C6,$7C,$00   ; 3
    db $1C,$3C,$6C,$CC,$FE,$0C,$0C,$00   ; 4
    db $FE,$C0,$FC,$06,$06,$C6,$7C,$00   ; 5
    db $3C,$60,$C0,$FC,$C6,$C6,$7C,$00   ; 6
    db $FE,$C6,$0C,$18,$30,$30,$30,$00   ; 7
    db $7C,$C6,$C6,$7C,$C6,$C6,$7C,$00   ; 8
    db $7C,$C6,$C6,$7E,$06,$0C,$78,$00   ; 9
    db $38,$6C,$C6,$C6,$FE,$C6,$C6,$00   ; A
    db $FC,$C6,$C6,$FC,$C6,$C6,$FC,$00   ; B
    db $7C,$C6,$C0,$C0,$C0,$C6,$7C,$00   ; C
    db $F8,$CC,$C6,$C6,$C6,$CC,$F8,$00   ; D
    db $FE,$C0,$C0,$FC,$C0,$C0,$FE,$00   ; E
    db $FE,$C0,$C0,$FC,$C0,$C0,$C0,$00   ; F
    db $00,$00,$00,$FE,$00,$00,$00,$00   ; - (16)
    db $C6,$CC,$D8,$F0,$D8,$CC,$C6,$00   ; K (17)
    db $C0,$C0,$C0,$C0,$C0,$C0,$FE,$00   ; L (18)
    db $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00   ; O (19)
    db $FC,$C6,$C6,$FC,$D8,$CC,$C6,$00   ; R (20)
    db $C6,$EE,$FE,$D6,$C6,$C6,$C6,$00   ; M (21)
    db $C6,$6C,$38,$38,$38,$6C,$C6,$00   ; X (22)

org $00FFC0
    db "TESTE SRAM 29        "
if !ROM4MB
    db $20,$02,$0C
else
    db $20,$02,$05
endif
    db !SRAM,$01,$00,$00
    dw $FFFF,$0000
org $00FFE4
    dw 0,0,0,vazio,0,vazio
org $00FFF4
    dw 0,0,0,0,reset,vazio

if !ROM4MB
org $FFFFFF
    db $00
endif
