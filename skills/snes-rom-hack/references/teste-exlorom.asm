asar 1.90
norom
optimize dp always
optimize address mirrors

; ROM de teste para ver no flashcart (FXPAK, Super EverDrive) como ele mapeia
; uma ROM ExLoROM (issue #29). Código original, sem conteúdo de jogo.
;
; Montar (o asar cria o arquivo; não precisa de ROM base):
;   asar --no-title-check teste-exlorom.asm teste-exlorom.sfc
; Isso gera 8 MB. Para 6 MB (o Super EverDrive X6 aceita até 7,5 MB):
;   asar --no-title-check -DMB=6 teste-exlorom.asm teste-exlorom6.sfc
; Não versionar a .sfc. Teste no emulador: teste-exlorom.lua, ao lado.
;
; Como funciona: o arquivo é montado em norom (endereço = offset no
; arquivo), para escrever onde o asar no modo exlorom não deixa (ele recusa
; os bancos $70-$7D, que são os blocos de $780000 a $7EFFFF). Cada bloco de
; 32 KB do arquivo tem a marca dele no offset $7F00 do bloco: número do
; bloco e o complemento ($FF - número). O cabeçalho vai duas vezes, em
; $7FC0 (onde o LoROM procura) e em $407FC0 (onde o ExLoROM procura), com
; o mesmo vetor de reset ($8000). O código fica no bloco 0 e roda no banco
; $80, que é o bloco 0 tanto em ExLoROM quanto em LoROM; o bloco $80
; (offset $400000) só tem um salto para lá. Assim a ROM liga mesmo que o
; cartucho trate o arquivo como LoROM comum, e a tela mostra o que ele fez.
; O par checksum/complemento do cabeçalho é fixo ($AAAA/$5555): soma $FFFF,
; que é o que os emuladores pontuam, mas não é a soma real do arquivo.
;
; A ROM lê os dois bytes em $bb:FF00 de cada banco $00-$FF (menos $7E e
; $7F, que são WRAM). Marca válida = o banco mostra aquele bloco; marca
; inválida = espelho fora do lugar, zeros, open bus ou outra coisa.
; Esperado em ExLoROM [bsnes][MesenCE][sd2snes]: banco $80-$FF = bloco
; banco - $80 (offset 0 em diante) e banco $00-$7D = bloco banco + $80
; (offset $400000 em diante), ou seja, bloco = banco XOR $80. Em LoROM
; comum seria bloco = banco AND $7F.
;
; A tela (dígitos em hexa, 16x16) mostra:
;   linhas 1-8   dois grupos de 16 bancos por linha: à esquerda o grupo
;                $00-$0F, $10-$1F ... $70-$7F; à direita $80-$8F ... $F0-$FF.
;                Cada grupo: dígito alto do banco, bloco lido no primeiro
;                banco do grupo ("--" se a marca for inválida) e quantos
;                dos outros bancos do grupo fogem da sequência (bloco do
;                primeiro + 1, + 2...); 0 = grupo inteiro em sequência.
;   linha 10     EX: bancos que não batem com o ExLoROM esperado (só conta
;                bloco que existe no arquivo); LO: bancos que não batem
;                com LoROM comum
;   linha 12     veredito (EXLOROM, LOROM ou --) e o tamanho montado (MB)
; Os mesmos valores ficam na WRAM: $7E0080 EX, $81 LO, $82 veredito
; (2 EXLOROM, 1 LOROM, 0 nenhum), $83 MB, $8F = $A5 quando acaba;
; $7E0090-$9F bloco do primeiro banco de cada grupo, $A0-$AF 1 se a marca
; dele é válida, $B0-$BF fugas de cada grupo; $7E0200-$02FF bloco lido em
; cada banco e $7E0300-$03FF 1 se a marca é válida.
;
; O que o MesenCE 2.2.1 mostra com 8 MB:
;   0 80 0  8 00 0
;   1 90 0  9 10 0
;   ...
;   7 F0 0  F 70 0
;   EX 00   LO 7E       (LO: os 126 bancos $00-$7D fogem do LoROM)
;   EXLOROM     08
; Com 6 MB, as linhas 5 a 8 da esquerda (bancos $40-$7D) aparecem
; "4 -- F" ... "7 -- D": o Mesen espelha a parte acima de 4 MB numa página
; só de 4 KB (o mesmo defeito de ROM irregular descrito em
; cabecalho-e-checksum.md) e o $bb:FF00 cai em código, sem marca. O
; veredito continua EXLOROM, porque esses bancos ficam além do arquivo e
; não entram na conta EX. Sem o cabeçalho de $407FC0 o Mesen escolhe LoROM
; e a tela mostra "0 00 0" ... "7 70 0", EX 7E, LO 00 e LOROM: é o que se
; espera ver num cartucho que ignore o ExLoROM.
;
; O que anotar no flashcart: as linhas 1 a 8 inteiras, a linha EX/LO e o
; veredito, com o modelo do cartucho, a versão do firmware e o tamanho
; montado. Se a ROM não ligar (tela preta ou menu recusando o arquivo),
; anote isso também: é resultado.

!MB ?= 8
!BLOCOS #= !MB*32

ptr = $00
g = $03
q = $04
lin = $05
base_f = $06
primeiro = $07
primeiro_ok = $08
quebras = $09
tmp = $0A
end16 = $0C
res = $80
bloco = $0200
valido = $0300

macro pos(l, c)
    lda #<l>
    sta lin
    lda #<c>
    sta q
    jsr posiciona
endmacro

org $000000
base $808000
reset:
    sei
    clc
    xce
    jml inicio

inicio:
    rep #$38
    ldx #$1FFF
    txs
    lda #$0000
    tcd
    sep #$30
    lda #$80
    pha
    plb                     ; banco de dados $80: WRAM em $0000-$1FFF e ROM em $8000+
    lda #$8F
    sta $2100
    stz $4200
    stz $420B
    stz $420C

    stz ptr
    lda #$FF
    sta ptr+1               ; ponteiro $bb:FF00
    ldx #$00
.le:
    stx ptr+2
    stz bloco,x
    stz valido,x
    cpx #$7E
    beq .le_prox
    cpx #$7F
    beq .le_prox
    ldy #$01
    lda [ptr],y
    eor #$FF
    sta tmp
    lda [ptr]
    cmp tmp
    bne .le_prox            ; open bus devolve o mesmo byte duas vezes: nunca passa
    sta bloco,x
    lda #$01
    sta valido,x
.le_prox:
    inx
    bne .le

    stz res
    stz res+1
    ldx #$00
.conta:
    cpx #$7E
    beq .conta_prox
    cpx #$7F
    beq .conta_prox
    txa
    and #$7F
    sta tmp                 ; LoROM: bloco = banco AND $7F
    lda valido,x
    beq .lo_erra
    lda bloco,x
    cmp tmp
    beq .lo_ok
.lo_erra:
    inc res+1
.lo_ok:
    txa
    eor #$80
    sta tmp                 ; ExLoROM: bloco = banco XOR $80
if !BLOCOS < 256
    cmp.b #!BLOCOS
    bcs .conta_prox         ; bloco além do arquivo: não conta
endif
    lda valido,x
    beq .ex_erra
    lda bloco,x
    cmp tmp
    beq .conta_prox
.ex_erra:
    inc res
.conta_prox:
    inx
    bne .conta

    ldx #$00
.grupo:
    lda bloco,x
    sta primeiro
    lda valido,x
    sta primeiro_ok
    stz quebras
    ldy #$01
.g_banco:
    inx
    cpx #$7E
    beq .g_seg
    cpx #$7F
    beq .g_seg
    lda valido,x
    beq .g_foge
    tya
    clc
    adc primeiro
    cmp bloco,x
    beq .g_seg
.g_foge:
    inc quebras
.g_seg:
    iny
    cpy #16
    bne .g_banco
    txa
    lsr
    lsr
    lsr
    lsr
    tay
    lda primeiro
    sta.w res+$10,y
    lda primeiro_ok
    sta.w res+$20,y
    lda quebras
    sta.w res+$30,y
    inx
    bne .grupo

    lda #$02
    ldx res
    beq .veredito
    lda #$01
    ldx res+1
    beq .veredito
    lda #$00
.veredito:
    sta res+2
    lda.b #!MB
    sta res+3
    lda #$A5
    sta res+15

    jsr prepara_tela

    stz g
.linha_g:
    lda g
    inc a
    sta lin
    lda #1
    sta q
    jsr posiciona
    lda g
    jsr digito
    lda #3
    sta q
    jsr posiciona
    ldx g
    jsr mostra_grupo
    lda #6
    sta q
    jsr posiciona
    ldx g
    lda res+$30,x
    jsr digito
    lda #9
    sta q
    jsr posiciona
    lda g
    ora #$08
    jsr digito
    lda #11
    sta q
    jsr posiciona
    lda g
    ora #$08
    tax
    jsr mostra_grupo
    lda #14
    sta q
    jsr posiciona
    lda g
    ora #$08
    tax
    lda res+$30,x
    jsr digito
    inc g
    lda g
    cmp #8
    bne .linha_g

    %pos(10, 1)
    ldx.b #(t_ex-textos)
    jsr texto
    %pos(10, 4)
    lda res
    jsr hex2
    %pos(10, 9)
    ldx.b #(t_lo-textos)
    jsr texto
    %pos(10, 12)
    lda res+1
    jsr hex2
    %pos(12, 1)
    ldx.b #(t_traco-textos)
    lda res+2
    beq +
    ldx.b #(t_lorom-textos)
    cmp #$01
    beq +
    ldx.b #(t_exlorom-textos)
+
    jsr texto
    %pos(12, 13)
    lda res+3
    jsr hex2

    jsr liga_tela
.fim:
    bra .fim

mostra_grupo:               ; X = grupo
    lda res+$20,x
    beq .traco
    lda res+$10,x
    jmp hex2
.traco:
    ldx.b #(t_traco-textos)
    jmp texto

; ---- tela: fonte própria 8x8 dobrada em tiles de 16x16, igual à de
; ---- snes-hardware/references/teste-refresh.asm, com sete letras a mais

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

texto:                      ; X = início do texto em textos, termina em $FF
    lda textos,x
    cmp #$FF
    beq .fim
    phx
    jsr glifo
    plx
    inx
    bra texto
.fim:
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

textos:
t_ex:       db 14,22,$FF                    ; EX
t_lo:       db 18,19,$FF                    ; LO
t_exlorom:  db 14,22,18,19,20,19,21,$FF     ; EXLOROM
t_lorom:    db 18,19,20,19,21,$FF           ; LOROM
t_traco:    db 16,16,$FF                    ; --

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
fim_codigo:
    assert fim_codigo <= $80FF00, "código invadiu a marca do bloco 0"

; Bloco $80 (offset $400000): o que o ExLoROM mostra em $00:8000.
org $400000
base $008000
    sei
    clc
    xce
    jml inicio

macro cabecalho(onde)
    org <onde>+$7F80
    base off
    rti
    org <onde>+$7FC0
    db "TESTE EXLOROM 29     "
    db $20,$00,$0D,$00,$01,$00,$00
    dw $5555,$AAAA          ; complemento e checksum: par válido, valor fixo
    org <onde>+$7FE4
    dw 0,0,0,$FF80,0,$FF80
    org <onde>+$7FF4
    dw 0,0,0,0,$8000,$FF80
endmacro

%cabecalho($000000)
%cabecalho($400000)

!b = 0
while !b < !BLOCOS
    org (!b*$8000)+$7F00
    db !b,$FF-!b
    !b #= !b+1
endwhile
org (!MB*$100000)-1
    db $00
