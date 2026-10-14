# Onde C entra — e por que ele NÃO é escolha de fit

> Parte da skill **schematize-c**. Esta seção é a razão de a skill existir: ela é **defensiva**.

---

## 1. A regra

**Componente novo de sistema nasce em Rust ou Zig.** C entra por **ADR de exceção**, não por fit.

A diferença é deliberada: no rol sancionado
(`schematize-engineering` → `references/linguagens.md`), a escolha é **por encaixe** — cada
linguagem tem um lugar onde ganha. C **não** é oferecido assim, porque o nicho dele (controle
manual, interop, embarcado) **já está coberto** por duas linguagens do rol que fazem o mesmo com
verificação: **Rust** (garantia em compilação) e **Zig** (controle explícito, sem UB silencioso na
maioria dos caminhos).

## 2. Quando o ADR de exceção é legítimo

- **Kernel, driver, firmware** onde a toolchain alvo só tem C.
- **Embarcado** com compilador proprietário/certificado que não suporta outra linguagem.
- **Biblioteca de sistema existente** que a casa mantém (não reescreve por decreto).
- **Interop obrigatória** em que a ABI é C e a camada precisa ser mínima — e, mesmo aí, o **wrapper**
  costuma ser melhor em Rust/Zig, com o C reduzido ao mínimo.

O ADR registra: **por que não Rust/Zig**, **qual é a superfície** em C, **quem mantém**, e **como se
sai** (se um dia sair).

## 3. C que já existe: mantém-se, com o piso ligado

Não se reescreve por gosto — reescrita de C maduro troca bugs conhecidos por bugs novos. A regra é a
mesma do resto do catálogo: **fica como está até ser tocado**, e o que for tocado passa a cumprir
`piso.md` (sanitizers no CI, `-Werror`, fuzzing do parser). Extração para Rust/Zig acontece **por
fronteira** (um módulo com contrato claro), com o teste de equivalência antes de desligar o antigo.

## 4. O que esta skill NÃO é

- **Não é uma porta para "backend em C".** Serviço novo nasce no rol; C não vira opção por
  desempenho — as opções do rol já cobrem isso.
- **Não é um curso de C.** É o piso mínimo para que o C que a casa toca **não vire vulnerabilidade**.
- **Não substitui a `schematize-pentest`** no lado ofensivo, nem a `schematize-engineering` no piso
  comum (segredo, testes, DoD, archive).

## 5. Fronteira com C++

`schematize-cpp` cobre C++ moderno (RAII, ownership por tipo, sem `new`/`delete` cru). **C não é
"C++ sem classes"**: as duas têm regras distintas de UB, de inicialização e de conversão implícita, e
misturar as duas mentalidades no mesmo arquivo é como o `.c` compilado como `.cpp` passa a ter outro
comportamento. Decida a linguagem do módulo, e escreva-a de verdade.
