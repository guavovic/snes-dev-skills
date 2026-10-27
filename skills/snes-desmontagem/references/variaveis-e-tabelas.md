# Variáveis na RAM e tabelas

## Achar uma variável pelo valor

Fluxo na janela Memory Search do Mesen [MesenCE src]:

1. Escolha o tamanho (byte, word, dword) e o formato (hex, com sinal, sem sinal).
2. Se o valor é visível (vidas = 3), compare com valor fixo, "igual a 3".
3. Se não é visível (posição, barra de energia), compare com o valor anterior: mude a situação no jogo e filtre por "maior", "menor", "igual" ou "diferente".
4. Repita até sobrar pouco. A lista mostra quantas vezes cada endereço foi lido, escrito e executado e o último acesso, o que já separa variável de lixo.

O bsnes-plus também tem busca na memória e o destaque de leitura e escrita no editor [bsnes-plus].

Dica de busca: o jogo pode guardar o valor de outro jeito (vidas 3 guardadas como 2, número em BCD, posição em ponto fixo). Se "igual a 3" não acha nada, use comparação com o valor anterior.

## Achar quem escreve e quem lê

1. **Breakpoint de escrita** no endereço achado. Quando parar, o PC mostra a instrução que escreveu; suba pela pilha ou pelo trace para achar a rotina [MesenCE src].
2. **Breakpoint de leitura** para achar quem usa o valor (desenho do HUD, teste de morte).
3. **Trace com breakpoint**: ligar o trace logger em volta do evento mostra o caminho completo até a escrita.
4. **Contadores de acesso**: a Memory Search mostra o último acesso; pelo Lua, `emu.getAccessCounters` e `emu.resetAccessCounters` dão contagens por endereço [MesenCE src].
5. **Callback de escrita em Lua**: `emu.addMemoryCallback(funcao, emu.callbackType.write, inicio, fim)` chama a função com endereço e valor antes da escrita, o que permite registrar todas as escritas de um quadro sem parar o jogo [MesenCE src]. Para saber o PC dentro do callback, use `emu.getState()` (ou `emu.getCpuState` no MesenCE); os nomes das chaves do estado podem mudar entre versões, confira no seu build (não confirmado).

Lembrete do mapa: a WRAM aparece em `$7E0000-$7FFFFF` e os primeiros 8 KB se espelham em `$0000-$1FFF` dos bancos de sistema [skill `snes-hardware`]. A mesma variável pode ser acessada por endereço curto ou longo; o breakpoint no tipo de memória `SnesWorkRam` pega os dois.

## Dar nome

- Nome pelo que faz, não por onde está: `jogador_vidas`, não `ram_0DBE`.
- Comece pelos acessos de hardware: o registrador já diz o que a rotina faz (escrita em `$2118` é VRAM, em `$420B` é DMA). Os nomes dos registradores estão em `snes-hardware`.
- Rotina chamada no NMI, rotina chamada de muitos lugares e rotina que escreve na variável que você achou são as primeiras a nomear.
- Guarde o nome no arquivo de labels assim que tiver certeza; use prefixo como `UNREACHABLE_` ou `UNK_` para o que ainda é dúvida. O jpdasm, por exemplo, marca código inalcançável com `UNREACHABLE_` mais o endereço [jpdasm].

## Tabela de ponteiros

Uma lista de endereços de 2 bytes (dentro do mesmo banco) ou de 3 bytes (endereço longo). Sinais típicos no código: índice multiplicado por 2 ou 3 (`ASL`), leitura indexada e uso do valor como endereço.

Como tratar:

1. Marque os bytes como ponteiro no desmontador (não como código).
2. Crie um label em cada destino.
3. Descubra o tamanho da tabela pelo maior índice usado no código; não conte até achar um valor estranho, porque a tabela seguinte pode parecer ponteiro válido.

O DiztinGUIsh permite marcar tipos de dado e cria labels de destino; o CDL do Mesen marca os destinos como dado lido, não como código, até que eles sejam executados [DiztinGUIsh][MesenCE src].

## Jump table

Variante em que os ponteiros são destinos de código: `JMP (abs,X)` ou `JSR (abs,X)` com X = índice × 2, ou um `JSL` para uma rotina que lê o ponteiro da pilha. O comportamento dessas instruções está em `snes-assembly` (`references/instrucoes.md`). O CDL ajuda: destinos executados recebem a flag de destino de salto `0x04` [MesenCE src]. Destinos nunca alcançados na sessão aparecem sem marca e precisam ser seguidos à mão.

## Tabela de caracteres (.tbl)

Jogos raramente guardam texto em ASCII. Uma tabela `.tbl` diz que byte (ou sequência de bytes) vira que caractere [Data Crystal TBL]:

```
00=A
01=B
1A=
FE01=[nome]
```

- Uma entrada por linha, `HEX=texto`, arquivo em UTF-8. Chave de vários bytes é lida na ordem em que aparece na ROM.
- `#` inicia comentário. `\HEX` (barra invertida) marca fim de texto e `*HEX` marca quebra de linha no formato descrito no Data Crystal.
- Códigos de controle (pausa, cor, nome do jogador) não têm sintaxe única: cada ferramenta usa a sua [Data Crystal TBL].
- O Mesen carrega só entradas simples `HEX=texto`, com número par de dígitos [MesenCE src].

Como montar uma: ache um texto conhecido na tela, busque na ROM a sequência de diferenças entre letras (técnica de "busca relativa": a diferença entre "A" e "B" é 1 qualquer que seja o código), e complete a tabela pelo que aparece em volta. A busca relativa é técnica comum de tradução amadora; a fonte consultada não a detalha (não confirmado como descrição oficial).

O texto que sai da ROM é do jogo: não versione texto extraído de jogo comercial, só a tabela e as ferramentas.
