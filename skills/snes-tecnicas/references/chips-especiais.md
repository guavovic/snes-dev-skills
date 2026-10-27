# Chips especiais no cartucho

Quando a CPU de 3,58 MHz não dava conta, o cartucho trazia um processador a mais. Mapeamento e registradores de cada chip: snes-hardware/references/mapa-de-memoria.md. Aqui fica **o que cada chip resolvia** e exemplos de jogos, todos segundo o [fullsnes].

| Chip | O que é | Jogos de exemplo |
|---|---|---|
| SA-1 | Outro 65C816 a 10,74 MHz, com DMA próprio e DMA de conversão de caracteres | Kirby Super Star, Super Mario RPG, Kirby's Dream Land 3 (cerca de 35 jogos) |
| Super FX (GSU1) | Processador RISC a 10,74 MHz que desenha num buffer de bitmap (10 jogos somando GSU1 e GSU2) | Star Fox, Stunt Race FX, Vortex, Dirt Trax FX |
| Super FX 2 (GSU2) | Versão a 21 MHz | Yoshi's Island, Doom, Winter Gold |
| DSP-1 | NEC uPD77C25 pré-programado com funções de matemática (matrizes, projeção) | Pilotwings, Super Mario Kart (cerca de 16 a 19 jogos) |
| DSP-2, DSP-3, DSP-4 | Variantes para jogos específicos | poucos jogos cada |
| CX4 | CPU RISC programável da Capcom | Mega Man X2, Mega Man X3 |
| S-DD1 | Descompressão em tempo real dos gráficos | Star Ocean, Street Fighter Alpha 2 |
| SPC7110 | Descompressão de dados | 3 jogos |
| OBC1 | Controlador de OBJ: portas para ler e escrever entradas da OAM por índice | Metal Combat |

## Quando a época usava chip

- **Polígonos**: o SNES não desenha polígono; o Super FX desenhava num bitmap que ia para a VRAM como tiles [fullsnes]. A equipe de Star Fox disse que "Super NES isn't polygon hardware" e que cada vértice a mais pesava [entrevista SNES Classic: Star Fox]. Ver [desenvolvedores.md](desenvolvedores.md).
- **Matemática do Mode 7 e 3D**: o DSP-1 recebia comandos de matriz e projeção e devolvia o resultado à CPU [fullsnes].
- **Mais CPU**: o SA-1 é um 65C816 três vezes mais rápido rodando ao lado da CPU principal [fullsnes].
- **Mais dados**: S-DD1 e SPC7110 descomprimiam dados da ROM em tempo real [fullsnes].

## Para um projeto novo

- Um chip especial exige um cartucho com esse chip (ou um flash cart que o suporte) e suporte do emulador; confira os dois antes de depender de um chip, principalmente dos raros.
- Antes de pensar em chip, esgote HDMA, color math e Mode 7, que já dão degradê, ondulação, paralaxe, perspectiva e luz sem hardware extra (ver [hdma-efeitos.md](hdma-efeitos.md)).

Related: [desenvolvedores.md](desenvolvedores.md), [hdma-efeitos.md](hdma-efeitos.md), [fontes.md](fontes.md)
