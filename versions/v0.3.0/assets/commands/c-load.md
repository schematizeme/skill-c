---
description: schematize-c — carrega à força TODO o corpo normativo do piso de C e passa a aplicá-lo nesta sessão.
---
Carregue **agora** o corpo normativo da skill `schematize-c`
(`.claude/skills/schematize-c/references/*.md`):

- `escopo.md` — **primeiro**, porque ele decide se você deveria estar escrevendo C: **componente
  novo de sistema nasce em Rust ou Zig**, e C entra por **ADR de exceção**, não por fit. Traz os
  casos legítimos (kernel/driver/firmware, embarcado com toolchain fechada, biblioteca já mantida,
  interop de ABI), o que o ADR registra, e a regra do C que já existe.
- `piso.md` — o piso **como ferramenta, não disciplina** (em C **o programa errado compila**):
  **ASan/UBSan/TSan no CI**, com **`-fno-sanitize-recover=all`** — sem ele o UBSan *imprime e
  continua* e o CI segue verde; flags (`-Werror`, `-Wconversion`, `_FORTIFY_SOURCE` que **em `-O0`
  não faz nada**); ownership escrito e `free(p); p = NULL;`; **retorno conferido sempre** (inclusive
  `write` parcial e `snprintf`, que **trunca e devolve o tamanho que teria**); **fuzzing para todo
  parser**; `<stdatomic.h>` em vez de `volatile`.
- `stack-versoes.md` — ferramental **verificado rodando** nesta máquina (gcc 14.2): ASan reproduziu
  use-after-free, UBSan reproduziu overflow com sinal, `-Werror` reprovou variável não inicializada.

Depois, rode o gate: `bash .claude/skills/schematize-c/scripts/check-c.sh .` — e **rode a suíte
sanitizada**, que o gate não substitui.
