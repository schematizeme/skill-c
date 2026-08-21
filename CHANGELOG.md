# Changelog — schematize-c

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [0.1.0] — 2026-08-21

Primeira versão, e **defensiva por decisão**: a vistoria de 2026-08-21 registrou que a casa tem **zero código em C hoje** e que o nicho **já está coberto por Rust e Zig no rol** — *o valor desta skill não é "mais opções de backend"*. Ela existe para que o C que a casa venha a manter (ou herdar) **não vire vulnerabilidade**.

### Adicionado
- **`references/escopo.md`** — a regra que rege tudo: **componente novo de sistema nasce em Rust ou Zig**; C entra por **ADR de exceção**, não por fit, porque o nicho (controle manual, interop, embarcado) **já está coberto por duas linguagens do rol que fazem o mesmo com verificação**. Com os casos legítimos nomeados (kernel/driver/firmware, embarcado com toolchain fechada, biblioteca que a casa já mantém, interop de ABI) e o que o ADR precisa registrar.
- **`references/piso.md`** — o piso **como ferramenta, não disciplina**, porque *em C o programa errado compila* e o erro não é exceção, é **UB**: **ASan/UBSan/TSan no CI** — com o detalhe que mais engana, **`-fno-sanitize-recover=all`**, sem o qual o UBSan *imprime e continua* e o CI segue verde com o defeito no log; flags (`-Werror` como o que **faz o aviso ser lido**, `-Wconversion` como o que pega a conversão implícita silenciosa, e **`_FORTIFY_SOURCE` que em `-O0` não faz nada**); ownership escrito e `free(p); p = NULL;`; **retorno conferido sempre** (incluindo `write` parcial e o `snprintf` que **trunca e devolve o tamanho que teria**); **fuzzing para todo parser**; e `<stdatomic.h>` no lugar de `volatile`.
- **`scripts/check-c.sh`** + **`check-c.test.sh`** (**10 casos**, 8 vermelhos) — o gate lê **o código e o build**: `gets`, `strcpy`/`strcat`/`sprintf`, `alloca`, `system()`, `volatile` em contexto de thread, `free` sem anular, função com estado global; e no build: sem `-Werror`, sem ASan, sem UBSan, **UBSan sem `-fno-sanitize-recover`**, ASan+TSan no mesmo alvo.

### Verificado rodando (gcc 14.2.0, nesta máquina)
- **ASan** reproduziu `heap-use-after-free` com `arquivo:linha`.
- **UBSan** reproduziu `signed integer overflow` — e o **mesmo programa sem sanitizer imprimiu `-2147483648` e saiu 0**, que é exatamente o modo de falha que a skill descreve.
- **`-Wall -Wextra -Werror`** reprovou uso de variável não inicializada (exit 2).
