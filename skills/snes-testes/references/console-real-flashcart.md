# Teste no console com flash cart

O console é a referência final: timing, estado inicial da memória e revisões de chip reais. O teste aqui é manual; o que der para automatizar fica no emulador.

## SD2SNES, FXPAK e FXPAK Pro

Mesma família de firmware, do projeto mrehkopf/sd2snes; o SD2SNES virou FXPAK e o modelo atual é o FXPAK Pro [sd2snes][sd2snes CHANGELOG].

Chips especiais: o firmware usa núcleos de FPGA por chip, e a árvore do repositório tem núcleos para base, Cx4, DSP, GSU (SuperFX), OBC1, SA-1, S-DD1 e SGB [sd2snes]. Não há núcleo de SPC7110 na árvore, e a página oficial de incompatibilidades confirma: lista como incompatíveis três jogos com SPC7110 e os jogos com ST-011 e ST-018 [sd2snes compat]. A mesma página diz que qualquer outra ROM deve funcionar (com ou sem header de cópia, não intercalada), com ressalvas para Sufami Turbo e para cartuchos de BS-X, cujo suporte não é completo [sd2snes compat]. A página não traz data nem versão de firmware.

Histórico relevante no CHANGELOG [sd2snes CHANGELOG]:

- SuperFX entrou na v10 e SA-1 na v1.10.0, ambos por RedGuy.
- v1.11.0: suporte ao FXPAK Pro Rev.D, USB (usb2snes), SGB e save states (por USB/savestate2snes e também sem PC). **Save state só em jogo sem chip de expansão.**
- v1.11.1 e v1.11.2 (2026): correções de velocidade do SA-1, de latência do SuperFX, de MSU-1 e de save state, além de autoboot.

O que isso significa para teste:

- Hack de jogo com SA-1 ou SuperFX roda, mas os núcleos tiveram correções recentes de timing; um erro que só aparece no flash cart pode ser do núcleo, não do seu código. Atualize o firmware antes de investigar.
- Save state para pular trechos não serve em jogo com chip.
- Hack de jogo com SPC7110, ST-011 ou ST-018 não tem teste em FXPAK: fica no emulador.
- Pela USB, o QUsb2snes é o servidor usado por ferramentas no PC para conversar com o cartucho [QUsb2snes]. As operações de memória estão abaixo.

## Ler e escrever memória pela USB (protocolo usb2snes)

Pelo documento do protocolo e pela lista de comandos no código do QUsb2snes [QUsb2snes]:

- O servidor é um WebSocket sem criptografia em `ws://localhost:23074` (a porta 8080 é a antiga e não deve ser usada). O pedido vai em JSON num texto, com `Opcode`, `Space` (quase sempre `SNES`), `Flags` opcionais e `Operands`; dado binário vai em mensagem binária. Em erro o servidor só fecha a conexão.
- Sequência mínima: `DeviceList`, `Attach` com o nome do dispositivo, `Name` com o nome da sua ferramenta e `Info` para confirmar que conectou.
- **`GetAddress [offset, tamanho]`** lê memória; **`PutAddress [offset, tamanho]`** escreve, com os dados enviados em seguida em mensagem binária. Os dois valores vão em hexadecimal. O `PutAddress` aceita vários pares num pedido só.
- O offset **não** é endereço do SNES, é o espaço próprio do usb2snes: ROM a partir de `0x000000`, SRAM a partir de `0xE00000`, WRAM a partir de `0xF50000`. Assim, `$7E1F00` vira `F51F00`.
- O servidor original do usb2snes manda e recebe em pedaços de 1024 bytes; leitura maior chega em mais de uma mensagem.
- Outros comandos: `PutIPS` (aplica patch; o nome `hook` é especial no sd2snes), `Boot`, `Menu`, `Reset`, e arquivos no cartão com `GetFile`, `PutFile`, `List`, `Remove`, `Rename`, `MakeDir`.
- O `Info` devolve versão do firmware, ROM rodando e flags. O QUsb2snes também atende emuladores e o SNES Classic e marca o que eles não fazem com `NO_FILE_CMD`, `NO_CONTROL_CMD`, `NO_ROM_WRITE` e `NO_ROM_READ`.

Para teste, isso permite o mesmo truque do Mesen no console: o código grava o resultado num endereço combinado da WRAM e uma ferramenta no PC lê `F5xxxx` com `GetAddress`. Esta skill não traz essa ferramenta nem a testou em hardware; o que está acima é o que o protocolo documenta.

## Super EverDrive

Linha da krikzz. O modelo atual no catálogo do fabricante é o Super EverDrive X6, e a página oficial dele lista como chips suportados só DSP-1/1B, DSP-2, DSP-3 e DSP-4, com ROM de até 7,5 MB e save RAM de até 128 KB [krikzz X6]. A página não cita USB nem save state.

- SA-1, SuperFX, S-DD1, Cx4 e os demais não estão na lista oficial, logo não rodam no X6. Lojas e reviews dizem o mesmo sobre SA-1 e SuperFX [EverDrive].
- Os modelos anteriores (X5 e mais antigos) não estão mais no catálogo da krikzz; sobre eles só há loja e fórum, que divergem: há quem diga que o X5 não roda chip nenhum e há quem diga que rodava DSP-1 só com chip físico instalado [EverDrive]. Trate como não confirmado.

Para hack de jogo com chip além do DSP, o EverDrive não é opção de teste. Confira a página do seu modelo antes de comprar ou de concluir que um bug é do código.

## Limites do teste em console

- Não há como ler a RAM por script durante o jogo sem USB e ferramenta no PC (no FXPAK, pelo usb2snes acima; o Super EverDrive X6 não cita USB [krikzz X6]); sem isso, o teste é olhar a tela, ou fazer o código de teste mostrar o resultado (mudar a cor de fundo, por exemplo).
- O flash cart não é o cartucho original: o mapeamento e a SRAM vêm do firmware, que lê o header da ROM. Header errado vira mapeamento errado no flash cart antes de virar no emulador; ver `snes-rom-hack` (`references/cabecalho-e-checksum.md`).
- Consoles têm revisões diferentes de CPU e PPU, com bugs conhecidos de DMA e HDMA em algumas (ver `snes-hardware`, `references/dma-hdma.md`). Um teste em um console não cobre todos.

## Ordem sugerida

1. Teste automatizado no Mesen com RAM aleatória ([receita-teste-automatizado.md](receita-teste-automatizado.md)).
2. Conferência manual em bsnes ou ares.
3. Console com flash cart, firmware atualizado, nos trechos que mexem com timing, DMA, HDMA e chip especial.
