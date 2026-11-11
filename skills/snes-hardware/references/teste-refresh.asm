asar 1.90
lorom
optimize dp always

; ROM de teste para medir no console real onde cai, dentro da linha, a pausa
; de 40 master clocks do refresh da DRAM (issue #25). Código original, sem
; conteúdo de jogo.
;
; Montar: crie um arquivo de 32 KB zerado (teste-refresh.sfc) e rode
;   asar --no-title-check teste-refresh.asm teste-refresh.sfc
; Rodar no console com flashcart e fotografar a tela. Apertar reset mede
; de novo. Teste no emulador: teste-refresh.lua, ao lado deste arquivo.
;
; Como mede: com force blank e sem NMI, IRQ, DMA ou HDMA, um laço de período
; fixo (142 master clocks, código em FastROM) trava o contador H ($2137), lê
; OPHCT ($213C duas vezes: bits 0-7 e bit 8) e empilha os dois bytes, 1800
; vezes seguidas a partir do começo da linha 20 (cerca de 194 linhas). Entre
; duas amostras o H anda 35 ou 36 dots; no par que contém o refresh anda 45
; ou 46 (142 + 40 clocks). Como 1364 - 40 não é múltiplo de 142, a fase do
; laço escorrega 46 clocks por linha e, em 71 linhas, passa por todas as
; posições pares. Sendo R o master clock da linha em que a pausa começa,
; h o clock em que o $2137 trava e H = h / 4 (sem fração), cada linha diz:
;   R > h(antes) >= 4 * H(antes)
;   R <= h(depois) - 40 <= 4 * H(depois) + 3 - 40
; O atraso entre o início da leitura do $2137 e o momento em que o contador
; trava é o mesmo em todas as amostras, então some da conta: o que se mede é
; a posição da pausa no contador H. A ROM guarda, por grupo de linhas,
;   L = maior H(antes)       U = menor H(depois) - 10
; e então 4 * L < R <= 4 * U + 3. Com L = U, R fica num intervalo de 3
; clocks (um valor só, se R for par); com U = L + 1, de 7. Isso separa 530
; (L = U = 132) de 538 (L = U = 134). As linhas vão em dois grupos, V par e
; V ímpar, porque 1364 não é múltiplo de 8 e a fase do master clock no
; começo da linha alterna; se a posição variar dentro de um grupo, L passa
; de U. Limite: se no console a pausa esperar o fim do acesso da CPU em
; curso, em vez de cortar o acesso no meio como no Mesen, L e U refletem
; essa espera (até 8 clocks), e L > U também pode aparecer por isso.
;
; A tela (dígitos em hexa, 16x16) mostra, de cima para baixo:
;   linha 1   versão da CPU ($4210 bits 0-3), da PPU1 ($213E bits 0-3), da
;             PPU2 ($213F bits 0-3) e número de linhas amostradas
;   linha 2   V par: linhas com salto, L, U
;   linha 3   V ímpar: linhas com salto, L, U
;   linha 4   menor e maior diferença normal de H entre amostras, menor e
;             maior diferença no par com refresh (todas em dots)
; Os mesmos valores ficam em $7E0080-$7E008D, um byte cada, nessa ordem
; (CPU, PPU1, PPU2, linhas, contagem, L e U do grupo par, contagem, L e U do
; ímpar, as quatro diferenças), e $7E008F = $A5 quando acaba. As amostras
; cruas ficam em $7E11F0-$7E1FFF: a amostra k tem os bits 0-7 em $1FFF-2k e
; o bit 8 no bit 0 de $1FFE-2k.
;
; O que o MesenCE 2.2.1 mostra:
;   2 1 3  C2
;   61 86 86
;   60 85 85
;   22 24 2D 2E
; ou seja, L = U = 134 nas linhas pares e 133 nas ímpares: refresh em 538 e
; 534, que é o que o Mesen usa (538 - (master clock no começo da linha
; AND 7)). A diferença normal de 34 ($22) vem do fim da linha, onde dois
; dots têm 6 clocks. A última linha amostrada acaba antes do refresh, por
; isso 61 + 60 = C1, uma a menos que C2.
;
; O que anotar no console: as quatro linhas da tela, e se elas mudam depois
; de alguns resets (a fase do master clock pode trocar os grupos). L maior
; que U num grupo quer dizer que a posição varia de linha para linha.

AMOSTRAS = 1800

tmp = $00
g = $01
q = $02
lin = $03
base = $04
ant = $10
atual = $12
dif = $14
grp = $16
voltas = $18
dnmin = $1A
dnmax = $1C
drmin = $1E
drmax = $20
cnt = $22
lim_inf = $26
lim_sup = $2A
res = $80

macro pos(l, c)
    rep #$20
    lda.w #($1000+(<l>*32)+<c>)
    sta $2116
    sep #$20
endmacro

org $808000
reset:
    sei
    clc
    xce
    jml rapido

rapido:
    rep #$38
    ldx #$01FF
    txs
    lda #$0000
    tcd
    sep #$20
    pha
    plb
    lda #$8F
    sta $2100
    stz $4200
    stz $420B
    stz $420C
    lda #$01
    sta $420D               ; FastROM: código em $80:8000 lido em 6 clocks
    lda #$FF
    sta $4201               ; bit 7 ligado, senão $2137 não trava o contador
    lda $4210
    and #$0F
    sta res                 ; versão da CPU
    lda $213E
    and #$0F
    sta res+1               ; versão da PPU1
    lda $213F               ; também zera os flip-flops de $213C e $213D
    and #$0F
    sta res+2               ; versão da PPU2

    ldx #$1FFF
    txs                     ; as amostras vão para a pilha, de $1FFF para baixo
.espera19:
    lda $2137
    lda $213D
    sta tmp
    lda $213D
    and #$01
    bne .espera19
    lda tmp
    cmp #19
    bne .espera19
.espera20:
    lda $2137
    lda $213D
    sta tmp
    lda $213D
    and #$01
    bne .espera20
    lda tmp
    cmp #20
    bne .espera20

    ldx.w #AMOSTRAS
.amostra:
    lda $2137               ; 24 clocks (3 leituras de ROM rápida + 1 do barramento B)
    lda $213C               ; 24, H bits 0-7
    pha                     ; 20 (6 + 6 + escrita de 8 na WRAM)
    lda $213C               ; 24, H bit 8
    pha                     ; 20
    dex                     ; 12
    bne .amostra            ; 18 com o desvio
    ldx #$01FF              ; período: 142 master clocks
    txs

    rep #$30
    stz voltas
    stz grp
    stz dnmax
    stz drmax
    stz cnt
    stz cnt+2
    stz lim_inf
    stz lim_inf+2
    lda #$FFFF
    sta dnmin
    sta drmin
    sta lim_sup
    sta lim_sup+2
    ldx #$1FFE
    lda $0000,x
    xba
    and #$01FF
    sta ant
    ldy.w #(AMOSTRAS-1)
.proxima:
    dex
    dex
    lda $0000,x
    xba
    and #$01FF
    sta atual
    sec
    sbc ant
    bpl .mesma_linha
    inc voltas              ; H voltou: linha nova
    lda grp
    eor.w #$0002
    sta grp
    bra .seguinte
.mesma_linha:
    sta dif
    cmp.w #42
    bcs .refresh
    cmp dnmin
    bcs +
    sta dnmin
+
    cmp dnmax
    bcc .seguinte
    sta dnmax
    bra .seguinte
.refresh:
    cmp drmin
    bcs +
    sta drmin
+
    cmp drmax
    bcc +
    sta drmax
+
    phx
    ldx grp
    inc cnt,x
    lda ant
    cmp lim_inf,x
    bcc +
    sta lim_inf,x           ; maior H antes do salto
+
    lda atual
    sec
    sbc.w #10
    cmp lim_sup,x
    bcs +
    sta lim_sup,x           ; menor (H depois do salto - 10)
+
    plx
.seguinte:
    lda atual
    sta ant
    dey
    bne .proxima

    sep #$20
    lda voltas
    inc a
    sta res+3
    lda cnt
    sta res+4
    lda lim_inf
    sta res+5
    lda lim_sup
    sta res+6
    lda cnt+2
    sta res+7
    lda lim_inf+2
    sta res+8
    lda lim_sup+2
    sta res+9
    lda dnmin
    sta res+10
    lda dnmax
    sta res+11
    lda drmin
    sta res+12
    lda drmax
    sta res+13
    stz res+14
    lda #$A5
    sta res+15

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
    lda #$0040
-
    sta $2118               ; mapa todo com o tile vazio (64)
    dex
    bne -

    sep #$30
    stz g
.glifo:
    stz q
.quadrante:
    ldx g
    lda tile_digito,x
    ldx q
    clc
    adc quad_desloc,x
    rep #$20
    and #$00FF
    asl
    asl
    asl
    sta $2116               ; tile * 8 palavras
    sep #$20
    lda g
    asl
    asl
    asl
    sta base
    lda q
    and #$02
    asl
    clc
    adc base
    sta base                ; linha da fonte: glifo * 8, + 4 na metade de baixo
    stz lin
.linha:
    lda lin
    lsr
    clc
    adc base
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
    cmp #16
    bne .glifo

    %pos(2, 2)
    lda res
    jsr digito
    %pos(2, 4)
    lda res+1
    jsr digito
    %pos(2, 6)
    lda res+2
    jsr digito
    %pos(2, 9)
    lda res+3
    jsr hex2
    %pos(4, 2)
    lda res+4
    jsr hex2
    %pos(4, 5)
    lda res+5
    jsr hex2
    %pos(4, 8)
    lda res+6
    jsr hex2
    %pos(6, 2)
    lda res+7
    jsr hex2
    %pos(6, 5)
    lda res+8
    jsr hex2
    %pos(6, 8)
    lda res+9
    jsr hex2
    %pos(8, 2)
    lda res+10
    jsr hex2
    %pos(8, 5)
    lda res+11
    jsr hex2
    %pos(8, 8)
    lda res+12
    jsr hex2
    %pos(8, 11)
    lda res+13
    jsr hex2

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
.fim:
    bra .fim

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
    tax
    lda tile_digito,x
    sta $2118
    stz $2119
    rts

vazio:
    rti

tile_digito:
    db 0,2,4,6,8,10,12,14,32,34,36,38,40,42,44,46
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

org $00FFC0
    db "TESTE REFRESH 25     "
    db $30,$00,$05,$00,$01,$00,$00
    dw $FFFF,$0000
org $00FFE4
    dw 0,0,0,vazio,0,vazio
org $00FFF4
    dw 0,0,0,0,reset,0
