# O piso de C da casa — defensivo, porque o padrão é NÃO escrever C

> Parte da skill **schematize-c**. Ela existe para o C que **já existe** ou que é **inevitável**
> (kernel, driver, embarcado sem alternativa, biblioteca de sistema que você tem de manter). Para
> **componente novo**, a resposta da casa é **Rust ou Zig** — ver `escopo.md`.

Convenção: **MUST** = o gate cobra · **VETADO** = piso.

---

## 1. A premissa: o compilador não protege você

Em C, **o programa errado compila**. Não há verificação de limite, de tempo de vida, de inicialização
nem de tipo forte na borda — e o resultado do erro não é exceção: é **comportamento indefinido**, que
significa literalmente *qualquer coisa*, inclusive "funcionou na sua máquina por dois anos".

Por isso o piso desta skill é **ferramenta**, não disciplina: a disciplina falha em silêncio, a
ferramenta falha ruidosamente.

## 2. Sanitizers — obrigatórios, no CI

**MUST:** a suíte roda **três vezes**, e cada uma pega uma classe:

```bash
# 1) memória: use-after-free, buffer overflow, leak
cc -O1 -g -fsanitize=address -fno-omit-frame-pointer …
# 2) comportamento indefinido: overflow com sinal, shift inválido, ponteiro desalinhado
cc -O2 -g -fsanitize=undefined -fno-sanitize-recover=all …
# 3) concorrência (se há thread): data race
cc -O2 -g -fsanitize=thread …
```

- **`-fno-sanitize-recover=all` no UBSan** — senão ele **imprime e continua**, e o CI segue verde
  com o defeito no log. (Este é o erro nº 1 de quem "já usa UBSan".)
- **ASan e TSan não convivem** no mesmo binário: são dois jobs.
- **Sanitizer é para teste, não para produção** (custo de 2–10×) — mas **um build de produção sem a
  suíte sanitizada é um build sem verificação**.
- **`valgrind`** ainda vale para o que ASan não pega (uso de memória não inicializada em alguns
  casos), e é a saída quando não dá para recompilar.

## 3. Flags — o build é parte do piso

**MUST**, em todo alvo:

```
-std=c17 -Wall -Wextra -Werror -Wconversion -Wshadow -Wpointer-arith
-Wformat=2 -Wvla -Wcast-qual -Wstrict-prototypes
-D_FORTIFY_SOURCE=3 -fstack-protector-strong
-fPIE -pie -Wl,-z,relro,-z,now,-z,noexecstack
```

- **`-Werror` não é rigor: é o que faz o aviso ser lido.** Aviso que não quebra o build vira ruído
  em três semanas.
- **`-Wconversion`** é o que pega a conversão implícita silenciosa (`int` → `size_t`, truncamento) —
  a família de bug que mais vira vulnerabilidade em C.
- **`_FORTIFY_SOURCE` exige otimização** (`-O1`+): em `-O0` ele **não faz nada**, e o build de debug
  passa a ter menos proteção do que você pensa.
- **VETADO** desligar warning com `#pragma` sem comentário justificando e sem escopo mínimo.

## 4. Memória — as regras que não se negociam

- **Todo `malloc` tem dono declarado** (quem libera) no comentário da função que aloca. Ownership
  que não está escrito é ownership que se perde na terceira refatoração.
- **`free(p); p = NULL;`** — o `free` não zera o ponteiro, e o use-after-free costuma ser um
  ponteiro que continuou "válido".
- **Nunca aritmética de ponteiro sem limite conhecido.** Índice vem com o tamanho, sempre; e a soma
  `offset + len` é checada **contra overflow** antes de comparar com o tamanho.
- **VETADO:** `gets` (removido do padrão), `strcpy`/`strcat`/`sprintf` sem limite,
  `scanf("%s")`, `alloca` com tamanho variável, VLA em caminho que vê input externo (é stack
  controlado pelo atacante).
- **Use as versões com tamanho** (`snprintf`, `memcpy_s`/`strlcpy` onde existir) — e **cheque o
  retorno**: `snprintf` **trunca e devolve o tamanho que teria**, então ignorar o retorno é ignorar
  a truncagem.

## 5. Erro é retorno, e retorno se confere

- **MUST:** conferir o retorno de **toda** função que pode falhar — `malloc`, `read`, `write`,
  `close`, `fclose`, `snprintf`. `write` **parcial** é a falha esquecida clássica.
- **`errno` só é válido depois de uma falha declarada** — não o leia "para ver".
- **VETADO** `exit()` no meio de biblioteca: quem decide morrer é o programa, não a lib.
- **Nada de estado global mutável** sem sincronização declarada; `strtok`, `localtime`, `strerror`
  têm variantes `_r` — use-as.

## 6. Fuzzing — para todo parser

**MUST:** todo código que lê **entrada externa** (arquivo, rede, protocolo, formato) tem harness de
fuzzing (`libFuzzer`/AFL++) rodando no CI, com **corpus versionado** e **crash reproduzível** como
teste de regressão.

Não é luxo: é o único método que encontra o caso que ninguém imaginou — e parser é onde o C erra.

## 7. Concorrência

- **`pthread` com invariantes escritas:** o que cada mutex protege, e a **ordem** de aquisição
  (ordem inconsistente = deadlock).
- **Atômico é `<stdatomic.h>`**, não `volatile` — `volatile` **não** dá garantia de ordem nem de
  atomicidade (é o mal-entendido mais comum de C).
- **TSan no CI** onde há thread.

## 8. Teste

Disciplina da **`schematize-qa`**. Aqui: a suíte roda **sanitizada** (§2), e cobertura mede o que o
fuzzer não alcança. **Teste que passa sem sanitizer não prova ausência de UB** — prova só que não
estourou desta vez.
