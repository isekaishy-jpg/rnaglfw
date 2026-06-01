# `glfw`

`glfw` is a split-module Runa wrapper for the GLFW C API.

Current verified scope:

- GLFW function imports covered: `151 / 151`
- GLFW constants covered: `333 / 333`
- package check status: `runa check` passes

Module layout:

- [lib.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\lib.rna)
- [core/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\core\mod.rna)
- [window/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\window\mod.rna)
- [monitor/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\monitor\mod.rna)
- [input/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\input\mod.rna)
- [joystick/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\joystick\mod.rna)
- [vulkan/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\vulkan\mod.rna)
- [native/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\native\mod.rna)
- [constants/mod.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\constants\mod.rna)

Authority:

- Runa syntax and package law come from `../RunaLang/spec/`
- GLFW API truth comes from `vendor/glfw/include/GLFW/`

Usage notes:

- The package links against `glfw3` through `[[native_links]]`.
- End-user downloads do not bundle platform-specific `glfw3` sidecars.
- Provide `glfw3` through a local `vendor/linking/glfw/` sidecar layout or one
  platform installation visible to the native linker.
- Titles, clipboard text, extension names, and similar C strings are caller-managed `*read CChar`.
- The package exposes split typed wrappers, not one flat generated blob.
- Public data records expose accessor helpers so external packages are not blocked by current stage0 imported-struct field-projection limits.

Vendored GLFW source:

- `vendor/glfw/` keeps the upstream GLFW source tree trimmed to the build-relevant
  source, headers, build files, upstream README, and upstream `LICENSE.md`.

Nullable callback and proc boundary:

- The current repo-local Runa bin accepts `Option[extern["c"] fn(...)]` in imported foreign signatures.
- `glfw` now models GLFW callback setters and proc-address APIs with exact nullable foreign-function-pointer surfaces.
- Use `Option.Some(callback)` to install a callback.
- Use `Option.None` to clear a callback slot or to represent a missing proc lookup.

Raw handle boundary:

- Window and monitor handle lookups now return nullable `GlfwWindow` and `GlfwMonitor` wrappers directly.
- Test handle presence with `.is_null()`.
- This keeps the low-level wrapper usable on the current compiler while `Option[NominalStruct]` payload extraction is still broken.

Smoke consumer:

- [examples/surface-smoke/main.rna](C:\Users\Weaver\Documents\GitHub\rnaglfw\examples\surface-smoke\main.rna)
- [examples/surface-smoke/runa.toml](C:\Users\Weaver\Documents\GitHub\rnaglfw\examples\surface-smoke\runa.toml)

Checks:

```powershell
runa check
cd examples/surface-smoke
runa check
```
