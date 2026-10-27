# Compressão em jogos de SNES

O hardware não descomprime nada (exceto cartuchos com chip S-DD1 ou SPC7110 [fullsnes]). O jogo descomprime por software, quase sempre pra um buffer na WRAM, e depois manda pra VRAM por DMA. Cada desenvolvedora tinha seu formato; não existe "o formato do SNES".

## Formatos conhecidos (catálogo do Lunar Compress)

O [Lunar Compress] (biblioteca de FuSoYa, v2.00 de 11/11/2025) dá nome e número a dezenas de formatos achados em jogos. Os nomes `LC_LZn` e `LC_RLEn` viraram o vocabulário da comunidade [Lunar Compress] [SNESLab: LZ2]. Alguns da tabela do `LunarDLL.h`:

| Nome | Jogo de referência na tabela | Nota da tabela |
|---|---|---|
| LC_LZ1 | Zelda 3, Super Mario World japonês (gráficos) | `Format2=1` converte 3bpp em 4bpp |
| LC_LZ2 | Super Mario World, Yoshi's Island (gráficos); Zelda 3 (dados) | quase idêntico ao LZ1; `Format2=1` converte 3bpp em 4bpp |
| LC_LZ5 | Super Metroid, Mario Kart, SimCity | LZ2 levemente melhorado |
| LC_LZ11 | Harvest Moon (gráficos) | sem descrição além de "just another format" |
| LC_LZ19 | Kirby Super Star, Earthbound (gráficos) | versão mais simples do LC_LZ3, usada pela HAL |
| LC_RLE1 | Super Mario World (dados) | usado nos fundos |

Formato marcado só com o nome do jogo no catálogo (como o LC_LZ11) não tem descrição em fonte nenhuma: trate como **não confirmado** até achar a rotina de descompressão no trace e comparar.

Os números dos formatos (ex.: `LC_LZ1 = 0`, `LC_LZ2 = 1`, `LC_LZ11 = 10`, `LC_RLE1 = 100`) vêm do `LunarDLL.def` de uma cópia antiga do código; confira no `.def` da versão que você baixar.

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

Variante muito comum fora da Nintendo: um byte de flags controla os 8 itens seguintes, e cada bit diz se o item é um literal (1 byte) ou uma referência (deslocamento + tamanho, normalmente em 2 bytes). Referências menores que o ponto de equilíbrio não são emitidas [Wikipedia: LZSS]. A maioria das implementações descende do código de Haruhiko Okumura (1989) [Wikipedia: LZSS]. Os parâmetros (tamanho da janela, valor inicial da janela, se o bit 1 é literal ou referência, ordem dos nibbles) mudam de jogo pra jogo: **não confirmado** nenhum valor "padrão" pra SNES; leia na rotina.

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
