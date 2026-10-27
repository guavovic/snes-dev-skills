# Escolher emulador para teste

A regra é testar onde o erro aparece: no emulador mais fiel ao console, depois no console. Emulador permissivo serve para conferir compatibilidade com o que o público usa, não para aprovar o código.

## Mesen 2 / MesenCE

- O SNESdev wiki o descreve como em desenvolvimento ativo, com a maioria dos recursos e provavelmente o emulador mais preciso disponível hoje, com depuração completa inclusive de símbolos do ca65 [SNESdev Tools].
- O repositório SourMesen/Mesen2 foi arquivado; o desenvolvimento segue no MesenCE (nesdev-org/MesenCE) [Mesen2 src][MesenCE src].
- É o único da lista com modo de teste automatizado por Lua e código de saída (`--testRunner`) conferido nesta pesquisa [MesenCE src].
- Opções úteis em teste: RAM inicial `Random`, `AllZeros` ou `AllOnes`, estado de power on aleatório, mapeamento de placa estrito [MesenCE src].
- O debugger pode parar em leitura de memória não inicializada, em acesso inválido ao PPU e em leitura durante o auto-joypad, o que transforma bug silencioso em parada [MesenCE src].

**Uso:** emulador principal de teste e de depuração.

## bsnes, higan e ares

- **bsnes**: o README atual se descreve com foco em desempenho, recursos e facilidade de uso, com emulação de baixo nível de todos os coprocessadores [bsnes].
- **higan**: o emulador multissistema do mesmo autor (byuu/Near), de onde vem a linha de precisão; o **ares** é descendente do higan e do bsnes e se declara focado em precisão e preservação, mais lento por isso [ares].
- O snes-rom-hack desta coleção também recomenda bsnes e Mesen para teste [skill `snes-rom-hack`].

**Uso:** segunda opinião de precisão. Se Mesen e bsnes (ou ares) concordam e o console discorda, suspeite de flash cart ou de diferença de revisão do console.

## snes9x

- Emulador portátil, com repositório oficial ativo [snes9x].
- As fontes consultadas não comparam a precisão dele com Mesen e bsnes (não confirmado).

**Uso:** conferir se o hack roda no emulador que muitos jogadores usam, depois de passar nos precisos.

## Por que não o ZSNES

Segundo a wiki de fãs consultada, que é fonte de confiança baixa [ZSNES wiki]:

- O ZSNES priorizava velocidade sobre precisão.
- O SuperFX tinha clock errado.
- Hacks testados só no ZSNES quebravam em emuladores precisos e no console, porque o ZSNES aceitava coisas que o hardware recusa.
- O speedrun.com proibiu ZSNES, no$sns e o bSNES antigo para runs em março de 2019 (mesma fonte, não conferido em segunda fonte).

Como a fonte é fraca, a recomendação desta skill se apoia também no ponto positivo bem documentado: há emuladores precisos e ativos (acima). Não existe motivo para testar no ZSNES, e "funciona no ZSNES" não é evidência de nada.

## Tabela rápida

| Emulador | Papel no teste | Teste automatizado conferido |
|---|---|---|
| Mesen 2 / MesenCE | Principal | Sim, `--testRunner` com Lua |
| bsnes / ares | Segunda opinião de precisão | Não pesquisado |
| snes9x | Compatibilidade com o público | Não pesquisado |
| ZSNES | Nenhum | Não |
