# Comunidade

## SMW Central

Maior comunidade de ROM hacking de SNES, centrada em Super Mario World, e de onde vem o asar [asar]. O site ao vivo pede verificação humana; as regras abaixo vêm das páginas oficiais arquivadas no Internet Archive (datas em `fontes.md`) [SMWC].

Regras de envio de hack (seção Hacks):

- **Só BPS.** O envio é um ZIP com o patch BPS, mais créditos e README opcionais. Mais de um BPS que não seja versão alternativa é rejeitado na hora, e patch quebrado ou em formato inválido também, "incluindo patches IPS" [SMWC].
- **Tem que rodar na última versão estável do bsnes ou do Snes9x**, com a configuração padrão. Parte da moderação testa em console [SMWC].
- **Pelo menos três capturas de tela** tiradas de emulador, enviadas fora do ZIP [SMWC].
- **No máximo dois envios** esperando moderação por conta; o terceiro é removido [SMWC].
- **ROM nunca.** Subir ROM ou linkar site que distribui ROM comercial é contra as regras; o BPS só carrega a diferença e quem baixa aplica na própria ROM com o Floating IPS [SMWC][flips].

A fonte secundária [SMWC-2ª] dizia "BPS preferido"; a regra oficial é mais dura: IPS é recusado.

Convenções que nasceram lá e servem fora do SMW: RATS, `autoclean`, `freecode`/`freedata` [asar].

## romhacking.net

Arquivo histórico de hacks, traduções, utilitários e documentos de todas as plataformas. Fechou pra envios em 01/08/2024, por decisão do administrador (Nightcrawler); o site ficou só leitura e o banco de dados (sem contas de usuário) foi entregue ao Internet Archive [alternativeto][timeextension]. Bom pra documento antigo e ferramenta clássica; não espere atualização.

## Etiqueta de distribuição

- Distribua patch (BPS), nunca ROM [SMWC][flips].
- Diga qual é a ROM base (nome, região, revisão e hash) no README.
- Credite patches e ferramentas de terceiros usados e respeite a permissão de quem fez.

## Hacks grandes como referência

Projeto aberto serve de modelo de organização. Aqui só a estrutura pública do repositório, sem código de jogo.

**z3randomizer** (base em asm do randomizador de A Link to the Past, licença MIT) [z3randomizer]:

- **Um arquivo por recurso** (`boots.asm`, `hud.asm`, `save.asm`...) e um arquivo raiz que inclui todos.
- **Hooks separados** num `hooks.asm`, longe da lógica nova: dá pra ver de uma vez tudo o que muda no código original.
- **Endereços em arquivo próprio:** `ram.asm`, `sram.asm`, `registers.asm` e `vanillalabels.asm` (rótulos do jogo original) concentram os números mágicos.
- **ROM fora do repositório:** o `build.sh` copia `../alttp.sfc` pra `../working.sfc` e roda o asar nessa cópia, o mesmo princípio de `fluxo-git-e-build.md`.

O que as fontes lidas mostram como prática comum: patch BPS, ROM base identificada, código montado com asar e espaço livre marcado com RATS [SMWC][asar]. Outros projetos grandes (Super Metroid Map Rando, VARIA) não foram lidos.
