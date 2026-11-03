# Compressão em jogos de SNES

O hardware não descomprime nada (exceto cartuchos com chip S-DD1 ou SPC7110 [fullsnes]). O jogo descomprime por software, quase sempre pra um buffer na WRAM, e depois manda pra VRAM por DMA. Cada desenvolvedora tinha seu formato; não existe "o formato do SNES".

## Formatos conhecidos (catálogo do Lunar Compress)

O [Lunar Compress] (biblioteca de FuSoYa, v2.00 de 11/11/2025) dá nome e número a dezenas de formatos achados em jogos. Os nomes `LC_LZn` e `LC_RLEn` viraram o vocabulário da comunidade [Lunar Compress] [SNESLab: LZ2]. Alguns da tabela do `LunarDLL.h`:

| Nome | Jogo de referência na tabela | Nota da tabela |
|---|---|---|
| LC_LZ1 | Zelda 3, Super Mario World japonês (gráficos) | `Format2=1` converte 3bpp em 4bpp |
| LC_LZ2 | Super Mario World, Yoshi's Island (gráficos); Zelda 3 (dados) | quase idêntico ao LZ1; `Format2=1` converte 3bpp em 4bpp |
| LC_LZ5 | Super Metroid, Mario Kart, SimCity | LZ2 levemente melhorado |
| LC_LZ11 | Harvest Moon (gráficos) | sem descrição além de "just another format"; o formato está descrito abaixo a partir de duas implementações abertas |
| LC_LZ19 | Kirby Super Star, Earthbound (gráficos) | versão mais simples do LC_LZ3, usada pela HAL |
| LC_RLE1 | Super Mario World (dados) | usado nos fundos |

Formato marcado só com o nome do jogo no catálogo não tem descrição no próprio Lunar Compress. Antes de tratar como desconhecido, procure no [sfc-comp], que reimplementa os formatos do catálogo e diz qual função corresponde a cada `LC_*` (`doc/LunarCompress.md`). O que não estiver lá continua **não confirmado** até achar a rotina de descompressão no trace e comparar.

### Números dos formatos

Conferidos no `LunarDLL.def` do pacote oficial `lc200.zip` (v2.00, 11/11/2025), baixado do site do FuSoYa, e iguais aos da cópia antiga que a v0.1 tinha usado [Lunar Compress]:

| Constante | Valor |
|---|---|
| LC_LZ1 a LC_LZ21 | 0 a 20 (LC_LZn = n - 1) |
| LC_RLE1, LC_RLE2, LC_RLE3, LC_RLE4 | 100, 101, 102, 103 |

O próprio `.def` comenta que começar o formato 1 no valor 0 "não foi uma boa ideia". A v2.00 acrescentou o LC_LZ21 (usado com `Format2` igual ao tamanho exato). Pra conversão de tiles a DLL tem `LunarCreatePixelMap` e `LunarCreateBppMap` (tile em bpp ↔ mapa de pixels indexado), com as constantes `LC_1BPP` a `LC_8BPP` = 1 a 8 e `LC_MODE7_8BPP` = `0x28`. O tamanho máximo descomprimido, em geral, é `0x10000` bytes [Lunar Compress].

Uso pela linha de comando que vem no pacote [Lunar Compress]:

```
decomp.exe rom.sfc saida.bin OffsetHex Formato Formato2
recomp.exe ...   (mesma ideia, no sentido inverso)
```

O offset é de arquivo, em hexa. O pacote traz também o `sniff`, força bruta que tenta achar offsets de dados comprimidos [Lunar Compress].

## LC_LZ2 (exemplo completo de formato LZ "de comandos")

Fluxo de blocos, cada um com cabeçalho de 1 byte `CCCLLLLL`; `$FF` encerra [SNESLab: LZ2] [MushROMs: LC_LZ2]:

| CCC | Comando | Depois do cabeçalho | Saída |
|---|---|---|---|
| 000 | cópia direta | L+1 bytes | os bytes, como estão |
| 001 | byte fill | 1 byte | o byte, L+1 vezes |
| 010 | word fill | 2 bytes | alterna os dois até dar L+1 bytes |
| 011 | fill crescente | 1 byte | o byte L+1 vezes, somando 1 a cada escrita |
| 100 | repeat | 2 bytes, big endian | copia L+1 bytes a partir desse endereço do buffer de saída |
| 101, 110 | sem uso | | |
| 111 | tamanho longo | cabeçalho de 2 bytes `111CCCLL LLLLLLLL` | comando CCC com tamanho de 10 bits (até 1024 bytes) |

LC_LZ1 é o mesmo formato com o endereço do repeat em little endian [MushROMs: LC_LZ2]. O repeat usa endereço absoluto no buffer de saída, não distância pra trás.

## LC_RLE1 (exemplo de RLE)

Cabeçalho `CLLLLLLL`: C = 0, seguem L+1 bytes literais; C = 1, segue 1 byte repetido L+1 vezes. Fim = `$FF $FF` [SNESLab: RLE1].

## LZSS genérico (família LZ77)

Variante muito comum fora da Nintendo: um byte de flags controla os 8 itens seguintes, e cada bit diz se o item é um literal (1 byte) ou uma referência (deslocamento + tamanho, normalmente em 2 bytes). Referências menores que o ponto de equilíbrio não são emitidas [Wikipedia: LZSS]. A maioria das implementações descende do código de Haruhiko Okumura (1989) [Wikipedia: LZSS].

### O LZSS.C clássico de Okumura

Parâmetros do `LZSS.C` de 06/04/1989, lidos na cópia que a Apple mantém no `libkern/mkext.c` do xnu [Okumura LZSS.C]:

| Parâmetro | Valor |
|---|---|
| Janela (anel) | `N = 4096` bytes |
| Tamanho máximo da referência | `F = 18` |
| Limite (`THRESHOLD`) | 2: referência só a partir de 3 bytes |
| Preenchimento inicial do anel | espaço (`0x20`) nas posições 0 a `N - F - 1` |
| Primeira escrita | posição `r = N - F` (`0xFEE`) |
| Flags | 1 byte pra cada 8 itens, lido a partir do bit 0; bit 1 = literal, bit 0 = referência |
| Referência (2 bytes) | byte 1 = bits 0-7 da posição; byte 2: nibble alto = bits 8-11 da posição, nibble baixo = tamanho - 3 |

A posição é absoluta no anel, não distância pra trás. A versão mais nova do código do autor (`lzss.c`, com `EI = 11` e `EJ = 4`) já é outra coisa: fluxo de bits, sem byte de flags [Okumura lzss.c].

### Variantes em jogos de SNES

O [sfc-comp] reimplementa dezenas de compressores de SNES e expõe os parâmetros de cada um na chamada do LZSS. Alguns, pra mostrar o quanto variam (nomes de função do sfc-comp, lidos no código do commit `dd9dc03`). "Flags do bit 0" quer dizer 1 byte por 8 itens lido a partir do bit 0, como no LZSS.C; referência sempre em 2 bytes little endian, salvo onde dito:

| Função | Janela | Tamanho | Diferença em relação ao LZSS.C | Segunda fonte |
|---|---|---|---|---|
| `action_pachio` | 4096 | 3 a 18 | nenhuma no empacotamento: anel com `0x20`, primeira escrita em `0xFEE`; cabeçalho de 4 bytes (tamanho descomprimido e comprimido) | uma fonte só |
| `dq12` | 4096 | 3 a 18 | anel começa zerado; tamanho descomprimido em 2 bytes big endian no cabeçalho | uma fonte só |
| `hanjuku_hero` | 4096 | 3 a 18 | anel começa com um padrão próprio, não constante (cada byte 13 vezes, 0 a 255, o inverso, zeros e espaços); cabeçalho de 8 bytes | uma fonte só |
| `marios_super_picross` | 4096 | 3 a 18 | empacota `(posição << 4) \| (tamanho - 3)`; anel zerado | uma fonte só |
| `bokujou_monogatari` (LC_LZ11) e `ff5` | 2048 | 3 a 34 | 5 bits de tamanho e 11 de posição: byte 1 = posição bits 0-7, byte 2 = tamanho - 3 nos bits 0-4 e posição bits 8-10 nos bits 5-7; anel zerado, primeira escrita em `0x7DE`; cabeçalho = tamanho descomprimido | LC_LZ11: [HM-Decomp] (seção abaixo); `ff5`: [ff6tools], conferido rodando (abaixo) |
| `ff6` | 2048 | 3 a 34 | empacota `posição \| (tamanho - 3) << 11`; anel zerado, primeira escrita em `0x7DE`; cabeçalho = tamanho **comprimido** (2 bytes, contando o próprio cabeçalho) | [ff6tools], conferido rodando (abaixo) |
| `wizardry6` | 2048 | 3 a 34 | flags do bit 0 com sentido invertido (bit 0 = literal, bit 1 = referência); empacota `posição \| (tamanho - 3) << 11`, posição contada a partir do começo da janela de 2048 bytes que acaba no byte atual | uma fonte só |
| `dq6` | 1024 | 3 a 66 | 6 bits de tamanho e 10 de posição (byte 2 = tamanho - 3 nos bits 0-5, posição bits 8-9 nos bits 6-7); primeira escrita em `0x3BE`; sem cabeçalho | uma fonte só |
| `super_mario_rpg` (LC_LZ8) | 4095 | 3 a 18 | distância pra trás em vez de posição absoluta; cabeçalho de 8 bytes big endian (tamanho descomprimido e comprimido) | nome e uso confirmados no `LunarDLL.h` ("gráficos dos créditos"); parâmetros, uma fonte só (ver abaixo) |
| `rs3_comp_1` | 4095 | 3 a 18 | mesma distância pra trás do `super_mario_rpg`, com cabeçalho de 2 bytes (tamanho comprimido) | uma fonte só |
| `dragon_knight_4` | 2048 | 2 a 33 | flags lidas a partir do bit 7, e bit 1 = referência; referência com 5 bits de tamanho, posição relativa ao fim da janela | uma fonte só |
| `kiki_kaikai` | 2048 | 3 a 34 | flags de 16 bits, bit 1 = referência; empacota `(distância - 1) \| (tamanho - 3) << 11` | uma fonte só |

Conclusão: não existe um LZSS "padrão do SNES". Os pontos que mudam são janela, valor inicial do anel, posição da primeira escrita, sentido e ordem dos bits de flag, divisão dos bits entre posição e tamanho, se a posição é absoluta ou relativa e o que o cabeçalho guarda. O próprio Okumura já previa a troca do preenchimento: no texto de 1988 que publicou o LZSS, ele diz que os primeiros `N - F` bytes foram preenchidos com espaço, mas que dá pra pôr ali as palavras reservadas da linguagem que a pessoa mais usa [Okumura 1988]. Anel com padrão próprio, como o do `hanjuku_hero`, é essa mesma ideia.

Linha marcada "uma fonte só": foi procurada implementação ou documentação aberta independente (repositórios de ferramenta e tradução no GitHub, catálogo do [Lunar Compress], Data Crystal pelas cópias do Internet Archive, porque o site recusa acesso direto) e nada foi achado; pra um jogo específico, confirme na rotina antes de recomprimir.

### Conferência rodando: ff5 e ff6

O [ff6tools] (editor aberto de Final Fantasy, GPL-3.0) tem compressor e descompressor próprios pros dois formatos (`ff5-lzss` e `ff6-lzss` em `rom/romtools.js`), num projeto separado do sfc-comp. Em 03/11/2026 o compressor do ff6tools foi rodado no Node sobre seis arquivos sintéticos gerados por script nosso (1 a 9000 bytes, com repetições e um bloco só de zeros) e a saída foi descomprimida com um descompressor em Python escrito a partir dos parâmetros do sfc-comp acima: os seis voltaram iguais nos dois formatos, e trocar um descompressor pelo outro falha, ou seja, o teste distingue os dois. Nenhum dado de jogo foi usado [Teste local: LZSS].

As duas fontes concordam em tudo o que a tabela diz pra `ff5` e `ff6`, inclusive a diferença do cabeçalho (tamanho descomprimido no ff5, comprimido no ff6).

O mesmo teste com o `recomp.exe` do [Lunar Compress] (LC_LZ8 pro `super_mario_rpg`) não rodou: a execução do binário baixado foi barrada no ambiente do agente. Fica **não confirmado** até alguém rodar `recomp.exe amostra.bin saida.bin 0 1007 0` e descomprimir com o formato da tabela.

## LC_LZ11 (LZSS de janela de 2 KB)

Formato descrito a partir de duas implementações abertas, sem rotina nem dado de jogo comercial [sfc-comp] [HM-Decomp]:

| Parte | Formato |
|---|---|
| Cabeçalho | tamanho descomprimido em little endian, no começo do bloco |
| Flags | 1 byte antes de cada grupo de 8 itens, lido a partir do bit 0; bit 1 = literal, bit 0 = referência |
| Literal | 1 byte |
| Referência | 2 bytes: byte 1 = bits 0-7 da posição; byte 2: bits 0-4 = tamanho - 3 (3 a 34), bits 5-7 = bits 8-10 da posição |
| Janela | anel de 2048 bytes, posição absoluta no anel |
| Primeira escrita | posição `0x7DE` (2048 - 34, a mesma conta `N - F` do LZSS.C) |
| Anel antes do começo | o compressor do sfc-comp supõe zero |

É o mesmo esquema do LZSS.C de Okumura com janela menor e um bit a mais de tamanho. Divergência entre as duas fontes: o [sfc-comp] grava o tamanho em 4 bytes (mas limita a `0xFFFF`), o [HM-Decomp] lê 2 bytes de tamanho e pula outros 2. Na prática dá o mesmo arquivo; ao escrever um compressor, grave os 4 bytes.

## Reconhecer compressão olhando os bytes

Heurísticas (método, não fato de hardware):

| Sinal | Indica |
|---|---|
| No editor de tiles, nada forma desenho em nenhum bpp ou offset | dado comprimido (ou criptografado) |
| Desenho aparece em pedaços, com "lixo" regular entre eles | LZ com muitos literais: os trechos de cópia direta mostram tile cru |
| Byte inicial pequeno seguido de bytes de tile reconhecíveis, depois bytes com bits altos 001/010/100 | candidato a LC_LZ1/LZ2: o primeiro byte é um cabeçalho de cópia direta |
| Um byte a cada 8 itens "estranho" e o resto parecendo texto ou tile | LZSS com byte de flags |
| Pares (contador, valor) repetidos em área que devia ser lisa | RLE |
| Bloco termina em `$FF` ou `$FF $FF` | fim de stream dos formatos LC_LZ2 e LC_RLE1 |
| Tabela de ponteiros de 2 ou 3 bytes apontando pra blocos de tamanhos irregulares | lista de recursos comprimidos |

Teste rápido: rode o `decomp.exe` do Lunar Compress no offset suspeito com os formatos candidatos; descompressão que dá tamanho redondo (múltiplo de 32 pra 4bpp, de 24 pra 3bpp) e abre como tile é forte indício.

## Reconhecer no trace do emulador (o jeito confiável)

Ferramentas do [Mesen2]: Tile Viewer, Tilemap Viewer, Sprite Viewer, Event Viewer, Trace Logger, Memory Viewer e breakpoints por tipo de memória (VRAM, OAM, CGRAM, WRAM, ROM).

1. Ache o tile no Tile Viewer e anote o endereço na VRAM.
2. Breakpoint de **escrita na VRAM** nesse endereço. Ao parar, você está num DMA ($420B): leia $43x2-$43x4 (endereço de origem) e $43x5-$43x6 (bytes) do canal usado [fullsnes].
3. Origem na ROM: o gráfico está cru ali. Origem na WRAM: foi descomprimido antes.
4. Breakpoint de **escrita na WRAM** no começo do buffer de origem. A rotina que parar é o descompressor (ou quem chama ele).
5. Com o Trace Logger ligado nessa rotina, procure o padrão: lê um byte da ROM, separa bits com `AND`/`LSR` (cabeçalho ou flags), desvia por tipo de comando, e grava com `STA [ptr],y` ou `MVN` no buffer. Os parâmetros de entrada (ponteiro de 24 bits da origem, destino) costumam vir em direct page ou na pilha antes do `JSL`.
6. Compare o algoritmo com a tabela acima; se bater com um formato LC, use o Lunar Compress pra extrair e recomprimir. Se não bater, escreva um descompressor em Python a partir da leitura da rotina (código seu, sem copiar a rotina do jogo).

Reinserção: o dado recomprimido tem de caber no espaço original ou ir pra espaço livre com o ponteiro atualizado. Compressor diferente do original gera bytes diferentes mas válidos: o que importa é a saída descomprimida bater.
