---
name: rust-style-guide
description: >
  Use when writing, reviewing, or refactoring Rust code, or settling Rust style
  and API design questions: module and import layout, ownership and borrowing,
  function signatures, error handling, traits, naming, concurrency, unsafe code,
  documentation, and formatting. Also use for Rust code review and for rustfmt
  or clippy configuration and lint disagreements.
---

# Rust Style Guide

Google's Rust style guide. It covers API and implementation design, not just
formatting. The full text is in `reference.md`; read the sections relevant to
the task instead of loading the whole guide.

## How to apply it

- Follow the official [Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/)
  and [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) first.
  This guide only overrides them where they conflict.
- **Library code:** API-design rules are binding. **Application code:** they are
  strong recommendations — favor simplicity and directness over reusability.
- Rules marked `[chrome]` or `[Fuchsia]` are codebase-specific; ignore them
  elsewhere.

## Highest-value rules

| Area | Rule |
|---|---|
| Imports | No glob imports (except `super::*` in inline modules, enum variants in their own methods, `pub use` re-exports, C++ namespace merging). One module per `use` statement. Import types unqualified, calls to top-level functions qualified (`mem::transmute`), traits locally. |
| Modules | Name files and leaf modules after their primary item (`mod foo`, `foo.rs`). Non-leaf modules contain only declarations and re-exports. |
| Ownership | Avoid `Rc`/`Arc` unless the alternative is unreasonably complex. Prefer borrowing over `.clone()`; clone only for a real deep copy. |
| Inputs | `&T` not `&Box<T>`; `&[T]` not `&Vec<T>`; `&str` not `&String`; `Option<&T>` not `&Option<T>`. Reusable library code accepts iterators/`impl IntoIterator`. |
| Outputs | Prefer iterators over `Vec<T>` in libraries; `Vec<T>` is fine in application code when it simplifies things. |
| Errors | `Option` for obvious failures, `Result` for recoverable failures that need context, `panic!` for bugs and violated invariants. |
| Types | Newtype over type alias when semantics differ or the type deserves an API. Prefer named fields over tuples and non-newtype tuple structs. |
| Traits | Define a trait only for generics, `impl Trait`/`dyn Trait`, or an extension trait — never just to organize code. Prefer generics over `dyn Trait` in libraries. Derive when possible. Extension traits use an `Ext` suffix. |
| Naming | `as_`/`to_`/`into_` conversions; `new`/`new_with_foo`/`try_new` constructors; `from_foo` plus a `From` impl; `foo`/`foo_mut`/`take_foo`/`set_foo`/`with_foo`/`replace_foo` accessors. Descriptive lifetimes; no needless abbreviations. |
| Cross-team APIs | `#[non_exhaustive]` on publicly exposed enums and public-field structs that may change. |
| Safety | Avoid `unsafe`; encapsulate it, add a `SAFETY:` comment and a justification. No unstable features. |
| Docs | Document public APIs, panic cases, and safety invariants with `///` and `//!`; Markdown is supported. Use `//` for implementation notes. Don't document what the code already says. |
| Implementation | Prefer `expect` over `unwrap`; pattern matching over check-then-unwrap; `format!`/`write!` instead of string `+`; no `catch_unwind`; no code before `main()`. |

## Source

Vendored from <https://google.github.io/styleguide/rustguide.html> (CC BY 3.0).
`reference.md` is the upstream text with presentation-only HTML converted to
Markdown; the rules are unchanged.
