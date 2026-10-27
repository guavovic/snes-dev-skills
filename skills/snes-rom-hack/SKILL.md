---
name: snes-rom-hack
description: ROM hacking de Super Nintendo / Super Famicom com asar. Cobre o cabeçalho interno (título, map mode, chipset, tamanho de ROM e SRAM, checksum e complemento, vetores, cabeçalho estendido), onde ele fica em LoROM, HiROM, ExLoROM e ExHiROM e como detectar o mapeamento, o cabeçalho de copiador de 512 bytes (.smc x .sfc), cálculo de checksum inclusive em ROM que não é potência de 2, achar espaço livre com segurança, expandir a ROM até 4 MB ou 8 MB, hooks com JSL preservando registradores, flags, M/X, DB e D, aumentar a SRAM, asar a fundo (org, freespace, freecode, freedata, autoclean, pushpc/pullpc, macros, defines, incsrc, incbin, check title) e patches IPS e BPS com Floating IPS (flips), mais um fluxo de projeto com git que nunca guarda a ROM. Use quando alguém disser "quero hackear uma ROM de SNES", "como faço um hook", "onde coloco código novo", "freespace ou org?", "a ROM não abre depois do patch", "checksum errado", "LoROM ou HiROM?", "como expandir a ROM", "como aumentar a SRAM", "tirar o header de 512 bytes", "gerar IPS ou BPS", "como distribuir o hack sem a ROM", "o que é RATS", "autoclean pra que serve", "como montar o build do hack".
---

# ROM hacking de SNES (asar)

ROM hack é patch em cima de uma ROM que você não pode distribuir. O trabalho tem três partes: entender o layout da ROM (cabeçalho e mapeamento), enxertar código e dados sem quebrar o que já existe (espaço livre e hooks) e entregar só a diferença (BPS). Detalhe de instrução 65816 (tamanho de registrador, modos de endereçamento, ciclos) fica na skill `snes-assembly`; aqui só o que é específico de hack.

## Regras de ouro

1. **A ROM nunca entra no repositório nem no release.** Distribua BPS (ou IPS). O build lê a ROM local, confere o hash e só então monta [flips][SMWC-2ª]. Ver `references/fluxo-git-e-build.md`.
2. **Trabalhe sem cabeçalho de copiador.** Arquivo com tamanho `mod 1024 = 512` tem 512 bytes de lixo no começo; tire antes de tudo [fullsnes][SNESdev]. No asar, `.smc` é tratado como com cabeçalho e `.sfc` sem [asar].
3. **Descubra o mapeamento antes do primeiro `org`.** LoROM: cabeçalho no offset `$7FC0`; HiROM: `$FFC0`; ExHiROM: `$40FFC0` [fullsnes][SNESdev]. Errou o mapper, todo endereço sai errado. Ver `references/cabecalho-e-checksum.md`.
4. **Espaço livre não é "bytes zerados".** Zero pode ser dado do jogo. Só use área que você provou estar livre (fim da ROM depois de expandir, ou região rastreada no debugger) e deixe o asar marcar com RATS [asar]. Ver `references/espaco-livre-e-hooks.md`.
5. **Hook sobrescreve no mínimo 4 bytes** (JSL = 4 bytes, `$22`) [sneslab][fullsnes]. As instruções apagadas têm que ser refeitas na rotina nova, inteiras, com o mesmo M/X e o mesmo DB.
6. **Devolva o estado como recebeu.** `PHP` / `PHB` / `PHD` na entrada, `PLD` / `PLB` / `PLP` na saída. Ir pra 8 bits em X/Y zera o byte alto de X e Y, e o `PLP` não traz esse byte de volta [fullsnes].
7. **Checksum é conferido, não é decoração.** O asar recalcula por padrão; ferramenta externa que mexer na ROM depois precisa recalcular também [asar][fullsnes].
8. **Use `check title`** no patch pra recusar ROM errada (outra região, outra revisão) [asar].
9. **Expandir é mudar `$FFD7` e preencher o fim da ROM.** Passou de 4 MB, é ExLoROM ou ExHiROM, que não têm o mesmo suporte em todo emulador e flash cart [bsnes][Epilogue].
10. **Documente cada hook:** endereço original, bytes originais e instruções refeitas num comentário curto. Facilita portar pra outra revisão da ROM.

## Armadilhas

- **Branch relativo copiado pra fora do lugar.** `BEQ`/`BRA` sobrescritos no hook apontam pra outro lugar quando refeitos no freespace. Troque por `JML` pro destino original ou refaça a lógica.
- **`JSR` refeito no banco errado.** `JSR` fica no banco atual (PB) [sneslab]. Refeito no freespace, ele chama o endereço no banco novo. Use `JSL` pra rotina que termina em `RTL`, ou um trampolim no banco original.
- **DB do jogo x DB do seu código.** Dado seu em outro banco: `PHB` / `PHK` / `PLB` antes de ler com endereço absoluto, `PLB` antes de voltar.
- **Flag usada depois do hook.** Se o código original faz `BEQ` logo depois dos bytes sobrescritos, a última instrução refeita tem que deixar Z como antes. Por isso as instruções originais vão no fim da rotina, depois do `PLP`.
- **freecode em jogo que não é Super Mario World.** O asar procura espaço livre a partir do banco `$10` (offset `$80000`) e confia em RATS [asar]. Em ROM de outro jogo com 1 MB ou mais, esse trecho é do jogo. Expanda primeiro, ou use `freespace` com `start=` (asar 2.0), ou `org` em área provada.
- **Detecção de cabeçalho de copiador diferente entre ferramentas.** bsnes usa `tamanho & $7FFF = 512`, fullsnes e SNESdev usam `tamanho mod 1024 = 512` [bsnes][fullsnes]. Arquivo de tamanho estranho pode enganar uma e não a outra.
- **SRAM aumentada sem ajustar o jogo.** O emulador dimensiona a SRAM por `$FFD8` [bsnes], mas o jogo pode zerar ou somar (checksum) só o tamanho antigo [fullsnes]. Ver `references/mapeamento-e-expansao.md`.
- **IPS acima de 16 MB ou com offset `$454F46`.** IPS tem offset de 3 bytes e esse valor colide com a marca "EOF" [flips][sneslab]. BPS não tem o problema e ainda confere CRC32.
- **Patch aplicado na ROM errada ou duas vezes.** IPS não sabe em que ROM foi aplicado. BPS recusa ROM com CRC32 diferente [BPS].

## Índice de referências

| Arquivo | Conteúdo |
|---|---|
| `references/cabecalho-e-checksum.md` | Todos os campos do cabeçalho interno e estendido, vetores, detecção de mapeamento, cabeçalho de copiador, cálculo do checksum (inclusive tamanho que não é potência de 2) |
| `references/mapeamento-e-expansao.md` | LoROM, HiROM, ExLoROM, ExHiROM: bancos, fórmulas endereço SNES -> offset, SRAM, como expandir e como aumentar a SRAM |
| `references/espaco-livre-e-hooks.md` | Achar espaço livre, RATS, anatomia de um hook com JSL, o que preservar, JML, trampolim, hook em vetor |
| `references/asar.md` | Diretivas do asar pra hack: mapper, org, freespace/freecode/freedata, autoclean, prot, pushpc/pullpc, defines, macros, incsrc/incbin, check, avisos, linha de comando |
| `references/patches-ips-bps.md` | Formato IPS e BPS byte a byte, flips na linha de comando, outras ferramentas |
| `references/fluxo-git-e-build.md` | Projeto mínimo com asar: estrutura, `.gitignore`, script de build que confere o hash da ROM base, monta e gera o `.bps` |
| `references/comunidade.md` | SMW Central, romhacking.net depois de 2024, etiqueta de distribuição |
| `references/fontes.md` | Fontes, confiança, divergências e o que não foi consultado |

## Relação com outras skills

- `snes-assembly`: instruções, M/X, REP/SEP, pilha, ciclos. Esta skill assume que você já lê 65816.
- `snes-hardware`: mapa de memória, PPU, DMA, NMI/IRQ, registradores `$21xx`/`$42xx`, quando o hack mexe em gráfico, som ou timing.
