#!/usr/bin/env bash
# schematize-c — o gate. Cobra o piso de `references/piso.md` sobre o C do repo.
#
# ALCANCE: textual + verificação do BUILD (quando há Makefile/CMake, ele confere se as flags e os
# sanitizers exigidos aparecem). Ele NÃO substitui rodar a suíte sanitizada — e diz isso.
#
# strict-ok: COLETOR — varre tudo e soma os achados (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail

raiz="${1:-.}"
erros=(); avisos=()

fontes=()
while IFS= read -r -d '' f; do fontes+=("$f"); done < <(
  find "$raiz" -type f \( -name '*.c' -o -name '*.h' \) \
    -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/vendor/*' \
    -not -path '*/third_party/*' -not -path '*/versions/*' -print0 2>/dev/null
)
builds=()
while IFS= read -r -d '' f; do builds+=("$f"); done < <(
  find "$raiz" -maxdepth 3 -type f \( -name 'Makefile' -o -name 'makefile' -o -name 'CMakeLists.txt' -o -name 'meson.build' \) \
    -not -path '*/.git/*' -print0 2>/dev/null
)

if [ "${#fontes[@]}" -eq 0 ]; then
  echo "✖ nenhum .c/.h em $raiz — nada para verificar (ausência de material não é aprovação)." >&2
  exit 2
fi

# ------------------------------------------------------------------ 1. o build
if [ "${#builds[@]}" -eq 0 ]; then
  avisos+=("sem Makefile/CMakeLists/meson no topo — não deu para conferir as flags do piso (piso.md secao 3)")
else
  todos="$(cat "${builds[@]}" 2>/dev/null)"
  grep -qE '\-Werror' <<< "$todos" \
    || erros+=("build sem \`-Werror\` — aviso que não quebra o build vira ruído em três semanas (piso.md secao 3)")
  grep -qE '\-Wall' <<< "$todos" || erros+=("build sem \`-Wall\`")
  grep -qE '\-Wextra' <<< "$todos" || avisos+=("build sem \`-Wextra\`")
  grep -qE '\-Wconversion' <<< "$todos" \
    || avisos+=("build sem \`-Wconversion\` — é o que pega a conversão implícita silenciosa, a família de bug que mais vira vulnerabilidade em C")
  grep -qE 'fsanitize=address' <<< "$todos" \
    || erros+=("nenhum alvo com \`-fsanitize=address\` — a suíte tem de rodar sanitizada (piso.md secao 2)")
  grep -qE 'fsanitize=undefined' <<< "$todos" \
    || erros+=("nenhum alvo com \`-fsanitize=undefined\` — UB não estoura sozinho: ele funciona por dois anos e falha no dia errado")
  if grep -qE 'fsanitize=undefined' <<< "$todos" && ! grep -qE 'fno-sanitize-recover' <<< "$todos"; then
    erros+=("UBSan **sem** \`-fno-sanitize-recover=all\` — ele IMPRIME e CONTINUA, e o CI segue verde com o defeito no log (é o erro nº 1 de quem já usa UBSan)")
  fi
  if grep -qE '_FORTIFY_SOURCE' <<< "$todos" && ! grep -qE '\-O[123s]' <<< "$todos"; then
    avisos+=("\`_FORTIFY_SOURCE\` sem \`-O1\`+ — em \`-O0\` ele NÃO faz nada")
  fi
  grep -qE 'fsanitize=address' <<< "$todos" && grep -qE 'fsanitize=thread' <<< "$todos" \
    && grep -qE 'fsanitize=address.*fsanitize=thread|fsanitize=thread.*fsanitize=address' <<< "$todos" \
    && erros+=("ASan e TSan no MESMO alvo — eles não convivem; são dois jobs")
fi

# ------------------------------------------------------------------ 2. o código
for f in "${fontes[@]}"; do
  nome="${f#"$raiz"/}"
  # strings fora, depois comentário de linha (ordem importa)
  codigo="$(sed -e 's/"[^"]*"/""/g' -e "s/'[^']*'/''/g" -e 's|//.*$||' "$f")"

  grep -qE '(^|[^_a-zA-Z])gets\s*\(' <<< "$codigo" \
    && erros+=("$nome: \`gets\` — removido do padrão C11 por ser indefensável")
  grep -qE '(^|[^_a-zA-Z])(strcpy|strcat|sprintf)\s*\(' <<< "$codigo" \
    && erros+=("$nome: \`strcpy\`/\`strcat\`/\`sprintf\` sem limite — use as versões com tamanho e CONFIRA o retorno (snprintf trunca e devolve o tamanho que teria)")
  grep -qE 'scanf\s*\(\s*""' <<< "$codigo" && grep -qE '%s' "$f" \
    && avisos+=("$nome: \`scanf\` com \`%s\` — sem largura máxima é overflow direto")
  grep -qE '(^|[^_a-zA-Z])alloca\s*\(' <<< "$codigo" \
    && erros+=("$nome: \`alloca\` — stack controlado por tamanho variável; em caminho com input externo é o atacante escolhendo o tamanho da pilha")
  grep -qE '(^|[^_a-zA-Z])system\s*\(' <<< "$codigo" \
    && erros+=("$nome: \`system()\` — injeção de comando; use \`exec*\` com argumentos separados")
  grep -qE '\bvolatile\b' <<< "$codigo" && grep -qE 'pthread|thread' "$f" \
    && ! grep -qE 'stdatomic|_Atomic' "$f" \
    && erros+=("$nome: \`volatile\` em contexto de thread — \`volatile\` NÃO dá atomicidade nem ordem; o certo é \`<stdatomic.h>\`")
  grep -qE '(^|[^_a-zA-Z])(strtok|localtime|strerror|asctime|ctime)\s*\(' <<< "$codigo" \
    && avisos+=("$nome: função com estado global (\`strtok\`/\`localtime\`/\`strerror\`…) — use a variante \`_r\`")
  # free sem anular
  grep -qE '(^|[^_a-zA-Z])free\s*\(' <<< "$codigo" && ! grep -qE '=\s*NULL' "$f" \
    && avisos+=("$nome: \`free\` sem anular o ponteiro no arquivo — o free não zera, e o use-after-free costuma ser um ponteiro que 'continuou válido'")
  # malloc com retorno ignorado (heurística: malloc numa linha sem atribuição nem if)
  grep -qE '^\s*malloc\s*\(' <<< "$codigo" \
    && erros+=("$nome: retorno de \`malloc\` descartado")
  grep -qE '#\s*pragma\s+GCC\s+diagnostic\s+ignored' "$f" \
    && ! grep -qE '#\s*pragma\s+GCC\s+diagnostic\s+ignored.*(/\*|//)' "$f" \
    && avisos+=("$nome: \`#pragma diagnostic ignored\` sem comentário justificando e sem escopo mínimo")
done

for a in "${avisos[@]:-}"; do [ -n "$a" ] && echo "  ! $a" >&2; done
if [ "${#erros[@]}" -gt 0 ]; then
  echo "" >&2
  echo "✖ C REPROVADO — ${#erros[@]} problema(s) em ${#fontes[@]} arquivo(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  echo "  Lembre: em C o programa ERRADO compila. O piso é ferramenta, não disciplina." >&2
  exit 1
fi
echo "✔ c: ${#fontes[@]} arquivo(s) e ${#builds[@]} build(s) no piso — e isto NÃO substitui rodar a suíte sanitizada."
