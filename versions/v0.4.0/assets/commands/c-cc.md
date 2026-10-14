---
description: schematize-c — context compact: grava o handoff no archive e roda /compact.
---
Antes de compactar, grave o handoff em `<projeto>/<projeto>_archive/context/`, no par
context + checklist do padrão da `schematize-archive` (prefixo `AAAA-MM-DD-<slug>-`): o que foi
escrito/revisado, o que o `check-c.sh` acusou e ficou aberto, o estado do **fuzzing** (corpus,
últimos crashes virando teste), o que ficou com `#pragma diagnostic ignored` **e por quê**, e o
**ADR de exceção** que justifica o C existir aqui. Só então rode `/compact`.
