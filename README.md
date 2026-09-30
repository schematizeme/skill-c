# schematize-c

> **Skill defensiva.** Ela não abre a porta do C: **componente novo de sistema nasce em Rust ou
> Zig**, e C entra por **ADR de exceção**. Ela existe para que o C que a casa mantém (ou
> herda) **não vire vulnerabilidade** — com o piso sendo **ferramenta, não disciplina**.

Pacote de **skill normativa para [Claude Code](https://claude.com/claude-code)**.
Parte do catálogo **schematize skills**.

## Instalar

```bash
schematize install c
# ou
git clone https://github.com/schematizeme/skill-c.git /tmp/skill-c
bash /tmp/skill-c/install.sh .
```

## O que tem dentro

- **SKILL.md** — o contrato: 11 pisos inegociáveis + mapa de references.
- **references/** — `escopo` (onde C entra e por que **não** é escolha de fit),
  `piso` (sanitizers, flags, memória, retorno, fuzzing, concorrência), `stack-versoes`
  (ferramental **verificado rodando** nesta máquina).
- **scripts/** — `check-c.sh` (o gate: lê **o código e o build**) e `check-c.test.sh`
  (10 casos, 8 vermelhos).
- **assets/commands/** — `/c-help`, `/c-load`, `/c-review`, `/c-claude`, `/c-cc`,
  `/c-handoff`.
- **assets/CLAUDE.md** — regra sempre-on.

## Versão

**v0.1.0** — changelog em `CHANGELOG.md`.

## Regra de ouro

**UB não dá erro — ele autoriza o compilador a assumir que aquilo não acontece.** É por isso que o
piso é sanitizer no CI, e não boa vontade na revisão.

MIT.
