# Piso de C (schematize-c) — sempre-on

> **Componente novo de sistema nasce em Rust ou Zig.** C entra por **ADR de exceção**, não por
> fit. O que segue vale para o C que já existe ou que o ADR autorizou.

1. **A suíte roda sanitizada no CI:** ASan, UBSan **com `-fno-sanitize-recover=all`** (sem isso ele
   imprime e continua, e o CI fica verde), TSan onde há thread.
2. **`-Wall -Wextra -Werror -Wconversion`** — `-Werror` é o que faz o aviso ser lido.
3. **`_FORTIFY_SOURCE` exige `-O1`+** (em `-O0` não faz nada) + `-fstack-protector-strong`.
4. **Todo `malloc` tem dono escrito**; `free(p); p = NULL;`.
5. **Retorno conferido sempre** — `write` **parcial** e `snprintf` (que **trunca** e devolve o
   tamanho que teria) inclusive.
6. **VETADO:** `gets`, `strcpy`/`strcat`/`sprintf` sem limite, `scanf("%s")` sem largura, `alloca`
   com tamanho variável, `system()`.
7. **Aritmética de ponteiro só com limite conhecido**, e a soma checada contra overflow.
8. **Parser tem fuzzing no CI**, com corpus versionado e crash virando teste.
9. **`<stdatomic.h>`, não `volatile`**; ordem de aquisição de locks documentada.
10. **Teste que passa sem sanitizer não prova ausência de UB.**
11. **Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e
    revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige →
    re-decompõe → só então `opus`, com motivo). Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.

Gate: `bash .claude/skills/schematize-c/scripts/check-c.sh .`
