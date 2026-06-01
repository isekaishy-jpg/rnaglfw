# General Runa Coding Guide For `rnaglfw`

This guide is the local coding contract for writing Runa in `rnaglfw`.
It is derived from the current `RunaLang` specs and bundled `std` surface.
When this guide and the spec disagree, the spec wins.

## Source Of Truth

Start from these current sources, in this order:

- `../RunaLang/spec/llm.md`
- `../RunaLang/spec/sema/modules-and-visibility.md`
- `../RunaLang/spec/sema/functions.md`
- `../RunaLang/spec/sema/types.md`
- `../RunaLang/spec/sema/type-aliases.md`
- `../RunaLang/spec/sema/traits-and-impls.md`
- `../RunaLang/spec/sema/where.md`
- `../RunaLang/spec/sema/callables.md`
- `../RunaLang/spec/sema/invocation.md`
- `../RunaLang/spec/sema/control-flow.md`
- `../RunaLang/spec/sema/bindings.md`
- `../RunaLang/spec/sema/patterns.md`
- `../RunaLang/spec/sema/expressions-and-operators.md`
- `../RunaLang/spec/sema/value-semantics.md`
- `../RunaLang/spec/sema/scalars.md`
- `../RunaLang/spec/sema/char-family.md`
- `../RunaLang/spec/sema/conversions.md`
- `../RunaLang/spec/sema/result-and-option.md`
- `../RunaLang/spec/sema/attributes.md`
- `../RunaLang/spec/sema/consts.md`
- `../RunaLang/spec/sema/literals.md`
- `../RunaLang/spec/sema/collections.md`
- `../RunaLang/spec/sema/collection-capabilities.md`
- `../RunaLang/spec/sema/arrays.md`
- `../RunaLang/spec/sema/tuples.md`
- `../RunaLang/spec/sema/standard-constructors.md`
- `../RunaLang/spec/sema/standard-collection-apis.md`
- `../RunaLang/spec/sema/lifetimes-and-regions.md`
- `../RunaLang/spec/sema/memory-core.md`
- `../RunaLang/spec/sema/memory-capabilities.md`
- `../RunaLang/spec/sema/allocator-families.md`
- `../RunaLang/spec/sema/allocator-strategies.md`
- `../RunaLang/spec/sema/raw-pointers.md`
- `../RunaLang/spec/sema/text-and-bytes.md`
- `../RunaLang/spec/sema/async-and-concurrency.md`
- `../RunaLang/spec/sema/send.md`
- `../RunaLang/spec/sema/defer.md`
- `../RunaLang/spec/sema/handles.md`
- `../RunaLang/spec/sema/reflection.md`
- `../RunaLang/spec/sema/observability.md`
- `../RunaLang/spec/sema/domain-state-roots.md`
- `../RunaLang/spec/sema/domain-state-surface.md`
- `../RunaLang/spec/sema/unsafe.md`
- `../RunaLang/spec/backend/c-abi.md`
- `../RunaLang/spec/backend/layout-and-repr.md`
- `../RunaLang/spec/backend/dynamic-libraries.md`
- `../RunaLang/spec/backend/boundary-kinds.md`
- `../RunaLang/spec/backend/boundary-contracts.md`
- `../RunaLang/spec/toolchain/manifest-and-products.md`
- `../RunaLang/spec/toolchain/packages-and-build.md`
- `../RunaLang/spec/toolchain/check-and-test.md`
- `../RunaLang/spec/toolchain/build.md`
- `../RunaLang/spec/toolchain/package-commands.md`
- `../RunaLang/std/prelude/mod.rna`
- `../RunaLang/std/collections/mod.rna`
- `../RunaLang/std/text/mod.rna`
- `../RunaLang/std/view/mod.rna`
- `../RunaLang/std/memory/mod.rna`
- `../RunaLang/std/iter/mod.rna`
- `../RunaLang/std/range/mod.rna`
- `../RunaLang/std/task/mod.rna`
- `../RunaLang/std/dylib/mod.rna`
- `../RunaLang/std/reflect/mod.rna`
- `../RunaLang/std/observe/mod.rna`

Use the repo-local compiler, not the PATH launcher:

- `../RunaLang/target/debug/runa.exe`

## Package, Products, And Modules

Runa package structure is explicit.

- Every package uses `runa.toml`.
- Every package with `[package]` declares at least one `[[products]]`.
- A manifest may be package-only, workspace-only, or a combined workspace-root
  package manifest.
- Optional manifest sections include `[build]` and `[[native_links]]`.
- `[workspace].members` uses relative directory paths, not package names or
  globs.
- `lib` and `cdylib` default to `lib.rna`.
- `bin` defaults to `main.rna`.
- Child modules are declared explicitly with `mod name`.
- A child module lives at `name/mod.rna`.
- There is no implicit file discovery and no multi-file module merging.
- Dependencies are explicit.
- The bundled `std` package is the compiler-provided exception and never goes
  in `[dependencies]`.

First-wave dependency forms include:

- exact version string
- `{ version = ... }`
- `{ version = ..., registry = ... }`
- `{ path = ... }`
- `{ version = ..., path = ... }`

General package rules:

- v1 dependency version matching is exact.
- `{ path = ... }` is path-based local resolution.
- `{ version = ..., path = ... }` still resolves by `path`; `version` is a
  validation constraint.
- `path` and `registry` do not combine.
- `[build].target` selects the explicit build target when present.

Minimal package manifest:

```toml
[package]
name = "rnaglfw"
version = "2026.0.01"
edition = "2026"
lang_version = "0.00"

[[products]]
kind = "lib"
```

Minimal layout:

```text
rnaglfw/
  runa.toml
  lib.rna
  window/
    mod.rna
```

## Product Kinds And Entry Rules

First-wave product kinds:

- `bin`
- `lib`
- `cdylib`

Rules:

- `lib` is the ordinary Runa library product.
- `cdylib` is the C ABI dynamic-library product.
- `pub` alone never exports a foreign symbol from `cdylib`; explicit
  `#export[...] extern[...] fn` declarations do.
- A `bin` product entry is exactly one top-level `main` in the product root.
- First-wave `main` may be `fn main` or `suspend fn main`.
- `main` must be zero-arg, non-generic, and non-lifetime-parameterized.
- First-wave `main` return types are only `Unit` or `I32`.
- `Unit` entry returns exit code `0`.

## Imports And Visibility

Rules:

- Visibility is private by default.
- The only visibility levels are private, `pub(package)`, and `pub`.
- Imports are explicit and module-local.
- Import paths are absolute, never `super`-style.
- Wildcard imports are not part of v1.
- `std` is always importable, but never ambient.
- `use std.prelude` is the sanctioned bulk facade import.
- There is no flat `std/mod.rna` root file to rely on.
- Bundled `std` is compiler-provided and not declared in user manifests.
- The compiler may lazily load only referenced `std` modules.

Current useful bundled facades:

- `std.prelude` reexports `Eq`, `Hash`, `Option`, `Result`, `Iterator`,
  `Iterable`, `IndexRange`, `IndexSpan`, `View`, `Contiguous`, `Str`, `Bytes`,
  `ByteBuffer`, `MaybeStr`, `CStr`, `Utf16`, `Utf16Buffer`, `List`, `Map`,
  task helpers, dynamic library helpers, and observe helpers.
- Specific modules still matter:
  - `std.text`
  - `std.collections`
  - `std.view`
  - `std.memory`
  - `std.iter`
  - `std.range`
  - `std.task`
  - `std.dylib`
  - `std.observe`
  - `std.reflect`

Examples:

```runa
pub mod window
pub(package) mod internal

use std.prelude
use std.text.{MaybeStr, decode_utf8, decode_c_string}
use std.memory.{Arena, ArenaSpec, GrowthPolicy}
use std.dylib.{DynamicLibrary, open_library, lookup_symbol, close_library}

pub use window.Window
```

## Core Declarations

Functions and suspend functions:

```runa
fn name[Params](arguments) -> ReturnType:
    ...

suspend fn name[Params](arguments) -> ReturnType:
    ...
```

Rules:

- Return types are always explicit.
- Parameters are named bindings, not patterns.
- Accepted parameter forms are `name: T`, `read name: T`, `edit name: T`,
  and `take name: T`.
- `where` goes between the signature and the body.
- User packages do not use `#hosted`; that is bundled `std` only.
- There is no overloading, default arguments, or local nested `fn`.

Type aliases:

```runa
type DWORD = CUInt
type TokenTable = Map[Str, Token]
```

Rules:

- `type Name = ExistingType` creates no new nominal identity.
- Type aliases are module items.
- Type aliases may take type parameters and `where` constraints.
- Local type aliases are not part of v1.
- `impl Alias` and `impl Trait for Alias` are not part of v1.

Named types:

```runa
pub struct WindowSpec:
    pub title: Str
    pub width: Index
    pub height: Index

pub enum Event:
    Quit
    Resize:
        width: Index
        height: Index

pub opaque type Window
```

Traits and impls:

```runa
pub trait Drawable:
    fn draw(read self) -> Unit

impl Window:
    fn resize(edit self, width: Index, height: Index) -> Unit:
        ...

impl Drawable for Window:
    fn draw(read self) -> Unit:
        ...
```

Rules:

- Dispatch is static.
- Inherent methods live in `impl Type`.
- Trait impls use `impl Trait for Type`.
- Traits may declare associated types and associated consts.
- Inherent impls may declare associated consts.
- Accepted receivers are `read self`, `edit self`, `take self`, and explicit
  retained-borrow `self` values.
- There are no trait objects, extension methods, or dynamic dispatch.

## Generics, `where`, And Lifetimes

Generic and lifetime parameters share one bracket list.

Examples:

```runa
fn apply[F](read f: F, take x: I32) -> I32
where F: CallRead[I32, I32]:
    return f :: x :: call

fn choose['a, 'b, T](take left: hold['a] read T, take right: hold['b] read T) -> hold['b] read T
where 'a: 'b:
    ...
```

Rules:

- `where` is real semantic constraint law, not descriptive text.
- `where` supports trait bounds, projection equality, and outlives predicates.
- Lifetime names are explicit source-level names like `'a`, `'b`, and
  `'static`.
- Retained borrows crossing boundaries use `hold['a] read T` and
  `hold['a] edit T`.
- Local retained-borrow formation uses explicit `hold` expressions:
  - `hold read place`
  - `hold edit place`
- Plain ephemeral `read T` and `edit T` do not become retained borrows
  implicitly.
- No higher-ranked lifetime surface and no explicit `region` syntax are part of
  v1.

## Scalars, `Char`, `Index`, And `IndexRange`

Current core scalar families include:

- `Unit`
- `Bool`
- `Char`
- signed integers: `I8`, `I16`, `I32`, `I64`, `I128`
- unsigned integers: `U8`, `U16`, `U32`, `U64`, `U128`
- machine-width integers: `ISize`, `USize`
- floating-point families: `F32`, `F64`

Structural domains:

- `Index` is the ordered position and count domain.
- `IndexRange` is the range domain over `Index`.
- `Index` is distinct from `ISize` and `USize`.
- `Index` and `IndexRange` are ordered structural domains, not general
  arithmetic domains.

Practical rules:

- Unsuffixed integer literals default to `I32` when unconstrained.
- Unsuffixed decimal literals default to `F64` when unconstrained.
- Integer literals in `Index` and `IndexRange` contexts infer those domains.
- `Char` is one Unicode scalar value, not one byte, one UTF-16 code unit, or a
  grapheme cluster.
- `Char` is distinct from `Str`, `Utf16`, `CChar`, and `CWChar`.
- The explicit first-wave `Char` conversion directions that matter most are:
  - `Char -> U32`
  - `U32 -> Maybe[Char]`

## Construction And Patterns

Construction law is stricter than the old guide assumed.

- `Type :: ... :: call` is constructor invocation.
- Inline construction is positional only.
- Block construction is named only.
- Inline named construction is not part of v1.
- `opaque type` does not imply a public constructor.
- Enum variants are constructor targets.

Examples:

```runa
let quit = Event.Quit :: :: call
let value = Option.Some :: 10 :: call

let spec = WindowSpec :: :: call
    title = "Demo"
    width = 1280
    height = 720
```

Pattern rules:

- Use `select value:` for pattern matching.
- Supported v1 patterns are `_`, binding names, literals, consts, exact tuples,
  exact structs, and enum variants.
- Struct and named-field variant patterns are exact.
- No spread, rest, or partial named-field patterns.
- Plain `let` and `repeat ... in ...` use irrefutable patterns only.

## Tuples And Arrays

Tuples:

- Tuple arity starts at `2`.
- Singleton tuples are not part of v1.
- Tuple projection uses `.0`, `.1`, `.2`, and so on.
- Tuples are structural and order-sensitive.
- Multi-argument callable packing uses tuples at the contract level.

Examples:

```runa
let pair = (width, height)
let x = pair.0
let (left, right) = pair
```

Arrays:

- The fixed-size array type form is `[T; N]`.
- `N` is a compile-time integer constant.
- Array literal forms are:
  - `[a, b, c]`
  - `[value; N]`
- `array[i]` is strict and bounds-checked.
- Array subranges return view-style results, not implicit copies.
- Arrays are valid C-layout fields when the element type is C ABI-safe, but
  arrays are not direct foreign function parameters or returns in v1.

## Value Semantics And Ownership

Runa is move-oriented by default.

- Owned values move by default.
- Copyability is narrow and explicit.
- Implicitly copyable first-wave values include scalar families, `Index`,
  `IndexRange`, raw pointers, foreign function pointers, and formed named
  function values.
- Nominal families are not implicitly copyable.
- `Str`, `Bytes`, `ByteBuffer`, `Utf16`, `Utf16Buffer`, views, collections,
  tasks, and handles are not implicitly copyable.

Ownership modes:

- `name: T` and `take name: T` are owned-value parameters.
- `read name: T` is an ephemeral shared borrow.
- `edit name: T` is an ephemeral exclusive mutable borrow.
- Retained borrows appear as `hold['a] read T` and `hold['a] edit T`.
- `&read T` and `&edit T` are first-class reference values.

Practical authoring rules:

- Default to owned values until the API actually needs borrowing.
- Use `read` for inspection-only APIs.
- Use `edit` only when the caller must pass a mutable place.
- Do not assume the compiler will synthesize retained borrows for you.
- `&` means reference to a place, never shared ownership.
- Local `let` bindings are mutable local places in v1.

## Invocation

Runa uses qualified phrase invocation.

Core forms:

```runa
callee :: args :: call
Type :: args :: call
receiver.member :: args :: method
```

Rules:

- Zero-arg calls keep the empty middle slot:
  - `main :: :: call`
  - `task.await :: :: method`
- Ordinary non-foreign top-level calls are capped at `5` arguments.
- Invocation blocks are structured payload only, not statement bodies.
- Nested invocation expressions used as plain arguments should usually be
  parenthesized or hoisted into a local first.

Examples:

```runa
window.resize :: :: method
    width = 1920
    height = 1080

let ok = Result.Ok :: () :: call
let err = Result.Err :: InitError.NoWindow :: call
```

## Callables And Function Values

Callability is an explicit contract, not a syntax category.

Important callable contracts:

- `CallRead[In, Out]`
- `CallEdit[In, Out]`
- `CallTake[In, Out]`
- `SuspendCallRead[In, Out]`
- `SuspendCallEdit[In, Out]`
- `SuspendCallTake[In, Out]`

Rules:

- `:: call` works for named functions, constructor targets, typed callbacks,
  and explicit callable values implementing one of the callable contracts.
- Closures, lambdas, and implicit capture objects are not part of v1.
- Named functions become first-class values only when their input surface can
  be represented by one owned packed input type:
  - `Unit`
  - one owned parameter type
  - one tuple of owned parameter types
- Named ordinary function values satisfy `CallRead[...]` only.
- Named suspend function values satisfy `SuspendCallRead[...]` only.
- Borrow-parameter packing is not part of first-wave function-value formation.

Example:

```runa
fn add_one(take x: I32) -> I32:
    return x + 1

let f = add_one
let y = f :: 41 :: call
```

## Attributes, `#unsafe`, And `repr`

Attribute forms:

- `#name`
- `#name[...]`

Current built-in attribute set:

- `#unsafe`
- `#hosted`
- `#test`
- `#reflect`
- `#domain_root`
- `#domain_child[...]`
- `#domain_context[...]`
- `#boundary[...]`
- `#repr[...]`
- `#link[...]`
- `#export[...]`

Rules:

- Unknown attributes are rejected.
- Duplicate non-repeatable attributes are rejected.
- Attribute order is semantically irrelevant.
- Attributes are semantically active directives, not passive metadata.

`#unsafe` forms:

- declaration prefix: `#unsafe fn ...`
- expression prefix: `#unsafe expr`
- block introducer: `#unsafe:`

Rules:

- `#unsafe` does not disable type checking, ownership, visibility, or package
  law.
- It only permits operations whose safety depends on external/manual proof.
- Imported foreign declarations are `#unsafe`.
- Raw pointer formation, pointer loads/stores/casts/arithmetic, foreign
  function-pointer calls, dynamic-library symbol lookup, and dynamic-library
  close require `#unsafe`.

Repr and layout rules:

- Default layout is compiler-defined and not a foreign-stable promise.
- `#repr[c]` is the explicit C-layout promise for eligible declarations.
- `#repr[c, IntType]` is the explicit C-layout enum representation form.
- `#repr[c]` is a strong promise, not a hint.
- `opaque type` keeps representation hidden.

## Control Flow And Binding

Rules:

- Use `select:` for guarded branching.
- Use `select value:` for subject-pattern branching.
- `select value:` arms may attach one `where` guard.
- Use `repeat:` for infinite loops.
- Use `repeat while cond:` for conditional loops.
- Use `repeat pattern in items:` for iteration.
- Use `let-else` for refutable local extraction.
- Expression-form `select` requires `else`.
- There is no `if`, `match`, `while`, `for`, or `loop` surface in v1.

Examples:

```runa
select:
    when ready => start :: :: call
    else => fail :: :: call

select event:
    when Event.Quit => return ()
    when Event.Resize(width = w, height = h) => resize :: w, h :: call

let Result.Ok(title_c) = title as Maybe[MaybeStr] else => return Result.Err :: InitError.EmbeddedNul :: call

repeat while running:
    tick :: state :: call
```

## `defer` And Cleanup

`defer` is lexical compiler-owned cleanup, not library sugar.

Rules:

- The first-wave deferred expression must be an invocation.
- Accepted deferred invocation forms are `callee :: ... :: call` and
  `receiver.member :: ... :: method`.
- Deferred invocations must return either `Unit` or `Result[Unit, E]`.
- Deferred arguments are evaluated at the `defer` site, not at scope exit.
- A deferred `take` consumes the original binding immediately.
- Deferred actions run in LIFO order.
- `defer` does not run at suspension points; it runs on scope exit and task
  teardown.

## Operators, Equality, And Hashing

Builtin operators are conventional but narrow.

- Arithmetic, shift, bitwise, boolean, ordering, and equality operators exist.
- Integer failure is loud: overflow, divide-by-zero, bad shifts, and similar
  invalid operations terminate deterministically.
- Comparison chaining such as `a < b < c` is invalid.
- Assignment and compound assignment are statements, not expressions.

Builtin `==` and `!=` do not extend to everything.

Builtin comparisons are guaranteed for:

- numeric scalar families
- `Char`
- `Index`
- `IndexRange`
- same-type numeric C ABI aliases
- `Bool`
- `Unit`
- raw pointers
- foreign function pointers

Builtin comparisons are not implied for:

- `struct` families
- `enum` families
- tuples
- arrays
- handles
- views
- collection families

Use `Eq.eq` and `Hash.hash` when a type participates in explicit equality or
map-key contracts. `Eq` does not magically add builtin `==`.

## Consts And Literals

Const items are explicit compile-time values.

Forms:

```runa
const PAGE_SIZE: Index = 4096

impl TokenKind:
    const COUNT: Index = 12
```

Rules:

- Module consts, local consts, and associated consts are part of v1.
- Const declarations require explicit types.
- Const evaluation is deterministic and has no fallback runtime evaluation.
- There is no `const fn`, no arbitrary compile-time method dispatch, no const
  loops, and no dynamic compile-time collections.
- Important const-safe families include scalars, numeric C ABI aliases, `Str`,
  `Bytes`, tuples, fixed-size arrays, `Option[...]`, `Result[...]`, and
  const-safe nominal aggregates.
- Raw pointers, handles, views, tasks, dynamic collections, and foreign
  function pointers are not const-safe in v1.

Literal surface:

- `true`, `false`, `()`
- character literals
- integer literals
- decimal floating-point literals
- string literals
- raw string literals
- byte-string literals
- array literals

Important literal rules:

- Negative numbers are unary `-` applied to a literal, not negative literal
  tokens.
- Character literals produce `Char`.
- String literals produce `Str`.
- Byte-string literals produce `Bytes`.
- There are no raw byte-string literals, no dedicated `Utf16` literals, and no
  user-defined literal suffixes in v1.

## Conversions, Text, And Bytes

Current conversion surface:

- `value as T` for explicit infallible conversion
- `value as Maybe[T]` for explicit checked conversion

Checked conversion returns `Result[T, ConvertError]`.

Important conversion rules:

- Implicit conversion is narrow: only same-ladder scalar widening is implicit.
- There is no implicit signed/unsigned crossing.
- There is no implicit integer/float crossing.
- There is no implicit conversion to or from `ISize` or `USize`.
- There is no implicit `Bool`/numeric conversion.
- There is no implicit text/bytes conversion.
- `Str -> Maybe[MaybeStr]` is the checked boundary-text conversion that matters
  most for this repo.
- Integer-like checked conversion includes exact signed and unsigned integers,
  `ISize`, `USize`, `Index`, and numeric C ABI aliases.
- Floating-point checked conversion includes `F32`, `F64`, and integer-like
  crossings where the conversion contract permits exact success.

Important text rules:

- `Str` is valid UTF-8 text.
- `MaybeStr` is valid UTF-8 text with one stable trailing NUL byte.
- `CStr['a]` is a borrowed UTF-8 view over a foreign NUL-terminated string.
- Text and byte APIs fail loudly on invalid boundaries or invalid decoding.

Current useful text APIs:

- `decode_utf8(read bytes: Bytes) -> Result[Str, Utf8Error]`
- `decode_c_string['a](ptr: *read CChar) -> Result[CStr['a], Utf8Error]`
- `MaybeStr.as_ptr() -> *read CChar`
- `MaybeStr.to_str() -> Str`
- `Str.copy_utf8() -> Bytes`
- `Str.encode_utf16() -> Utf16Buffer`

For outbound foreign strings, prefer checked conversion to `MaybeStr`:

```runa
let Result.Ok(title_c) = title as Maybe[MaybeStr] else => return Result.Err :: InitError.EmbeddedNul :: call
let title_ptr = title_c.as_ptr :: :: method
glfwSetWindowTitle :: window_ptr, title_ptr :: call
```

Do not hand-roll NUL-terminated buffers unless the actual surface requires it.

## Collections, Ranges, And Views

Rules:

- `List[T]`, `Map[K, V]`, `ByteBuffer`, and `Utf16Buffer` have zero-arg
  standard constructors.
- `Map[K, V]` requires `K: Eq + Hash`.
- `Type :: capacity :: call` is explicit reserved capacity with family-owned
  growth policy.
- For those standard families, `Type :: :: call` with named fields uses the
  family spec block.
- `repeat pattern in items:` is the language-owned iteration form.
- `value[key]` is strict access.
- Ranges are `a..b`, `a..=b`, `..b`, `..=b`, `a..`, and `..`.
- `IndexRange` has an explicit standard surface:
  - `start()`, `end()`, `is_end_inclusive()`
  - `normalize(extent) -> Result[IndexSpan, IndexRangeError]`

View and subslice rules:

- `View[Elem, Contiguous]` is the first-wave non-owning contiguous view family.
- Read subranges return a view-style result by default.
- `Str.slice(...)` and `Utf16.slice(...)` return retained same-family subslices.
- Subrange access does not imply a copy.

Examples:

```runa
let items = List[I32] :: :: call
let table = Map[Str, Token] :: 128 :: call
let bytes = text.copy_utf8 :: :: method
let piece = text.slice :: 0..4 :: method
```

Collection capability rules:

- `repeat pattern in items:` works through `Iterable['a]` or direct `Iterator`.
- `Iterator.next(edit self) -> Option[Self.Item]` is the cursor contract.
- `Iterable['a].iter(take self: hold['a] read Self) -> Self.Iter` is the
  read-oriented iteration-source contract.
- `Str`, `Utf16`, and `Utf16Buffer` do not participate in raw keyed access with
  `value[index]` in v1; use explicit validated text APIs instead.

## Memory Families And Allocator Strategies

`rnaglfw` mostly uses the self-backed standard families, but the language has a
larger memory model than the old guide implied.

Core non-owning view surface:

- `View[Elem, Contiguous]`
- `View.count()`
- `View.is_empty()`

Standard memory capability traits:

- `IdAllocating[T]`
- `Resettable`
- `LiveIterable['a]`
- `Compactable`
- `SequenceBuffer[T]`

Standard allocator-family catalog:

- `Arena[T]`
- `Pool[T]`
- `Slab[T]`
- `Ring[T]`

Standard strategy types and shared policies:

- `ArenaSpec`
- `PoolSpec`
- `SlabSpec`
- `RingSpec`
- `GrowthPolicy`
- `RingFullPolicy`

Important rules:

- Strategy values are typed data, not live allocator instances.
- `Arena`, `Pool`, and `Slab` use explicit family-spec construction in v1.
- `Ring[T]` uses explicit `RingSpec` construction in v1.
- `List[T]`, `Map[K, V]`, `ByteBuffer`, and `Utf16Buffer` are their own
  self-backed standard families, not hidden wrappers over those allocator
  families.
- `Sealable` exists for implementation-facing self-host support, but it is not
  ordinary public generic memory surface.

Representative family semantics:

- `Arena[T]` is append-and-reset, with no per-item remove.
- `Pool[T]` is dense reusable-slot storage and may compact.
- `Slab[T]` is stable-slot reusable storage and does not compact.
- `Ring[T]` is bounded circular sequence-buffer storage and uses
  `RingFullPolicy` for full-buffer behavior.

## Async And Tasks

Rules:

- Use `suspend fn` for suspendable callables.
- Calling a `suspend fn` does not create concurrent work by itself.
- Concurrency starts through explicit task APIs such as `spawn`,
  `spawn_edit`, `spawn_take`, `spawn_local`, and detached variants.
- Waiting is `task.await :: :: method`.
- There is no standalone `await expr`.
- Plain ephemeral `read` and `edit` borrows do not live across suspension.
- `Task[T]` is a move-only handle and awaiting consumes the task in first-wave
  law.
- `Send` is the builtin concurrency-crossing marker trait.
- User-written `impl Send for Type` is not part of v1.
- Detached cross-thread work requires `Send` and `'static` state.

Example:

```runa
use std.task.{Task, spawn}

suspend fn load_texture(path: Str) -> Bytes:
    ...

suspend fn init(path: Str) -> Bytes:
    let task = spawn :: load_texture, path :: call
    return task.await :: :: method
```

## Reflection And Observability

Reflection is declaration-oriented and runtime metadata is opt-in.

Rules:

- Use `#reflect` on exported declarations only.
- Valid `#reflect` targets are `pub fn`, `pub const`, `pub struct`,
  `pub enum`, and `pub opaque type`.
- Methods, traits, impls, fields, and enum variants are not `#reflect`
  targets in v1.
- Runtime reflection entry roots are:
  - `std.reflect.current_package()`
  - `Mirror[...]` for direct reflected declaration acquisition

Useful `std.reflect` families:

- `ReflectedPackage`
- `ReflectedModule`
- `ReflectedDeclaration`
- `FunctionMetadata`
- `ConstMetadata`
- `StructMetadata`
- `EnumMetadata`
- `OpaqueTypeMetadata`
- `TypeShape`

Observability is explicit under `std.observe`.

Useful `std.observe` families:

- `Level`
- `LevelFilter`
- `TraceValue`
- `TraceField`
- `SpanRecord`
- `Event`
- `SpanGuard`
- `TraceSnapshot`
- `FormattingSubscriber`
- `TracerOps`

Rules:

- Observability is library-owned, not ambient default printing.
- Structured fields are preserved and ordered.
- Event and span data are typed surfaces, not just flattened strings.

## C ABI, Raw Pointers, And Dynamic Libraries

`rnaglfw` is boundary-heavy, but this is general language surface.

Foreign rules:

- Use `extern["c"]` or `extern["system"]`.
- Imported foreign declarations are `#unsafe` and bodyless.
- Use explicit `#link[...]` or `#export[...]`.
- Use C ABI aliases like `CInt`, `CChar`, `CUInt`, `CSize`, and `CVoid`.
- `Unit`, `Bool`, `Str`, `Bytes`, collections, `Option[...]` in general, and
  `Result[...]` are not C ABI-safe.
- The one `Option[...]` carve-out that matters here is
  `Option[extern["c"] fn(...)]` or `Option[extern["system"] fn(...)]` for
  nullable callback slots.

Raw pointer rules:

- Raw pointer families are `*read T` and `*edit T`.
- Raw pointers are nullable and compare against `null`.
- Raw pointer formation is explicit and `#unsafe`:
  - `#unsafe &raw read place`
  - `#unsafe &raw edit place`
- Address bridge helpers exist for low-level wrapper work:
  - `raw_pointer_from_address_read`
  - `raw_pointer_from_address_edit`
  - `raw_pointer_address_read`
  - `raw_pointer_address_edit`
- `cast`, `offset`, `load`, and `store` are `#unsafe`.

Dynamic-library rules:

- `std.dylib.open_library(path: Str)` is the explicit runtime loader surface.
- `std.dylib.lookup_symbol[T](...)` is typed and `#unsafe`.
- `T` for dynamic lookup must be a foreign function pointer type or raw pointer
  type.
- `std.dylib.close_library(...)` is explicit and `#unsafe`.

Minimal import example:

```runa
#link[name = "glfw3"]
#unsafe
extern["c"] fn glfwGetError(description: *edit *read CChar) -> CInt
```

## C Translation And Binding Ownership

Runa treats C translation as a toolchain bridge over ordinary source
declarations.

Rules:

- Discovery and translation are explicit tooling steps, not ambient build-time
  header authority.
- Translation emits ordinary Runa declarations.
- After translation, the resulting Runa source is authoritative for normal
  compilation.
- Complete foreign aggregates become explicit `#repr[c]` declarations when the
  compiler can represent them honestly.
- Incomplete or non-transparent foreign types become `opaque type`.
- Honest `typedef`-style renames become `type` aliases.
- Translation must not invent automatic handles, ownership wrappers, or hidden
  safety wrappers.
- Regeneration is explicit and must not silently overwrite edited bindings
  during ordinary builds.

## Domain State And `#boundary`

Domain-state surface:

- `#domain_root` on `struct`
- `#domain_child[RootName]` on `struct`
- `#domain_context[RootName]` on `struct`

Rules:

- Domain roots are owned lifetime-governing values.
- Domain children and domain contexts are explicit struct declarations with
  retained anchor fields.
- `#domain_child[...]` requires one `parent` field.
- `#domain_context[...]` requires one `root` field.
- The narrow `domain.RootName` reference exists only for domain-family
  attachment and anchor typing in the owning subtree.
- There is no hidden ambient context or runtime owner registry.

Boundary surface:

- `#boundary[api]` on exported `pub fn` / `pub suspend fn`
- `#boundary[value]` on exported `pub struct` / `pub enum`
- `#boundary[capability]` on exported `pub opaque type`

Rules:

- Boundary contracts are exported-only.
- `#boundary[api]` signatures use owned parameters and transfer-safe or
  capability-safe types only.
- `read`, `edit`, retained borrows, references, views, raw pointers, foreign
  function pointers, and `Task[...]` are not valid boundary API surface types.
- `#boundary[value]` members must all be transfer-safe.
- `#boundary[capability]` marks capability-safe opaque families.
- Products exporting `#boundary[api]` entries must package explicit generated
  boundary-surface metadata.
- Non-C boundary use goes through generated typed stubs or adapters, not
  invoke-by-name.

## Handle Law

The language has a real handle model, not just generic opaque types used
casually.

Rules:

- Handle families are explicit uses of `opaque type`.
- Handles are produced only by explicit API producers.
- Ordinary construction, literals, aggregate formation, and casts must not
  fabricate handle values.
- Public handle families are move-only by default.
- Handle duplication is never implicit copy.
- Handle absence uses `Option[Handle]` or `Result[...]`, not fabricated null or
  zero sentinels.
- Cleanup is explicit API plus ordinary `defer`, not hidden destructor magic.

For `rnaglfw`, raw wrapper handles and app-layer handles should keep these
rules in mind even when the source of the resource is foreign.

## What To Avoid

Do not write guessed Rust-, C-, or Arcana-shaped Runa.

Avoid:

- `foo(bar)` call syntax
- `obj.method(arg)` call syntax
- `if`, `match`, `while`, `for`, or `loop`
- closures or lambdas
- wildcard imports
- relative `super`-style import climbing
- `pub(super)` or `pub(in path)`
- implicit `std` names without `use`
- guessed enum or struct equality through `==`
- treating `Index` like a general integer arithmetic domain
- treating tuples as singleton-capable or field-assignable
- assuming `Task[T]`, raw pointers, handles, or views are `Send`
- implicit retained-borrow synthesis
- manual string-to-C-string buffer hacks where `MaybeStr` already fits
- fabricating handle values or null-like handle sentinels
- silent fallback behavior

## Toolchain Workflow

Current core commands:

- `runa check`
- `runa build`
- `runa test`
- `runa fmt`
- `runa trace`
- `runa new`
- `runa add`
- `runa remove`
- `runa import`
- `runa vendor`
- `runa publish`

Practical rules:

- `runa check` is semantic validation, not a build.
- `runa build` shares the semantic path with `check` and then emits artifacts.
- `runa test` is the explicit test command.
- `runa fmt` is the canonical formatter.
- `runa fmt --check` is the check-only formatting mode.
- Formatting is syntax-owned, not semantics-owned; semantically invalid code may
  still format if the parse result is reliable.
- `runa trace <wrapped-command>` is the explicit invocation-scoped tracing
  command.
- First-wave trace-wrapped commands are `check`, `build`, `test`, `review`, and
  `repair`.
- `#test` is the built-in test attribute.
- `--locked` is the first-wave lockfile replay flag for `check` and `build`.
- Workspace roots and package roots come from `runa.toml` discovery, not single
  loose files.
- The local build roots are `target/` and `dist/`.
- For authored `.rna` source files in the local authoring scope, `runa check`
  enforces the hard `3000` physical-line limit.
- `runa new <name>` creates a bin package by default.
- `runa new --lib <name>` creates a library scaffold with `lib.rna` and
  `core/mod.rna`.
- `runa new --mod=path.to.module` creates explicit child-module paths inside an
  existing package.
- `runa add`, `runa remove`, `runa import`, `runa vendor`, and `runa publish`
  are explicit package-lifecycle commands, separate from `check`, `build`,
  `test`, and `fmt`.

## Repo Working Rule

Before adding new Runa code here:

1. Check `../RunaLang/spec/llm.md` first, then the owning law.
2. Follow the exact v1 surface, not the shortest shape from another language.
3. Validate with `../RunaLang/target/debug/runa.exe`.
4. If the spec is silent, contradictory, or still missing a needed rule, stop.
