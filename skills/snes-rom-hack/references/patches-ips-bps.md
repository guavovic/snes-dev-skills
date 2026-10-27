# Patches IPS e BPS

## IPS

Formato antigo, simples e ainda comum [sneslab][flips]:

```
"PATCH"                         5 bytes
registro, repetido:
  offset   3 bytes big-endian
  tamanho  2 bytes big-endian
  dados    "tamanho" bytes
  (se tamanho = 0, é RLE:)
    quantidade 2 bytes big-endian
    valor      1 byte, repetido "quantidade" vezes
"EOF"                           3 bytes
[truncar: 3 bytes big-endian]   opcional
```

- Offset de 3 bytes: limite de 16 MB [flips].
- O offset `$454F46` é "EOF" em ASCII: um registro ali seria lido como fim. O flips evita gerar esse offset [flips][sneslab].
- O campo de truncar depois do "EOF" é extensão (Lunar IPS, NINJA, SNESTool) [sneslab].
- Sem checksum: aplica em qualquer arquivo, inclusive a ROM errada ou com cabeçalho de copiador, e dá lixo sem aviso.

## BPS

Criado por byuu (Near) pra resolver os problemas do IPS [BPS][flips]:

```
"BPS1"
tamanho_origem    varint
tamanho_destino   varint
tamanho_metadado  varint
metadado          texto, pode ser vazio
ações             até 12 bytes antes do fim
crc32_origem      4 bytes little-endian
crc32_destino     4 bytes little-endian
crc32_patch       4 bytes little-endian (sobre tudo antes dele)
```

**Varint:** 7 bits por byte; o bit 7 em 1 marca o último byte; a cada byte depois do primeiro soma-se 1 antes de deslocar, pra não haver duas codificações do mesmo número [BPS][flips].

**Ação:** um varint `v`. Comando = `v & 3`, comprimento = `(v >> 2) + 1` [BPS]:

| Comando | Nome | Faz |
|---|---|---|
| 0 | SourceRead | Copia da origem, na mesma posição da saída |
| 1 | TargetRead | Lê bytes literais do patch |
| 2 | SourceCopy | Copia da origem a partir de um cursor relativo |
| 3 | TargetCopy | Copia do próprio destino já escrito (permite repetição) |

Os comandos 2 e 3 vêm seguidos de um varint de deslocamento relativo: bit 0 é o sinal, `valor >> 1` é a distância [BPS].

**Vantagens:** confere CRC32 da ROM de entrada e da saída (aplicar na ROM errada é recusado), trata bloco movido de lugar sem regravar tudo e não tem limite de 16 MB [BPS][flips].

## flips (Floating IPS)

Ferramenta de referência pra criar e aplicar IPS e BPS, de Alcaro [flips]. O repositório original está em modo de manutenção; o README aponta um fork em `git.disroot.org/Sir_Walrus/Flips` [flips].

```
flips --create --bps original.sfc hack.sfc hack.bps
flips --apply hack.bps original.sfc saida.sfc
flips -c original.sfc hack.sfc hack.bps
flips -a hack.bps original.sfc saida.sfc
flips -I hack.bps
```

- `-c` / `--create`, `-a` / `--apply`, `-I` / `--info` [flips].
- `-b` / `--bps` (padrão e recomendado, igual a `--bps-delta`), `--bps-linear` (mais rápido, patch maior), `-i` / `--ips` [flips].
- `--exact`: não mexe no cabeçalho de copiador. Sem ele, o flips tira o cabeçalho SMC ao criar e aplicar BPS [flips].
- `--ignore-checksum`: aplica mesmo com CRC32 diferente. Só pra diagnóstico [flips].
- `-m arquivo`: grava um manifesto [flips].

Sem instalar nada: Rom Patcher JS, no navegador, citado pelo próprio README do flips [flips].
