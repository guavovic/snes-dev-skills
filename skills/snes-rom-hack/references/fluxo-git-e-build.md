# Fluxo de projeto com git, sem a ROM

## Princípio

O repositório guarda só o que é seu: fonte asm, gráficos novos, tabelas, scripts. A ROM original fica fora, num caminho local. O build:

1. Lê a ROM local.
2. Tira o cabeçalho de copiador se houver.
3. Confere o SHA-1 contra o valor esperado no repositório. ROM errada = para.
4. Copia pra `build/hack.sfc` e roda o asar nela.
5. Gera `build/hack.bps` com o flips.

Distribuir patch em vez de ROM é a regra da comunidade [SMWC] e o BPS é o formato que o flips recomenda [flips]; ele também confere o CRC32 da ROM de quem aplica [BPS].

## Estrutura mínima

```
meu-hack/
  .gitignore
  README.md
  rom-base.txt          hash esperado da ROM original
  build.py
  src/
    main.asm
    hooks.asm
  build/                ignorado
```

`.gitignore`:

```
*.sfc
*.smc
*.swc
*.fig
*.srm
build/
```

`rom-base.txt` (uma linha, sem a ROM):

```
sha1=0000000000000000000000000000000000000000
```

Troque pelo SHA-1 da ROM limpa (sem cabeçalho de copiador). Em PowerShell: `Get-FileHash rom.sfc -Algorithm SHA1`; em shell: `sha1sum rom.sfc`.

## `src/main.asm`

```asm
lorom

!checar_titulo ?= 0
if !checar_titulo
    check title "TITULO DO JOGO BASE  "
endif

incsrc "hooks.asm"
```

`check title` fica desligado no exemplo porque o título depende do jogo; troque pelo título real (21 caracteres) e ligue com `-Dchecar_titulo=1` [asar].

## `src/hooks.asm`

```asm
; Hook de exemplo em $00:8123 (endereço fictício).
; Original: A5 10 (lda $10) / 8D 00 02 (sta $0200)
org $008123
    autoclean jsl HookExemplo
    nop

freecode
HookExemplo:
    php
    sep #$20
    lda #$01
    sta.l $7E1F00       ; marca em WRAM (endereço ilustrativo)
    plp
    lda $10
    sta $0200
    rtl
```

`sta.l` usa endereço longo de propósito: WRAM `$7E` não depende de DB, então a rotina nem precisa trocar DB [asar]. Confira no mapa de RAM do seu jogo que o endereço está livre. Padrão completo de hook: `espaco-livre-e-hooks.md`.

## `build.py`

```python
import hashlib
import pathlib
import shutil
import subprocess
import sys

raiz = pathlib.Path(__file__).parent
esperado = (raiz / "rom-base.txt").read_text().strip().split("=", 1)[1].lower()
rom = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else raiz / "rom" / "base.sfc"

dados = rom.read_bytes()
if len(dados) % 1024 == 512:
    dados = dados[512:]
if hashlib.sha1(dados).hexdigest() != esperado:
    sys.exit("ROM base diferente da esperada em rom-base.txt")

saida = raiz / "build"
saida.mkdir(exist_ok=True)
limpa = saida / "base.sfc"
hack = saida / "hack.sfc"
limpa.write_bytes(dados)
shutil.copyfile(limpa, hack)

subprocess.run(["asar", "-werror", "--symbols=wla", str(raiz / "src" / "main.asm"), str(hack)], check=True)
subprocess.run(["flips", "--create", "--bps", str(limpa), str(hack), str(saida / "hack.bps")], check=True)
print("ok:", saida / "hack.bps")
```

Uso: `python build.py C:\caminho\da\rom.sfc`. Precisa de `asar` e `flips` no PATH. A ROM base precisa ter pelo menos 512 KB: o `freecode` do exemplo depende da autoexpansão do asar, que só acontece a partir de 512 KB (ver `mapeamento-e-expansao.md`).

## Boas práticas

- **Commit pequeno por hook ou recurso**, com o endereço tocado na mensagem.
- **README do hack** com o nome exato da ROM base e o hash (CRC32 e SHA-1), pra quem for aplicar conferir antes.
- **Release** = só o `.bps` e o README, nunca a ROM nem a ROM já patcheada.
- **Arquivo de símbolos** (`--symbols=wla`) no build local pra depurar no emulador.
- **Teste em emulador de alta precisão** (bsnes, Mesen) e, se der, em flash cart; emulador permissivo esconde erro de mapeamento e de timing.
- **Não versione `.srm`** (save) nem estado salvo.

## Variante: patch sem a ROM, com dois arquivos de mentira

Quando todo o código vai pra endereço fixo (`org`), dá pra gerar o patch sem a ROM original. É o que fazem o Super Metroid Practice Hack e o Combo Randomizer [SMPractice][SMZ3]:

1. Crie dois arquivos do tamanho da ROM, um só com `$00` e outro só com `$FF`.
2. Monte o mesmo `main.asm` nos dois, com `--no-title-check`.
3. Compare byte a byte: onde os dois são iguais, o asar escreveu; onde diferem, ficou o enchimento. Grave só os iguais num IPS.

O Map Rando e o VARIA também montam sem a ROM, mas com um arquivo só, pedindo o IPS direto ao asar (`--ips`) [MapRando][VARIA].

Ressalvas, deduzidas do funcionamento do método e não testadas nesta rodada:

- **Não combina com `freespace`/`freecode`.** A busca procura sequência de `freespacebyte`; no arquivo de `$FF` ela não acha o mesmo lugar que no de `$00`, ou não acha nada. Use `org` em faixa conhecida, como os projetos acima.
- **Não combina com patch que lê a ROM** (`read1()` e parecidos): o valor lido é o enchimento, não o jogo.
- **Desligue o recálculo do checksum** (`--fix-checksum=off`, como o Map Rando e o VARIA). Se o asar recalcular, os dois arquivos ganham checksums diferentes, e um byte que coincida por acaso entra no patch.
- O resultado é IPS, com os limites do formato (`patches-ips-bps.md`). Pra distribuir em BPS, aplique o IPS na ROM limpa e gere o BPS com o flips a partir dela.

## O exemplo rodado de verdade

Em 02/11/2026 o `main.asm` e o `hooks.asm` acima foram montados sem nenhuma mudança no asar 1.91, sobre uma ROM base própria (512 KB de zeros, com um RESET que grava `$42` em `$10` e pula pra `$8123`, onde estão os bytes `A5 10 8D 00 02` do comentário) [Teste local]:

- O asar expandiu a ROM de 512 KB pra 1 MB e mudou `$FFD7` pra `$0A`.
- Em `$8123` ficou `22 08 80 90 EA`: `JSL $90:8008` mais o `NOP`. O `freecode` foi pro offset `$80000` (banco `$90`), com a marca RATS "STAR" nos 8 bytes antes da rotina.
- `--symbols=wla` gerou o `hack.sym`.
- No Mesen 2.2.1 com `--testRunner`, um script Lua leu a WRAM no décimo quadro: na ROM base, `$7E:1F00` tinha lixo de power-on e `$0200` = `$42`; no hack, `$7E:1F00` = `$01` e `$0200` = `$42`. O hook rodou e as instruções refeitas também.

O passo do flips foi conferido em 11/11/2026: o Floating IPS v198 rodou a mesma linha de comando (`flips --create --bps limpa hack saida.bps`) sobre arquivos sintéticos e `flips --apply` devolveu o arquivo modificado igual byte a byte. O `build.py` para nesse passo se o `flips` não estiver no PATH.
