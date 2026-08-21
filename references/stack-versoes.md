# Anexo volátil — ferramental (C)

> Parte da skill **schematize-c**. **Fonte volátil:** prazo de validade, atualizado à parte do corpo
> normativo (regra `anexo-volatil` do lint).
>
> **Verificado em: 2026-08-21**, rodando na máquina de referência (Debian, **gcc 14.2.0**).

## Padrão e compilador

- **Piso: `-std=c17`** (ou o que a plataforma alvo suportar), **explícito** — nunca o default do
  compilador, que varia entre versões e distribuições.
- **Dois compiladores no CI** (gcc e clang) quando possível: cada um pega avisos que o outro não
  emite, e a diferença entre eles costuma ser um UB real.

## Ferramental

| Ferramenta | Papel | Verificado em 2026-08-21 |
|---|---|---|
| **ASan** (`-fsanitize=address`) | use-after-free, overflow, leak | ✔ reproduziu use-after-free com `gcc 14.2` |
| **UBSan** (`-fsanitize=undefined -fno-sanitize-recover=all`) | comportamento indefinido | ✔ reproduziu overflow de `int` com sinal |
| **TSan** (`-fsanitize=thread`) | data race | job separado (não convive com ASan) |
| **`-Werror`** | avisos viram erro | ✔ `-Wall -Wextra -Werror` reprovou uso de variável não inicializada |
| **`_FORTIFY_SOURCE=3`** | checagem de tamanho em libc | exige `-O1`+ — em `-O0` **não faz nada** |
| **libFuzzer / AFL++** | fuzzing de parser | corpus versionado, crash vira teste |
| **valgrind** | o que ASan não pega, e quando não dá para recompilar | |
| **clang-tidy / cppcheck** | análise estática | complementa, não substitui os sanitizers |

## Regra que NÃO é volátil

`gets`, `strcpy` sem limite, retorno não conferido, UBSan **sem** `-fno-sanitize-recover` e parser
sem fuzzing são VETADOS **em qualquer versão**. E **componente novo nasce Rust/Zig** — C entra por
ADR de exceção.
