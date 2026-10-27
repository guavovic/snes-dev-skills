# Fluxo de projeto com git, sem a ROM

## Princípio

O repositório guarda só o que é seu: fonte asm, gráficos novos, tabelas, scripts. A ROM original fica fora, num caminho local. O build:

1. Lê a ROM local.
2. Tira o cabeçalho de copiador se houver.
3. Confere o SHA-1 contra o valor esperado no repositório. ROM errada = para.
4. Copia pra `build/hack.sfc` e roda o asar nela.
5. Gera `build/hack.bps` com o flips.

Distribuir patch em vez de ROM é a regra da comunidade [SMWC-2ª] e o BPS é o formato que o flips recomenda [flips]; ele também confere o CRC32 da ROM de quem aplica [BPS].

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

Uso: `python build.py C:\caminho\da\rom.sfc`. Precisa de `asar` e `flips` no PATH.

## Boas práticas

- **Commit pequeno por hook ou recurso**, com o endereço tocado na mensagem.
- **README do hack** com o nome exato da ROM base e o hash (CRC32 e SHA-1), pra quem for aplicar conferir antes.
- **Release** = só o `.bps` e o README, nunca a ROM nem a ROM já patcheada.
- **Arquivo de símbolos** (`--symbols=wla`) no build local pra depurar no emulador.
- **Teste em emulador de alta precisão** (bsnes, Mesen) e, se der, em flash cart; emulador permissivo esconde erro de mapeamento e de timing.
- **Não versione `.srm`** (save) nem estado salvo.

O exemplo não foi montado num asar nesta pesquisa; a sintaxe segue o manual [asar].
