---
description: schematize-c — revisa C contra o piso: roda o gate (código + build) e depois lê o que a máquina não lê (sanitizers, memória, entrada externa, escopo)
argument-hint: "[arquivo.c/.h ou diretório]"
---

# /c-review

## 0. A pergunta que vem antes

**Isto é mesmo caso de C?** Componente novo de sistema **nasce em Rust ou Zig**
(`references/escopo.md`). Se for código novo sem ADR de exceção, o review termina aqui, com o
encaminhamento.

## 1. A máquina

```bash
bash .claude/skills/schematize-c/scripts/check-c.sh .     # lê o código E o build
make test-asan      # a suíte sanitizada — o gate NÃO substitui isto
make test-ubsan
make fuzz           # parser com libFuzzer/AFL++
```

`0` passa · `1` reprova · `2` **nada para verificar** (não é aprovação).

## 2. O que a máquina não lê

- **Sanitizers:** a suíte roda com **ASan e UBSan** no CI? o UBSan tem **`-fno-sanitize-recover=all`**
  (senão ele imprime e segue, e o CI fica verde com o defeito no log)? há **TSan** onde há thread?
- **Memória:** todo `malloc` tem **dono escrito** (quem libera)? todo `free` **anula** o ponteiro? a
  aritmética de ponteiro tem limite conhecido, e a soma `offset + len` é checada **contra overflow**
  antes de comparar com o tamanho?
- **Retorno:** conferido em `malloc`, `read`, **`write` (parcial!)**, `close`, `fclose` e
  `snprintf` — que **trunca e devolve o tamanho que teria**?
- **Entrada externa:** todo parser tem **fuzzing** no CI, com corpus versionado? o último crash
  virou **teste de regressão**?
- **Concorrência:** o que cada mutex protege está **escrito**? a ordem de aquisição é consistente
  (ordem inconsistente = deadlock)? nada de `volatile` fazendo papel de atômico?
- **Build:** `-Werror` ligado? `_FORTIFY_SOURCE` com `-O1`+ (em `-O0` ele **não faz nada**)? os dois
  compiladores (gcc e clang) rodam no CI?

## 3. Feche

Achado vira correção no mesmo PR ou item de checklist com dono. Mexeu no gate? rode o vermelho:
`bash scripts/check-c.test.sh` (10 casos).
