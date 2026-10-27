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
- **Suporte:** bsnes tem placa própria [bsnes]. O SN Operator da Epilogue não lista ExLoROM [Epilogue]. Outros emuladores e flash carts: não confirmado. Teste no alvo antes de escolher.

## Expandir a ROM

1. **Decida o tamanho.** LoROM: 1, 2, 3 ou 4 MB. HiROM: até 4 MB. Mais que isso: ExHiROM (ou ExLoROM, com as ressalvas acima).
2. **Preencha o fim do arquivo** até o novo tamanho com o byte que o asar considera livre (`freespacebyte`, padrão `$00`) [asar].
3. **Atualize `$FFD7`:** `$0A` = 1 MB, `$0B` = 2 MB, `$0C` = 3 ou 4 MB (arredonda pra cima) [fullsnes].
4. **Ex:** copie o cabeçalho pro novo lugar (`$40FFC0`), ajuste `$FFD5` no ExHiROM e confirme no emulador que ele reconheceu.
5. **Checksum:** o asar recalcula. 3 MB não é potência de 2 (2 MB + 1 MB repetido duas vezes); ver `cabecalho-e-checksum.md`.

O asar expande sozinho quando um `freespace` não acha lugar em LoROM: 512 KB -> 1 MB (`$FFD7 = $0A`) -> 2 MB (`$0B`). Só dado (`freedata`) pode levar a 4 MB (`$0C`); `freecode` não passa de 2 MB, porque busca só nos bancos `$10-$3F` [asar]. Pra ter controle, expanda antes (ferramenta ou script) e use o asar só pra colocar o conteúdo.

## Aumentar a SRAM

1. **Mude `$FFD8`.** O emulador dimensiona a SRAM por ele: bsnes usa `1024 << n`, com `n` limitado a 8 [bsnes]. Ex.: `$03` = 8 KB, `$05` = 32 KB.
2. **Confira o chipset `$FFD6`:** jogo sem SRAM tem `$00`; mude pra `$02` (ROM + RAM + bateria) [fullsnes].
3. **Respeite o mapa:** LoROM, 32 KB em `$70:0000-$7FFF` (e bancos seguintes); HiROM, 8 KB por banco em `$20-$3F:6000-7FFF` [bsnes][fullsnes]. Em LoROM acima de 3 MB, só os 32 KB de baixo de cada banco.
4. **Revise o jogo:** rotina que zera a SRAM, que soma (checksum) ou que testa o tamanho pode assumir o tamanho antigo. SRAM costuma ter checksum, então patch de SRAM normalmente vem junto com patch desse cálculo [fullsnes].
5. **Flash carts** também leem `$FFD8`; tamanho acima do padrão (mais de 32 KB em LoROM) pode não funcionar. Não confirmado por modelo.

Exemplo no asar (LoROM, 8 KB com bateria):

```asm
org $00FFD6
    db $02          ; ROM + RAM + bateria
org $00FFD8
    db $03          ; 8 KB
```
