# Teste no console com flash cart

O console é a referência final: timing, estado inicial da memória e revisões de chip reais. O teste aqui é manual; o que der para automatizar fica no emulador.

## SD2SNES, FXPAK e FXPAK Pro

Mesma família de firmware, do projeto mrehkopf/sd2snes; o SD2SNES virou FXPAK e o modelo atual é o FXPAK Pro [sd2snes][sd2snes CHANGELOG].

Chips especiais: o firmware usa núcleos de FPGA por chip, e a árvore do repositório tem núcleos para base, Cx4, DSP, GSU (SuperFX), OBC1, SA-1, S-DD1 e SGB [sd2snes]. Não há núcleo de SPC7110 na árvore; daí se deduz que jogos com SPC7110 não rodam, mas isso **não foi confirmado** numa lista oficial.

Histórico relevante no CHANGELOG [sd2snes CHANGELOG]:

- SuperFX entrou na v10 e SA-1 na v1.10.0, ambos por RedGuy.
- v1.11.0: suporte ao FXPAK Pro Rev.D, USB (usb2snes), SGB e save states (por USB/savestate2snes e também sem PC). **Save state só em jogo sem chip de expansão.**
- v1.11.1 e v1.11.2 (2026): correções de velocidade do SA-1, de latência do SuperFX, de MSU-1 e de save state, além de autoboot.

O que isso significa para teste:

- Hack de jogo com SA-1 ou SuperFX roda, mas os núcleos tiveram correções recentes de timing; um erro que só aparece no flash cart pode ser do núcleo, não do seu código. Atualize o firmware antes de investigar.
- Save state para pular trechos não serve em jogo com chip.
- Pela USB, o QUsb2snes é o servidor usado por ferramentas no PC para conversar com o cartucho [QUsb2snes]. Quais operações ele oferece para leitura de memória durante o jogo não foi conferido nesta pesquisa.

## Super EverDrive

Linha da krikzz. Pelas fontes consultadas, de confiança baixa (fórum e loja) [EverDrive]:

- Os modelos antigos só rodam DSP-1 com um chip físico instalado.
- O SNES EverDrive X6 emula DSP-1 a DSP-4.
- Sem SA-1, SuperFX e S-DD1.

Para hack de jogo com esses chips, o EverDrive não é opção de teste. Confira a página do seu modelo antes de comprar ou de concluir que um bug é do código.

## Limites do teste em console

- Não há como ler a RAM por script durante o jogo sem USB e ferramenta no PC; o teste é olhar a tela, ou fazer o código de teste mostrar o resultado (mudar a cor de fundo, por exemplo).
- O flash cart não é o cartucho original: o mapeamento e a SRAM vêm do firmware, que lê o header da ROM. Header errado vira mapeamento errado no flash cart antes de virar no emulador; ver `snes-rom-hack` (`references/cabecalho-e-checksum.md`).
- Consoles têm revisões diferentes de CPU e PPU, com bugs conhecidos de DMA e HDMA em algumas (ver `snes-hardware`, `references/dma-hdma.md`). Um teste em um console não cobre todos.

## Ordem sugerida

1. Teste automatizado no Mesen com RAM aleatória ([receita-teste-automatizado.md](receita-teste-automatizado.md)).
2. Conferência manual em bsnes ou ares.
3. Console com flash cart, firmware atualizado, nos trechos que mexem com timing, DMA, HDMA e chip especial.
