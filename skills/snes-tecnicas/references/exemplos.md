# Exemplos em asar

Código original, escrito para esta skill, na sintaxe do asar. **Não foi montado nem testado em emulador** (não havia asar na máquina em que foi escrito); trate como esboço revisado à mão. Cada trecho aplica regras dos outros references, onde está a fonte. O init e o esqueleto LoROM completo estão em snes-hardware/references/exemplos.md; estes trechos se encaixam nele.

Convenções: código no banco `$00` (LoROM, `org $008000`), DB = `$00`, variáveis na WRAM baixa, X e Y em 16 bits o tempo todo.

```asm
!quadro_pronto  = $0020     ; 1 byte: o laço terminou o quadro
!lag            = $0021     ; 2 bytes: quadros em que a NMI não transferiu
!inidisp_sombra = $0023     ; 1 byte: valor que a NMI escreve em $2100
!joy_atual      = $0024     ; 2 bytes
!joy_novo       = $0026     ; 2 bytes: recém-apertados
!fila_fim       = $0028     ; 2 bytes: deslocamento do fim da fila
!fila_bytes     = $002A     ; 2 bytes: total pedido neste quadro
!arg_vram       = $002C     ; argumentos de enfileira_dma
!arg_origem     = $002E     ; 2 bytes
!arg_banco      = $0030     ; 1 byte
!arg_tamanho    = $0032     ; 2 bytes
!fase           = $0034     ; 2 bytes: fase da onda
!camera_x       = $0036     ; 2 bytes
!foco_x         = $0038     ; 1 byte: centro da luz
!foco_y         = $003A     ; 2 bytes
!tmp            = $003C

!fila           = $0300     ; entradas de 8 bytes
!fila_max       = 16
!limite_dma     = 4096      ; bem abaixo dos ~6 KB do vblank NTSC
!hdma_onda      = $0400     ; 451 bytes
!hdma_foco      = $0600     ; 451 bytes
!raio           = 48
```

## Laço principal e NMI com flag de quadro

```asm
principal:
    jsr logica              ; lê !joy_novo, move atores, enche buffers
    sep #$20
    lda #$01
    sta !quadro_pronto
.espera:
    wai                     ; uma IRQ também acorda: por isso confere a flag
    lda !quadro_pronto
    bne .espera
    bra principal

nmi:
    rep #$30
    pha
    phx
    phy
    phb
    phd
    phk
    plb                     ; DB = banco do código ($00)
    lda #$0000
    tcd                     ; D = $0000
    sep #$20
    lda $4210               ; reconhece a NMI
    lda !quadro_pronto
    beq .lag
    jsr esvazia_fila_dma    ; o que precisa estar pronto antes da linha 0 vem primeiro
    ; aqui: DMA do buffer de OAM, paleta, scroll e HDMAEN a partir das sombras
    lda !inidisp_sombra
    sta $2100               ; ver o glitch de INIDISP em cor-e-transicoes.md
    jsr le_controle         ; controle por último, e só em quadro sem lag
    stz !quadro_pronto
    bra .fim
.lag:
    rep #$20
    inc !lag
.fim:
    rep #$30
    pld
    plb
    ply
    plx
    pla
    rti
```

## Controle com botão recém-apertado

```asm
le_controle:                ; A em 8 bits na entrada
.espera:
    lda $4212
    lsr                     ; bit 0 (auto-joypad lendo) vai para o carry
    bcs .espera
    rep #$20
    ldy !joy_atual          ; Y = quadro anterior
    lda $4218
    sta !joy_atual
    tya
    eor !joy_atual          ; bits que mudaram
    and !joy_atual          ; ... e estão apertados agora
    sta !joy_novo
    sep #$20
    rts
```

## Fila de DMA para a VRAM

```asm
; Entrada: !arg_vram (words), !arg_origem + !arg_banco, !arg_tamanho (bytes).
; Saída: carry 0 = entrou na fila, carry 1 = não coube, tente no próximo quadro.
enfileira_dma:
    rep #$30
    ldx !fila_fim
    cpx.w #8*!fila_max
    bcs .cheia
    lda !fila_bytes
    clc
    adc !arg_tamanho
    cmp.w #!limite_dma+1
    bcs .cheia
    sta !fila_bytes
    lda !arg_vram
    sta !fila+0,x
    lda !arg_origem
    sta !fila+2,x
    lda !arg_tamanho
    sta !fila+4,x
    lda !arg_banco          ; lê 2 bytes; o de cima cai no byte livre +7
    sta !fila+6,x
    txa
    clc
    adc.w #8
    sta !fila_fim
    clc
    rts
.cheia:
    sec
    rts

; Chamada pela NMI com A em 8 bits.
esvazia_fila_dma:
    ldx !fila_fim
    beq .fim
    lda #$80
    sta $2115               ; VMAIN: +1 word depois do byte alto
    lda #$01
    sta $4300               ; padrão 1: $2118, $2119
    lda #$18
    sta $4301
    ldx #$0000
.laco:
    ldy !fila+0,x
    sty $2116
    ldy !fila+2,x
    sty $4302
    ldy !fila+4,x
    sty $4305
    lda !fila+6,x
    sta $4304
    lda #$01
    sta $420B               ; canal 0; a CPU para até o fim
    rep #$20
    txa
    clc
    adc.w #8
    tax
    sep #$20
    cpx !fila_fim
    bne .laco
    ldx #$0000
    stx !fila_fim
    stx !fila_bytes
.fim:
    rts
```

## Ondulação de água: tabela de HDMA em BG1HOFS

Tabela em modo de repetição: dois blocos de 112 linhas (`$F0` = repetir por 112 linhas), 2 bytes por linha, terminador `$00`. Com a tabela sendo reescrita todo quadro, use duas cópias e troque o ponteiro na NMI (buffer duplo); aqui há uma só para ficar curto.

```asm
gera_onda:                  ; chamado pelo laço, uma vez por quadro
    rep #$30
    lda !fase
    inc a
    sta !fase
    sep #$20
    lda #$F0
    sta !hdma_onda          ; cabeçalho do bloco 1
    sta !hdma_onda+225      ; cabeçalho do bloco 2
    stz !hdma_onda+450      ; fim da tabela
    rep #$20
    ldx #$0000              ; linha da tela
    ldy #$0001              ; posição na tabela
.laco:
    txa
    clc
    adc !fase
    and.w #$003F
    asl
    phx
    tax
    lda seno,x
    plx
    clc
    adc !camera_x
    sta !hdma_onda,y
    iny
    iny
    cpy.w #225
    bne .seguinte
    iny                     ; pula o cabeçalho do bloco 2
.seguinte:
    inx
    cpx.w #224
    bne .laco
    sep #$20
    rts

liga_onda:                  ; no vblank
    lda #$02
    sta $4310               ; padrão 2: mesmo registrador duas vezes
    lda #$0D
    sta $4311               ; BG1HOFS
    ldx.w #!hdma_onda
    stx $4312
    stz $4314               ; banco $00 (WRAM baixa espelhada)
    lda #$02
    sta $420C               ; HDMA no canal 1
    rts

seno:                       ; 64 valores, amplitude 3 pixels
    dw 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3
    dw 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 0
    dw 0, 0, $FFFF, $FFFF, $FFFF, $FFFF, $FFFE, $FFFE, $FFFE, $FFFE, $FFFE, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD
    dw $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFD, $FFFE, $FFFE, $FFFE, $FFFE, $FFFE, $FFFF, $FFFF, $FFFF, $FFFF, 0
```

## Foco de luz: janela em círculo e escuro fora dela

Mesmo formato de tabela, agora com 2 bytes por linha para WH0 e WH1 (padrão 1). A meia largura do círculo vem pronta da tabela `meia` (raio 48).

```asm
gera_foco:
    sep #$20
    lda #$F0
    sta !hdma_foco
    sta !hdma_foco+225
    stz !hdma_foco+450
    ldy #$0001
    ldx #$0000
.laco:
    rep #$20
    txa
    sec
    sbc !foco_y             ; distância vertical até o centro
    bpl .positivo
    eor #$FFFF
    inc a
.positivo:
    cmp.w #!raio+1
    sep #$20
    bcs .fora
    phx
    tax                     ; byte alto de A é 0 aqui, então X = distância
    lda meia,x
    sta !tmp
    plx
    lda !foco_x
    sec
    sbc !tmp
    bcs .esquerda_ok
    lda #$00                ; corta na borda esquerda
.esquerda_ok:
    sta !hdma_foco,y
    lda !foco_x
    clc
    adc !tmp
    bcc .direita_ok
    lda #$FF                ; corta na borda direita
.direita_ok:
    sta !hdma_foco+1,y
    bra .seguinte
.fora:
    lda #$FF                ; esquerda 255 e direita 0: janela vazia na linha
    sta !hdma_foco,y
    lda #$00
    sta !hdma_foco+1,y
.seguinte:
    iny
    iny
    cpy.w #225
    bne .mesmo_bloco
    iny
.mesmo_bloco:
    inx
    cpx.w #224
    bne .laco
    rts

liga_foco:                  ; no vblank, com A em 8 bits
    lda #$20
    sta $2125               ; WOBJSEL: janela 1 ligada na janela de cor, sem inverter
    lda #$20
    sta $2130               ; CGWSEL: color math só fora da janela de cor, cor fixa
    lda #$BF
    sta $2131               ; CGADSUB: subtrai, em todas as camadas e no backdrop
    lda #$EC
    sta $2132               ; COLDATA: 12 nos três canais
    lda #$01
    sta $4320               ; padrão 1: $2126, $2127
    lda #$26
    sta $4321
    ldx.w #!hdma_foco
    stx $4322
    stz $4324
    lda #$04
    sta $420C               ; HDMA no canal 2 (some com o da onda: use $06 para os dois)
    rts

meia:                       ; round(sqrt(48*48 - d*d)), d = 0..48
    db 48, 48, 48, 48, 48, 48, 48, 47, 47, 47, 47, 47, 46, 46, 46, 46
    db 45, 45, 44, 44, 44, 43, 43, 42, 42, 41, 40, 40, 39, 38, 37, 37
    db 36, 35, 34, 33, 32, 31, 29, 28, 27, 25, 23, 21, 19, 17, 14, 10
    db 0
```

Para escuro total fora da luz, troque CGWSEL por `$40` (força preto fora da janela de cor) e dispense CGADSUB e COLDATA.

## Fade de saída

```asm
; Chamado uma vez por quadro de lógica. Carry 1 quando terminou.
fade_saida:
    sep #$20
    lda !inidisp_sombra
    and #$0F
    beq .acabou
    dec a
    sta !inidisp_sombra     ; a NMI escreve em $2100
    clc
    rts
.acabou:
    lda #$8F                ; brilho 0 não é preto garantido: termina em force blank
    sta !inidisp_sombra
    sec
    rts
```

Related: [estrutura-do-jogo.md](estrutura-do-jogo.md), [hdma-efeitos.md](hdma-efeitos.md), [cor-e-transicoes.md](cor-e-transicoes.md), [fontes.md](fontes.md)
