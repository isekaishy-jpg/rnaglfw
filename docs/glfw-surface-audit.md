# GLFW Surface Audit

Authoritative sources:

- `vendor/glfw/include/GLFW/glfw3.h`
- `vendor/glfw/include/GLFW/glfw3native.h`

- `glfw3.h` macro count: `333`
- `glfw3.h` function count: `124`
- `glfw3native.h` function count: `28`
- wrapped `GLFW_*` constants in `constants/mod.rna`: `333`
- imported foreign GLFW functions in `rnaglfw`: `152`

Coverage result:

- missing from `glfw3.h` constants: `0`
- missing from `glfw3.h`: `0`
- missing from `glfw3native.h`: `0`
- extra local declarations not present in the headers: `0`

Compiler verification:

- `runa check`: `ok (1 package(s), 1 product(s), 11 source file(s))`
- `examples/surface-smoke`: `ok (2 package(s), 1 product(s), 12 source file(s))`
- large constant module accepted
- fixed-size array C-layout payloads accepted
- Vulkan handle aliases compile with the current stage0 subset
- native handle aliases compile with the current stage0 subset

Nullable foreign-function-pointer coverage:

The current repo-local Runa bin accepts `Option[extern["c"] fn(...)]` in
imported foreign signatures, so the GLFW nullable callback and proc surfaces
can now be modeled directly.

Covered nullable foreign-function-pointer APIs:

- `glfwSetErrorCallback`
- `glfwSetMonitorCallback`
- `glfwSetJoystickCallback`
- `glfwSetWindowPosCallback`
- `glfwSetWindowSizeCallback`
- `glfwSetWindowCloseCallback`
- `glfwSetWindowRefreshCallback`
- `glfwSetWindowFocusCallback`
- `glfwSetWindowIconifyCallback`
- `glfwSetWindowMaximizeCallback`
- `glfwSetFramebufferSizeCallback`
- `glfwSetWindowContentScaleCallback`
- `glfwSetCursorEnterCallback`
- `glfwSetKeyCallback`
- `glfwSetCharCallback`
- `glfwSetCharModsCallback`
- `glfwSetMouseButtonCallback`
- `glfwSetCursorPosCallback`
- `glfwSetScrollCallback`
- `glfwSetDropCallback`
- `glfwGetProcAddress`
- `glfwGetInstanceProcAddress`

Current package status for those APIs:

- the imported symbols exist and type-check
- callback setters accept `Option.Some(callback)` and `Option.None`
- previous callback slots return through `Option[...]`
- proc-address lookup returns `Option[...]`

Nullable handle-wrapper status:

- raw window and monitor handle queries now return `GlfwWindow` or `GlfwMonitor`
- missing handles are represented by null wrapped handles
- low-level consumers should use `.is_null()` on those wrappers
- this is the current low-level package surface for nullable window and monitor
  handles
