# Labels, mapas e organização de projeto

## Arquivo de labels do Mesen (.mlb)

Uma linha por label [MesenCE src]:

```
TipoDeMemoria:ENDERECO[-FIM]:Nome[:Comentario]
```

- `TipoDeMemoria` é o nome do tipo de memória do Mesen, por exemplo `SnesWorkRam` para a WRAM e `SnesPrgRom` para a ROM.
- `ENDERECO` é o offset dentro desse tipo de memória, em hex: na ROM é o offset no arquivo (sem cabeçalho de copiador), na WRAM é a distância desde o começo dela.
- `-FIM` opcional dá um intervalo (um vetor de 16 bytes, por exemplo).

Exemplo original:

```
SnesWorkRam:0100:jogador_x:posição horizontal em pixels
SnesWorkRam:0102:jogador_y
SnesWorkRam:0200-020F:fila_de_sons
SnesPrgRom:8000:inicio_do_banco_01
```

O Mesen também importa `.sym` (formato do WLA-DX quando o arquivo contém `[labels]` ou `wlalink`), `.dbg` do ca65, `.fns`, `.elf` e `.cdb` [MesenCE src]. O bsnes-plus lê símbolos do WLA-DX, do FMA e do VICE [bsnes-plus]. Os projetos de desmontagem distribuem um `.sym` por versão do jogo para carregar no debugger [SMWDisX].

## Mapa de RAM e mapa de ROM

Não há formato padrão. O que os projetos fazem:

- **Mapa de RAM como código**: um arquivo de defines ou labels com um nome por endereço, incluído no build (`rammap.asm` no SMWDisX, `symbols_wram.asm`, `symbols_sram.asm` e `symbols_apu.asm` no jpdasm) [SMWDisX][jpdasm]. Vantagem: o mesmo arquivo serve para montar e para documentar.
- **Mapa por banco**: o Super Metroid tem logs anotados por banco ($80 a $DF) com mapas de RAM, VRAM e SRAM no site do PJBoy; esses logs não são reassembláveis, são documentação [PJ bank logs].
- **Registradores de hardware num arquivo próprio** (`hardware_registers.asm` no SMWDisX) [SMWDisX].

Para o mapa de ROM, a divisão natural é um arquivo por banco (`bank_00.asm`, `bank_01.asm`...), que é o que SMWDisX e jpdasm fazem [SMWDisX][jpdasm].

## Como se organizam as desmontagens conhecidas

Só a estrutura; nada do código dos jogos é reproduzido aqui.

### Super Mario World: SMWDisX

Monta no asar 1.91 [SMWDisX].

- Arquivos `bank_XX.asm`, mais `smw.asm` (raiz), `macros.asm`, `constants.asm`, `rammap.asm` e `hardware_registers.asm`; pastas separadas para gráficos, fases, efeitos e samples; `.sym` por versão; scripts `PATCH.bat` e `.sh`.
- Uma variável `!_VER` escolhe entre cinco versões do jogo, e o build compara o resultado com a ROM original de cada versão.
- Regras de formato: label em linha própria, indentação de 4 espaços, comentário na coluna 46 e sufixo de tamanho `.B`, `.W` ou `.L` obrigatório nas instruções.

### Zelda: A Link to the Past: jpdasm

Versão japonesa 1.0, licença GPL-3.0, montador Futaba [jpdasm].

- `bank_00.asm` a `bank_1F.asm`, `symbols_wram.asm`, `symbols_sram.asm`, `symbols_apu.asm`, `values.asm`, `Makefile` e um script Python que extrai os binários.
- Os binários do jogo não estão no repositório: são extraídos da ROM do usuário. O README lista CRC32, MD5 e SHA1 da ROM esperada.
- Cada linha tem um marcador de endereço; código inalcançável recebe o prefixo `UNREACHABLE_`.
- Credita a desmontagem da versão americana de MathOnNapkins e o DiztinGUIsh.

### Super Metroid

- Logs anotados por banco no site do PJBoy, com mapas de memória, que servem de documentação mas não montam [PJ bank logs].
- A mesma página aponta uma versão reassemblável mantida por outra pessoa (InsaneFirebat), não conferida nesta pesquisa (não confirmado).

### EarthBound: ebsrc

ca65 2.19 e spcasm [ebsrc].

- Pastas `include/` e `src/`, `snes.cfg` (configuração do linker), `charsets.yaml`.
- A ferramenta `ebbinex` extrai os binários da ROM do usuário a partir de um arquivo yml por versão (EarthBound, Mother 2, protótipo).
- Build com `make`. O objetivo declarado é virar uma decompilação.

### Estilo pret (Game Boy, como referência de organização)

Os projetos pret não são de SNES, mas são o modelo mais copiado de desmontagem organizada [pokered]:

- Pastas por função: `constants/`, `data/`, `engine/`, `gfx/`, `home/`, `macros/`, `maps/`, `ram/`, `text/`.
- `layout.link` define onde cada seção cai na ROM; `roms.sha1` guarda o hash de cada ROM que o projeto produz; versão do montador fixada num arquivo; CI que confere o hash.

### Reimplementações em C (não são desmontagens)

snesrev/zelda3, sm e smw reescrevem os jogos em C e precisam da ROM para extrair recursos [snesrev]. Servem de consulta de lógica, mas não de modelo de projeto byte a byte.

## Esqueleto sugerido para um projeto novo

Síntese do que os projetos acima têm em comum, com asar (a montagem e o hash estão detalhados em `snes-rom-hack`, `references/fluxo-git-e-build.md`):

```
meu-jogo-dis/
  main.asm             raiz: mapper, incsrc dos bancos
  bank_00.asm ...      um arquivo por banco
  ram.asm              mapa de RAM como defines
  hardware.asm         nomes dos registradores
  macros.asm
  labels/meu-jogo.mlb  labels para o debugger
  tabelas/texto.tbl
  ferramentas/extrai.py  tira os binários da ROM do usuário
  rom.sha1             hash da ROM original esperada
  .gitignore           *.sfc, *.smc, binários extraídos
```

Critério de pronto: montar e obter uma ROM com o mesmo hash da original [SMWDisX][jpdasm][pokered].
