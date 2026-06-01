Use `docs/runa-coding-guide.md` before writing any Runa code here.
Runa truth lives in `../RunaLang/spec/` and `../RunaLang/std/*.rna`.
Write only spec-backed Runa syntax, never guessed or Rust-shaped syntax.
Use `lib.rna` or `main.rna`; child modules live at `name/mod.rna`.
Declare every child module explicitly with `mod name`.
Use explicit `use` imports; `std` is available but never ambient.
Use `fn` or `suspend fn`, `struct`, `enum`, `opaque type`, `trait`, `impl`.
Use `callee :: args :: call` and `receiver.member :: args :: method`.
Use `select`, `repeat`, `let`, and `let-else`; no `if` or `match`.
Model ownership explicitly with `read`, `edit`, `take`, and explicit `hold`.
Fail loudly on unsupported syntax or uncovered spec areas.
