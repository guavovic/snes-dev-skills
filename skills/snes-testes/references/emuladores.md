# Escolher emulador para teste

A regra é testar onde o erro aparece: no emulador mais fiel ao console, depois no console. Emulador permissivo serve para conferir compatibilidade com o que o público usa, não para aprovar o código.

## Mesen 2 / MesenCE

- O SNESdev wiki o descreve como em desenvolvimento ativo, com a maioria dos recursos e provavelmente o emulador mais preciso disponível hoje, com depuração completa inclusive de símbolos do ca65 [SNESdev Tools].
- O repositório SourMesen/Mesen2 foi arquivado; o desenvolvimento segue no MesenCE (nesdev-org/MesenCE) [Mesen2 src][MesenCE src].
- É o único da lista com modo de teste automatizado por Lua e código de saída (`--testRunner`) conferido nesta pesquisa, no código e rodando a versão 2.2.1 [MesenCE src][Teste local].
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
- Não há comparação atual e confiável com Mesen e bsnes. O que existe é antigo:
  - A tabela de testes de precisão do TASVideos, editada pela última vez em 27/10/2014, dá ao snes9x 1.53 53 de 59 testes, contra 59 do higan v094. As falhas do snes9x são nos testes de ADC/SBC do blargg, num teste de OAM e numa linha do teste de cor. O Mesen não está na tabela [TASVideos SNES].
  - Num tópico do fórum do NESdev de 2019, um desenvolvedor mediu uso de CPU e sobra de vblank de uma demo e achou o snes9x igual ao console nessa medida, com bsnes e Mesen-S um pouco diferentes; na mesma conversa o autor do bsnes lembra que o snes9x emula por instrução, não por ciclo [NESdev fórum 2019]. É uma medida de uma demo só, em fórum: não serve para ranquear.
  - A versão mais recente publicada é a 1.63, de 09/07/2024 [snes9x]; nenhuma das duas fontes diz como ela se sai.

Conclusão desta skill: snes9x não aprova código. Ele confere compatibilidade com o emulador que o público usa, como já dizia a regra abaixo.

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
