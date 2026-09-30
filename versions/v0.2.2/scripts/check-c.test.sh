#!/usr/bin/env bash
# Vermelho primeiro do gate de C.
#
# strict-ok: harness de teste — continua depois de um caso vermelho (`schematize-shell` -> `references/piso.md` secao 1)
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-c.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM
ok=0; fail=0

MAKE_BOM='CFLAGS = -std=c17 -O2 -g -Wall -Wextra -Werror -Wconversion -D_FORTIFY_SOURCE=3
SAN_ASAN = -fsanitize=address -fno-omit-frame-pointer
SAN_UB   = -fsanitize=undefined -fno-sanitize-recover=all
test-asan: ; $(CC) $(CFLAGS) $(SAN_ASAN) -o t src/*.c && ./t
test-ubsan: ; $(CC) $(CFLAGS) $(SAN_UB) -o t src/*.c && ./t
'

caso() { # <nome> <exit> <agulha> [makefile-alternativo]
  local nome="$1" esp="$2" agulha="$3" mk="${4:-$MAKE_BOM}"
  local d="$TMP/$nome"; mkdir -p "$d/src"; cat > "$d/src/alvo.c"
  printf '%s' "$mk" > "$d/Makefile"
  local saida; saida="$(bash "$G" "$d" 2>&1)"; local rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $nome: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $nome: exit certo, saída sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $nome"; ok=$((ok+1))
}

echo "== verde de partida =="
caso verde 0 "no piso" <<'FIX'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Dono: o CHAMADOR libera com free(). */
char *duplicar(const char *origem, size_t max) {
    size_t n = strnlen(origem, max);
    char *saida = malloc(n + 1);
    if (saida == NULL) {
        return NULL;
    }
    memcpy(saida, origem, n);
    saida[n] = 0;
    return saida;
}

int main(void) {
    char *s = duplicar("ola", 16);
    if (s == NULL) {
        return 1;
    }
    if (printf("%s\n", s) < 0) {
        free(s);
        s = NULL;
        return 1;
    }
    free(s);
    s = NULL;
    return 0;
}
FIX

echo "== funções indefensáveis =="
caso gets 1 "removido do padrão" <<'FIX'
#include <stdio.h>
int main(void) { char b[16]; gets(b); return 0; }
FIX
caso strcpy 1 "sem limite" <<'FIX'
#include <string.h>
void copiar(char *d, const char *o) { strcpy(d, o); }
FIX
caso alloca 1 "o atacante escolhendo o tamanho da pilha" <<'FIX'
#include <alloca.h>
void ler(unsigned n) { char *b = alloca(n); (void)b; }
FIX
caso system 1 "injeção de comando" <<'FIX'
#include <stdlib.h>
void rodar(const char *cmd) { system(cmd); }
FIX

echo "== concorrência =="
caso volatile-thread 1 "NÃO dá atomicidade" <<'FIX'
#include <pthread.h>
static volatile int pronto = 0;
void *trabalhar(void *arg) { (void)arg; pronto = 1; return NULL; }
FIX

echo "== o build =="
caso sem-werror 1 "vira ruído em três semanas" 'CFLAGS = -std=c17 -O2 -Wall -fsanitize=address -fsanitize=undefined -fno-sanitize-recover=all
' <<'FIX'
int main(void) { return 0; }
FIX
caso sem-asan 1 "fsanitize=address" 'CFLAGS = -std=c17 -O2 -Wall -Wextra -Werror -fsanitize=undefined -fno-sanitize-recover=all
' <<'FIX'
int main(void) { return 0; }
FIX
caso ubsan-que-continua 1 "IMPRIME e CONTINUA" 'CFLAGS = -std=c17 -O2 -Wall -Wextra -Werror -fsanitize=address -fsanitize=undefined
' <<'FIX'
int main(void) { return 0; }
FIX

echo "== nada para verificar =="
d="$TMP/vazio"; mkdir -p "$d"; echo "# prosa" > "$d/LEIA.md"
saida="$(bash "$G" "$d" 2>&1)"; rc=$?
if [ "$rc" = 2 ] && grep -q "não é aprovação" <<<"$saida"; then echo "  ✔ repo sem C sai 2 (não 0)"; ok=$((ok+1))
else echo "  ✖ repo sem C: exit $rc"; fail=$((fail+1)); fi

echo; echo "check-c: $ok ok, $fail falha(s)"; [ "$fail" = 0 ]
