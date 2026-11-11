# Mapeamento, expansão e SRAM

Endereço SNES = `$BB:AAAA` (banco:endereço). Offset = posição no arquivo sem cabeçalho de copiador. As fórmulas são as do asar (`snestopc`), conferidas com os mapas do fullsnes, do SNESdev e das placas do bsnes. Mapa de memória completo (WRAM, I/O, registradores): skill `snes-hardware`.

## LoROM ("Mode 20")

- **ROM:** bancos `$00-$7D` e `$80-$FF`, sempre na metade de cima (`$8000-$FFFF`). Cada banco tem 32 KB de ROM [bsnes][SNESdev].
- **Fórmula:** `offset = ((endereço & $7F0000) >> 1) | (endereço & $7FFF)` [asar]. Exemplo: `$02:9ABC` -> `$011ABC`.
- **Inválido:** bancos `$7E/$7F` (WRAM), metade de baixo dos bancos `$00-$3F`/`$80-$BF` (I/O e WRAM espelhada) e metade de baixo de `$70-$7D` (SRAM) [asar].
- **Tamanho máximo:** 4 MB [SNESdev][bsnes]. O resumo do fullsnes fala em 2 MB e chama o maior de "BigLoROM" [fullsnes] (divergência em `fontes.md`).
- **SRAM:** `$70-$7D` e `$F0-$FF`, endereços `$0000-$7FFF` [bsnes][fullsnes]. Placas antigas mapeiam o banco inteiro (64 KB) e deixam a ROM só até o banco `$6F`; o bsnes chama essa variante de LOROM-RAM#A, usada em ROM de até 2 MB [bsnes][fullsnes]. Acima de 3 MB a SRAM tem que ficar só nos 32 KB de baixo [fullsnes].
- **FastROM:** bancos `$80-$FF` com `$FFD5` bit 4 = 1 e `MEMSEL` (`$420D`) = 1 (detalhe em `snes-hardware` e `snes-assembly`).

## HiROM ("Mode 21")

- **ROM:** bancos `$40-$7D` e `$C0-$FF`, banco inteiro (64 KB), com espelho em `$00-$3F`/`$80-$BF` na metade de cima [bsnes][fullsnes].
- **Fórmula:** `offset = endereço & $3FFFFF` [asar]. Exemplo: `$C1:2345` -> `$012345`.
- **Tamanho máximo:** 4 MB [fullsnes][SNESdev].
- **SRAM:** `$20-$3F` e `$A0-$BF`, endereços `$6000-$7FFF` (8 KB por banco) [bsnes][fullsnes].
- Código em banco `$00-$3F` precisa estar na metade de cima (`$8000+`); dado grande fica melhor em `$C0+`, onde o banco inteiro é contínuo.

## ExHiROM ("Mode 25")

- `$FFD5` = `$25` (ou `$35` com FastROM). Cabeçalho em `$40FFC0` [fullsnes][SNESdev].
- **ROM:** bancos `$80-$FF` = primeiros 4 MB (como HiROM); bancos `$00-$3F`/`$40-$7D` = os próximos 4 MB, a partir do offset `$400000` [bsnes].
- **Fórmula (bancos abaixo de `$80`):** `offset = (endereço & $3FFFFF) | $400000` [asar].
- Só dois jogos comerciais usaram [SNESdev]. Máximo prático: pouco menos de 8 MB, porque os bancos `$7E/$7F` são WRAM.

## ExLoROM (não oficial)

- Não existe valor de map mode pra ele: "ExLoROM mode is unofficial, and lacks a mapping mode value" [bsnes]. O cabeçalho vai pra `$407FC0`.
- **ROM:** `$80-$FF:8000-FFFF` a partir do offset 0; `$00-$7D:8000-FFFF` a partir do offset `$400000` [bsnes]. SRAM como LoROM.
- **Fórmula:** metade `$80+` igual a LoROM; metade `$00-$7D` igual a LoROM + `$400000` [asar].
- **Suporte por alvo:**
  - **bsnes:** placa própria (EXLOROM) e +4 na pontuação pro cabeçalho em `$407FB0` [bsnes].
  - **Mesen:** testa a base `$400000`; ExLoROM liga `$00-$7D:8000+` a partir do offset `$400000` e `$80-$FF` a partir de 0, e o log mostra "Type: ExLoROM" [MesenCE][Teste local].
  - **Snes9x:** `Map_JumboLoROMMap` com o formato estendido: `$00-$3F` a partir de `$400000`, `$40-$7F` de `$600000`, `$80-$BF` de 0 e `$C0-$FF` de `$200000` [snes9x]. Versões antigas variam: 1.39a a 1.43 e 1.54 em diante rodam 64 Mbit, 1.50 a 1.53 param em 48 Mbit; ZSNES não roda ExLoROM [LunarExpand].
  - **FXPAK / sd2snes:** o firmware não procura cabeçalho em `$407FB0`, mas acha o de LoROM em `$7FB0` e escolhe o mapeador LoROM. Na FPGA esse mapeador monta o endereço com o bit 23 invertido no lugar do bit 22, o que já é o layout ExLoROM (`$80+` a partir de 0, `$00-$7F` a partir de `$400000`) [sd2snes]. Lido no código, sem teste em hardware.
  - **SN Operator:** não lista ExLoROM [Epilogue]. **Super EverDrive:** firmware fechado, não confirmado.
  - Teste no alvo antes de escolher; ExHiROM tem suporte mais uniforme.

## Expandir a ROM

1. **Decida o tamanho.** LoROM: 1, 2, 3 ou 4 MB. HiROM: até 4 MB. Mais que isso: ExHiROM (ou ExLoROM, com as ressalvas acima).
2. **Preencha o fim do arquivo** até o novo tamanho com o byte que o asar considera livre (`freespacebyte`, padrão `$00`) [asar].
3. **Atualize `$FFD7`:** `$0A` = 1 MB, `$0B` = 2 MB, `$0C` = 3 ou 4 MB (arredonda pra cima) [fullsnes].
4. **Ex:** copie o cabeçalho pro novo lugar (`$40FFC0`), ajuste `$FFD5` no ExHiROM e confirme no emulador que ele reconheceu.
5. **Checksum:** o asar recalcula. 3 MB não é potência de 2 (2 MB + 1 MB repetido duas vezes); ver `cabecalho-e-checksum.md`.

O asar expande sozinho quando um `freespace` não acha lugar em LoROM: 512 KB -> 1 MB (`$FFD7 = $0A`) -> 2 MB (`$0B`). Só funciona se a ROM tiver exatamente 512 KB ou 1 MB; ROM menor (256 KB, por exemplo) dá erro de falta de espaço livre em vez de expandir [asar][Teste local]. Só dado (`freedata`) pode levar a 4 MB (`$0C`); `freecode` não passa de 2 MB, porque busca só nos bancos `$10-$3F` [asar]. Pra ter controle, expanda antes (ferramenta ou script) e use o asar só pra colocar o conteúdo.

**Alternativa relatada: LoROM convertida em HiROM (não confirmado).** Um blog japonês descreve outro jeito de ganhar espaço numa LoROM: inserir 32 KB vazios antes de cada banco de 32 KB do arquivo e somar 1 em `$FFD5` (`$20` -> `$21`, ou `$30` -> `$31` com FastROM) [RGLab]. Pelo mapa HiROM, cada banco de 64 KB fica com o banco original na metade de cima, então os endereços `$00-$3F`/`$80-$BF:8000-FFFF` que o código usa continuam apontando pros mesmos bytes, e as metades de baixo de `$C0-$FF:0000-7FFF` ficam livres [bsnes][fullsnes]; o cabeçalho, que estava no offset `$7FC0`, vai sozinho pra `$FFC0`. O preço é dobrar o arquivo (LoROM de até 2 MB vira HiROM de até 4 MB). Ressalvas: o autor testou só em emulador, sem dizer qual; a ROM de 3 MB que virou 6 MB não iniciou; e ele relata que a SRAM funcionou, mas no mapa HiROM a SRAM fica em `$20-$3F:6000-7FFF`, não em `$70` como em LoROM [bsnes][fullsnes], então, pela leitura do mapa, o código do jogo que acessa a SRAM precisaria mudar. Nada disso foi testado nesta pesquisa.

## Aumentar a SRAM

1. **Mude `$FFD8`.** O emulador dimensiona a SRAM por ele: `1024 << n`, com `n` limitado a 8 (256 KB) no bsnes e no Mesen [bsnes][MesenCE]; o Snes9x reserva até 512 KB [snes9x]. Ex.: `$03` = 8 KB, `$05` = 32 KB.
2. **Confira o chipset `$FFD6`:** jogo sem SRAM tem `$00`; mude pra `$02` (ROM + RAM + bateria) [fullsnes].
3. **Respeite o mapa:** LoROM, 32 KB em `$70:0000-$7FFF` (e bancos seguintes); HiROM, 8 KB por banco em `$20-$3F:6000-7FFF` [bsnes][fullsnes]. Em LoROM acima de 3 MB, só os 32 KB de baixo de cada banco.
4. **Revise o jogo:** rotina que zera a SRAM, que soma (checksum) ou que testa o tamanho pode assumir o tamanho antigo. SRAM costuma ter checksum, então patch de SRAM normalmente vem junto com patch desse cálculo [fullsnes].
5. **Janela da SRAM em LoROM muda com o tamanho da ROM.** Mesen: ROM de 2 MB ou mais põe a SRAM só em `$70-$7D:0000-7FFF`; abaixo disso, o banco inteiro [MesenCE]. Snes9x: só até `$7FFF` quando a ROM passa de 2 MB ou a SRAM passa de 32 KB [snes9x]. SRAM maior que 32 KB numa ROM grande ocupa vários bancos (`$70`, `$71`...).
6. **Flash carts.** FXPAK / sd2snes: o firmware aceita `1024 << n` sem teto e reserva 1 MB pra save; a FPGA põe a SRAM de LoROM em `$70-$7F`/`$F0-$FF` e, com ROM acima de 2 MB (`$FFD7` = `$0C`, máscara da ROM com o bit 21), só nos 32 KB de baixo; com ROM menor a metade de cima espelha a de baixo (o endereço não usa A15), então o banco inteiro de 64 KB não funciona como no Mesen. HiROM e ExHiROM: `$20-$3F:6000-7FFF`, até 256 KB endereçáveis [sd2snes]. Lido no código, sem teste em hardware. Super EverDrive: não confirmado.

Exemplo no asar (LoROM, 8 KB com bateria):

```asm
org $00FFD6
    db $02          ; ROM + RAM + bateria
org $00FFD8
    db $03          ; 8 KB
```
