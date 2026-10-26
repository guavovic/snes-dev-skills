# AGENTS.md

Guia pra agente de código que vai usar ou mexer neste repositório.

## O que é

Skills de desenvolvimento pra Super Nintendo, uma pasta por tema em `skills/<nome>/`. Cada `SKILL.md` é curto e aponta pros arquivos de `references/`, que só são lidos quando o assunto aparece.

## Regras de conteúdo

- **Toda afirmação técnica tem fonte.** Endereço de registrador, bit, tempo em ciclos, formato de dado: citar a fonte no próprio arquivo (`[fullsnes]`, `[SNESdev wiki]`...), com a entrada completa em `docs/fontes.md`.
- **Duas fontes quando der.** Quando as fontes divergem, registrar a divergência e qual vale (de preferência a confirmada em hardware ou em emulador de alta precisão).
- **Nada de memória de modelo sem conferência.** Informação que não achou em fonte confiável não entra, ou entra marcada como "não confirmado".
- **Texto próprio.** Resumir e explicar com as próprias palavras; não copiar trechos longos de documento nem de manual.
- **Sem conteúdo de jogo comercial.** Nada de código desmontado, gráfico ou texto extraído de jogo: exemplos com código original nosso.
- Texto em pt-BR, com acento e sem travessão. Termo técnico consagrado fica em inglês (VRAM, DMA, HDMA, OAM). Arquivos em UTF-8 com fim de linha LF.
- Mudança que o usuário percebe entra no `CHANGELOG.md`, na seção da próxima versão.
