---
name: schematize-c
metadata:
  version: 0.1.0
description: O piso de C da casa — DEFENSIVO, porque o padrão é não escrever C. Componente novo de sistema nasce em **Rust ou Zig**; C entra por **ADR de exceção**, não por fit (kernel, driver, embarcado sem alternativa, biblioteca que a casa já mantém). Para o C que existe, o piso é **ferramenta, não disciplina** — em C o programa errado compila, e o erro não é exceção, é comportamento indefinido: **ASan/UBSan/TSan no CI** (com `-fno-sanitize-recover=all`, senão o UBSan imprime e continua e o CI segue verde), `-Wall -Wextra -Werror -Wconversion`, `_FORTIFY_SOURCE` (que em `-O0` não faz nada), ownership escrito, `free` que anula o ponteiro, retorno conferido sempre, **fuzzing para todo parser**, `<stdatomic.h>` em vez de `volatile`. Traz gate executável que também lê o build.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de C da casa (schematize-c)

Esta skill é **defensiva**. Ela não existe para abrir a porta do C: existe para que o C que a casa
**já tem** ou que é **inevitável** não vire vulnerabilidade.

**Versão:** skill `schematize-c` v0.1.0. Changelog em `CHANGELOG.md`.

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

## Relação com as outras skills

- **`schematize-engineering`** — a base e o rol (`references/linguagens.md`), que é quem manda na
  escolha de linguagem.
- **`schematize-cpp`** — C++ moderno. **C não é "C++ sem classes"**: as regras de UB, inicialização
  e conversão diferem, e misturar as mentalidades no mesmo arquivo é como o `.c` compilado como
  `.cpp` passa a ter outro comportamento.
- **`schematize-qa`** — a disciplina de teste; aqui ela roda **sanitizada**.
- **`schematize-pentest`** — o lado ofensivo (overflow, parser hostil, fuzzing dirigido).
