# asar para ROM hack

asar é o montador 65816 da comunidade de Super Mario World, mantido por RPGHacker [asar]. Versão estável: 1.9; a 2.0 está em beta, com sintaxe de `freespace` mais rica. Os exemplos usam o que vale nas duas; o que é só da 2.0 está marcado. Sintaxe das instruções (sufixos `.b/.w/.l`, `bank`, `optimize`): skill `snes-assembly`.

Linha de comando: `asar [opções] patch.asm rom.sfc`. O asar escreve na própria ROM; trabalhe numa cópia.

## Mapper

`lorom`, `hirom`, `exlorom`, `exhirom`, `sa1rom`, `fullsa1rom`, `sfxrom`, `norom` [asar]. Sem diretiva, o asar tenta detectar pela ROM (ver `cabecalho-e-checksum.md`) e, sem certeza, usa LoROM. Declare sempre no topo do `main.asm`.

## Posição

- `org $endereço`: endereço SNES de destino; a tradução pra offset depende do mapper [asar].
- `base $endereço` / `base off`: monta como se estivesse em outro endereço (código copiado pra RAM) [asar].
- `pushpc` / `pullpc`: salva e volta a posição. Útil pra colocar um hook no meio de um bloco de freespace e continuar de onde parou [asar].
- `pushbase` / `pullbase`: o mesmo pro `base` [asar].
- `warnpc $endereço`: avisa se passou do limite. Está obsoleto; o manual recomenda `assert pc() <= $endereço` [asar].

## Espaço livre

```
; asar 1.9
freespace ram|noram[,align][,cleaned][,static][,$xx]
; asar 2.0
freespace ram|noram[,norats][,align][,cleaned][,static][,bankcross][,bank=n][,start=$x][,pin=label]
freecode   ; = freespace ram    (bancos $10-$3F)
freedata   ; = freespace noram  (prefere $40-$6F e $F0-$FF)
```

- `ram`: bloco acessível com a RAM baixa espelhada no banco (código). `noram`: só dado [asar].
- `align`: começa no início de um banco.
- `cleaned`: diz que nenhum `autoclean` aponta pro bloco de propósito (silencia o aviso).
- `static`: o bloco não pode mudar de tamanho entre aplicações do patch.
- `,$xx` (1.9): byte considerado livre nesse bloco.
- `start=` (2.0): começo da busca; o manual cita como útil pra jogos que não são SMW [asar].
- `bank=`, `bankcross`, `pin=` (2.0): banco fixo, permitir cruzar banco, ficar no mesmo banco de outro bloco [asar].
- `norats` (2.0): sem marca RATS.
- `freespacebyte $xx`: byte livre padrão (`$00`) [asar].
- A 2.0 tem também `segment` e `freespace_settings` [asar].

Cada bloco ganha uma marca RATS (8 bytes); teto de 125 blocos por patch [asar].

## Limpeza ao reaplicar

Reaplicar um patch não pode deixar o bloco antigo ocupando espaço. `autoclean` resolve:

- `autoclean jsl Rotina`, `autoclean jml Rotina`, `autoclean dl Tabela`: escreve a instrução ou o ponteiro e, antes, lê o que já estava ali; se apontava pra um bloco RATS antigo, libera esse bloco [asar].
- `autoclean $endereço`: só libera, sem escrever [asar].
- O alvo tem que estar na área expandida (banco `$10` em diante, em LoROM), e `autoclean` não pode ficar dentro de um bloco de freespace [asar].
- `prot Label1, Label2, ...`: dentro de um bloco de freespace, protege blocos que só são referenciados de lá (até 85 labels) [asar].

## Defines e macros

```asm
!velocidade = $02          ; define (substituição de texto)
!sufixo += _b              ; acrescenta texto, não soma número
!total #= 4*8              ; avalia agora e guarda o número
!opcional ?= 0             ; só define se ainda não existe
!copia := !velocidade      ; expande na hora

macro mover(origem, destino)
    lda <origem>
    sta <destino>
endmacro

%mover($10, $0200)
```

Defines começam com `!`, parâmetros de macro aparecem como `<nome>` e a chamada é `%nome(...)` [asar]. `-D nome=valor` na linha de comando cria define de fora (bom pra build de depuração) [asar].

## Arquivos

- `incsrc "arquivo.asm"`: inclui outro fonte, caminho relativo ao arquivo atual; `-I pasta` acrescenta pasta de busca [asar].
- `incbin arquivo.bin` ou `incbin arquivo.bin:inicio..fim`: inclui binário (gráfico, tabela), com faixa opcional [asar].

## Conferências

- `check title "TITULO DO JOGO       "`: 21 caracteres, inclusive os espaços do fim. Título diferente na ROM = erro; `--no-title-check` ignora [asar].
- `check bankcross off|half|full`: controla se cruzar banco é erro [asar].
- `assert condição, "mensagem"`, `error "..."`, `warn "..."`, `print "..."` [asar].

## Avisos e linha de comando

- `warnings push` / `warnings pull`, `warnings disable Wnome` / `warnings enable Wnome` [asar].
- `-werror`: aviso vira erro. Use no build de release [asar].
- `--symbols=wla` ou `--symbols=nocash`: arquivo de símbolos pro debugger [asar].
- `--fix-checksum=on|off`, `--no-title-check`, `-D`, `-I` [asar].
