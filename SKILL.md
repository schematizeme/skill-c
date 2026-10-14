---
name: schematize-c
metadata:
  version: 0.2.2
description: >-
  Piso defensivo de C para manter código existente (*.c/*.h, CMakeLists.txt, Makefile); componente novo nasce em Rust
  ou Zig, C só por ADR. Use ao revisar ou corrigir C: sanitizers no CI, -Werror, ownership, fuzzing de parser. Traz
  gate executável e template de CI.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de C da casa (schematize-c)

Esta skill é **defensiva**. Ela não existe para abrir a porta do C: existe para que o C que a casa
**já tem** ou que é **inevitável** não vire vulnerabilidade.

**Versão:** skill `schematize-c` v0.2.2. Changelog em `CHANGELOG.md`.

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:foraRol intro="Esta skill é o recorte **C** das linguagens **sancionadas fora do rol de backend** (`schematize-engineering` → `references/linguagens.md` §2.2): **manutenção defensiva**. Componente novo de sistema nasce em Rust ou Zig, por ADR; C não recebe serviço backend novo." cmd="c" -->Esta skill é o recorte **C** das linguagens **sancionadas fora do rol de backend** (`schematize-engineering` → `references/linguagens.md` §2.2): **manutenção defensiva**. Componente novo de sistema nasce em Rust ou Zig, por ADR; C não recebe serviço backend novo.

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização — a lib, o gate, a
   sintaxe da linguagem. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve; subagents `sonnet` por padrão, `opus` só após falha.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/c-*` cobrem só o piso da linguagem.<!-- /herdado -->

## A regra, antes de tudo

**Componente novo de sistema nasce em Rust ou Zig.** C entra por **ADR de exceção**, não por fit —
o nicho dele já está coberto por duas linguagens do rol que fazem o mesmo **com verificação**
(`references/escopo.md`).

## Comandos (Claude Code)

| Comando | O que faz |
|---|---|
| `/c-help` | lista os comandos |
| `/c-load` | carrega à força o corpo normativo (piso, escopo) |
| `/c-review` | revisa `.c`/`.h` e o build contra o piso: roda o gate e lê o que a máquina não lê |
| `/c-claude` | cria/mescla o `CLAUDE.md` sempre-on na raiz do repo |
| `/c-cc` · `/c-handoff` | context compact / handoff arquivado |

## Como usar

1. **Confirme que é caso de C** (`references/escopo.md`). Se for componente novo, a resposta é
   Rust/Zig, e o ADR tem de dizer **por que não**.
2. **Rode o gate:** `bash scripts/check-c.sh .` — `0` passa · `1` reprova · `2` **nada para
   verificar**. Ele lê o código **e o build**.
3. **Rode a suíte sanitizada** — o gate não substitui isso, e diz isso na saída.

Mapa de references:

| Tarefa | Reference |
|---|---|
| Sanitizers no CI, flags do build, memória e ownership, retorno conferido, fuzzing de parser, concorrência, teste | `references/piso.md` |
| **Onde C entra e por que ele NÃO é escolha de fit**; quando o ADR de exceção é legítimo; C que já existe; fronteira com C++ | `references/escopo.md` |
| Ferramental verificado (ASan/UBSan/TSan, `-Werror`, `_FORTIFY_SOURCE`, fuzzers) | `references/stack-versoes.md` |

Assets prontos para copiar: `assets/ci/github-actions-ci.yml` (clang-tidy, clang-format, build gcc/clang com `-fsanitize=address,undefined`, ctest) · `assets/lint/.clang-tidy` · `assets/lint/.clang-format`.

## Pisos inegociáveis (vetam o atalho)

1. **Componente novo nasce Rust/Zig.** C é ADR de exceção.
2. **A suíte roda sanitizada** (ASan, UBSan, TSan onde há thread) **no CI** — e **UBSan com
   `-fno-sanitize-recover=all`**, senão ele imprime e continua e o CI segue verde com o defeito no
   log.
3. **`-Wall -Wextra -Werror -Wconversion`.** `-Werror` é o que faz o aviso ser lido.
4. **`_FORTIFY_SOURCE` exige `-O1`+** — em `-O0` ele não faz nada.
5. **Todo `malloc` tem dono escrito**; `free(p); p = NULL;`.
6. **Retorno conferido sempre** — inclusive `write` parcial e `snprintf`, que **trunca e devolve o
   tamanho que teria**.
7. **VETADO:** `gets`, `strcpy`/`strcat`/`sprintf` sem limite, `scanf("%s")` sem largura, `alloca`
   com tamanho variável, `system()`.
8. **Parser tem fuzzing no CI**, com corpus versionado e crash virando teste de regressão.
9. **`<stdatomic.h>`, não `volatile`** — `volatile` não dá atomicidade nem ordem.
10. **Teste que passa sem sanitizer não prova ausência de UB** — prova só que não estourou desta vez.
11. <!-- herdado:engineering/orquestracao:curto -->**Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige, até 2 rodadas → re-decompõe → só então `opus`, com motivo). No overdev, cada item do checklist vai a um subagent e o principal revisa antes do `- [x]`. **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata (§9.6). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.<!-- /herdado -->

## Relação com as outras skills

- **`schematize-engineering`** — a base e o rol (`schematize-engineering → references/linguagens.md` §2.2, C como manutenção
  defensiva), que é quem manda na escolha de linguagem.
- **`schematize-cpp`** — C++ moderno. **C não é "C++ sem classes"**: as regras de UB, inicialização
  e conversão diferem, e misturar as mentalidades no mesmo arquivo é como o `.c` compilado como
  `.cpp` passa a ter outro comportamento.
- **`schematize-qa`** — a disciplina de teste; aqui ela roda **sanitizada**.
- **`schematize-pentest`** — o lado ofensivo (overflow, parser hostil, fuzzing dirigido).
