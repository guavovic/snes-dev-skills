<div align="center">

# snes-dev-skills

Skills pra agentes de código que precisam entender e programar o **Super Nintendo**: hardware, assembly 65816, ROM hacking, desmontagem, gráficos, testes no emulador e as técnicas que os jogos da época usavam. Cada informação técnica vem com a fonte.

[Fontes](docs/fontes.md) • [Mudanças](CHANGELOG.md)

</div>

## Skills

| Skill | O que cobre |
|---|---|
| [snes-hardware](skills/snes-hardware/SKILL.md) | Mapa de memória (LoROM, HiROM, SRAM), CPU 5A22 e registradores $42xx, PPU, DMA e HDMA, APU, controles, timing e vetores |
| [snes-assembly](skills/snes-assembly/SKILL.md) | 65816 com sintaxe do asar: registradores, flags M e X, modos de endereçamento, pilha, chamadas e a tabela dos 256 opcodes |
| [snes-rom-hack](skills/snes-rom-hack/SKILL.md) | Cabeçalho interno e checksum, detecção de mapeamento, espaço livre, hooks, expansão de ROM e patches IPS e BPS |
| [snes-desmontagem](skills/snes-desmontagem/SKILL.md) | Separar código de dado, trace e CDL, ferramentas, nomear variáveis e tabelas, organizar um projeto de desmontagem |
| [snes-graficos](skills/snes-graficos/SKILL.md) | Formatos de tile, paleta BGR555, tilemaps, sprites, Mode 7, compressão e conversão entre PNG e SNES |
| [snes-testes](skills/snes-testes/SKILL.md) | Mesen pela linha de comando, testes automáticos em Lua, outros emuladores e console real com flashcart |
| [snes-tecnicas](skills/snes-tecnicas/SKILL.md) | Estrutura de um jogo (init, laço, NMI, fila de DMA), efeitos de HDMA, color math, transições, streaming e chips especiais |

---

Licença MIT · Feito por [Gustavo Victor](https://github.com/guavovic)
