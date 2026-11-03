# Desempenho no SNES

Fontes: [fullsnes] "SNES Memory Speed" e "SNES Memory Control", [WDC], [Clark], tabela de [instruções](instrucoes.md), [bsnes], [Anomie timing], [SNESdev timing].

## Ciclo de CPU não é tempo fixo

O clock mestre do SNES NTSC é 21,47727 MHz. Cada ciclo de CPU dura 6, 8 ou 12 ciclos de clock mestre, conforme o que está sendo acessado naquele ciclo [fullsnes]:

| Região (bancos 00-3F e 80-BF salvo indicação) | Clks | Velocidade |
|---|---|---|
| $0000-1FFF (espelho de WRAM) | 8 | 2,68 MHz |
| $2000-3FFF (I/O, inclui PPU $21xx) | 6 | 3,58 MHz |
| $4000-41FF (leitura manual do joypad) | 12 | 1,78 MHz |
| $4200-5FFF (I/O da CPU, DMA) | 6 | 3,58 MHz |
| $6000-7FFF (SRAM, expansão) | 8 | 2,68 MHz |
| 00-3F:$8000-FFFF (ROM) | 8 | 2,68 MHz |
| 40-7F:qualquer (ROM, SRAM, WRAM $7E-7F) | 8 | 2,68 MHz |
| 80-BF:$8000-FFFF e C0-FF:qualquer (ROM) | 6 ou 8 | 3,58 MHz com FastROM |
| Ciclo interno (sem acesso à memória) | 6 | 3,58 MHz |

FastROM: escrever 1 no bit 0 de `$420D` (MEMSEL) faz a ROM nos bancos $80-$FF responder em 6 clks; no reset vale 0 [fullsnes]. Só ajuda se o código e os dados forem acessados pelos bancos $80+ (rodar em $80:8000 e não em $00:8000). A ROM precisa ser rápida (120 ns) e o cabeçalho deve indicar isso.

## Refresh da DRAM e tempo útil por linha

Uma linha de vídeo tem 1364 clocks mestre. Em toda linha a CPU para 40 clocks mestre pro refresh da WRAM, então sobram 1324 clocks pra executar código [SNESdev timing][Anomie timing][bsnes]. Isso é cerca de 3% do tempo, e conta em qualquer cálculo de "quantos ciclos cabem no V-Blank".

Posição do refresh na linha: o [bsnes] faz em 530 clocks na CPU revisão 1 e em 538 na revisão 2. O [Anomie timing] dá cerca de 536, com o primeiro em 538, e marca isso como teoria. A pausa de 40 clocks bate nas três fontes; a posição exata depende da revisão do chip.

## Quando o NMI e o IRQ disparam

- **NMI**: no começo do V-Blank, perto do ponto H=0,5 da primeira linha de V-Blank [Anomie timing]; o [bsnes] liga o NMI quando a linha chega a `vdisp` (225, ou 240 com overscan).
- **H-IRQ**: pedido pra `HTIME` (registradores $4207/$4208) dispara cerca de 3,5 pontos depois do ponto `HTIME`; a flag sobe em 14 + 4 x `HTIME` clocks mestre na linha [Anomie timing][bsnes]. O [bsnes] não dispara no último ponto do campo.
- Logo depois de escrever em $4200 e logo depois de um DMA, o teste de interrupção fica adiado um pouco (`irqLock` no [bsnes]), então um IRQ que cairia exatamente ali entra atrasado.
- Pra efeito de linha a linha, prefira HDMA. IRQ tem uma variação natural de alguns ciclos de CPU, porque espera a instrução em andamento terminar (ver [latência](pilha-chamadas-interrupcoes.md#latência-e-wai)).

## Dicas de ciclo

- **D alinhado**: deixe DL=$00 (D=$0000, $0100, $4300 ...). Cada acesso direct com DL diferente de zero custa +1 ciclo [WDC][Clark].
- **D apontando pra I/O**: `PEA $2100` + `PLD` (ou `LDA #$2100` + `TCD`) e depois `STA $18` escreve em $2118 com 2 bytes por instrução em vez de 3. O mesmo com D=$4300 pra configurar DMA. Lembre de restaurar D.
- **8 bits quando dá**: cada operando de 16 bits custa +1 ciclo (+2 em read-modify-write). Mas trocar de tamanho custa 3 ciclos por REP/SEP; não fique alternando dentro de laço.
- **Índices de 16 bits pagam sempre** o ciclo extra de `abs,x`/`abs,y`/`(d),y` em leitura; com 8 bits só paga se cruzar página.
- **Long custa 1 byte e 1 ciclo** a mais que absoluto. Ajuste DB pro banco dos dados (PHB/PLB) quando o laço for longo.
- **Desvio tomado** custa 3 ciclos, não tomado 2. No modo nativo cruzar página não custa nada.
- **MVN/MVP** levam 7 ciclos de CPU por byte; pra blocos grandes, DMA (canais em $43xx) é bem mais rápido. Detalhes de DMA ficam na skill de hardware do SNES.
- **Stack relative** (`LDA $03,s`) custa o mesmo que direct alinhado e evita mexer em D pra variáveis locais.
- **Ler o joypad manualmente** em $4016/$4017 é lento (12 clks por acesso); prefira a leitura automática.

## Exemplo: escrever em registradores da PPU com D apontando pra $2100

```asm
    PHD
    PEA $2100
    PLD               ; D = $2100, DL = $00, sem ciclo extra
    SEP #$20
    LDA #$80
    STA $00           ; $2100 = $80 (forced blank)
    PLD
```
