# Shader code spec

## Shader initialization

Verbosely, you can do

```nim
let shader = initShader(kind = k)
shader.define(source = s)
shader.compile()
shader.check()
```

or more compactly,

```nim
let shader = initShader(kind = k, source = s, check = c)
```

Parameters:
- The value `k` is a `ShaderKind`, like vertex or fragment. The enum values for such are `vVertex` and `vFragment`.
- The value `s` is the shader source, as a multiline string.
- The value `c` is a boolean determining whether to check that the shader compiled successfully, after `initShader(k, s, c)` compiles the shader.

Functions:
- `initShader(k)` simply creates a shader of type `k` and returns the empty shader object.
- `Shader.define(s)` sets the shader source using `s`.
- `Shader.compile()` compiles the shader, possibly with errors.
- `Shader.check()` checks whether the shader compiled successfully, and if not, raises an error with the log.
- `initShader(k, s, c)` creates an empty shader object of type `k`, defines the source using `s`, compiles, and checks for successful compilation if `c` is true.

## Program initialization

Verbosely,

```nim
let program = initProgram()
program.attach(shader = s)
program.link()
program.check()
```

or compactly,

```nim
let program = initProgram(shaders = a, check = c)
```

Parameters:
- The value `s` is a `Shader` that is attached to the program.
- The value `a` is a sequence or array of shaders that will be attached to the program.
- The value `c` is boolean determining whether the program checks for successful shader linking, after `initProgram(a, c)` links the shaders.

Functions:
- `initProgram()` creates an empty shader program object.
- `ShaderProgram.attach(s)` attaches shader `s` to the program.
- `ShaderProgram.link()` links the shaders, possibly with errors.
- `ShaderProgram.check()` checks for successful linking, raising an error with the log in case of a fail.
- `initProgram(a, c)` creates an empty program object, attaches shaders `a`, links, and checks depending on `c`.

## Uniforms

Uniforms are set using two forms: implicit and explicit.

Implicit setting using the currently bound program, possibly incurring performance penalties. It looks like this:

```nim
let l = @n
```

Explicit setting uses an explicit program. It looks like this:

```nim
let l = program.locate(n)
```

Uniform usage looks like this, instead:

```nim
set(l, 1f)
set(l, 1f, 2f, 3f, 4f)
set(l, [
    1f, 0f,
    0f, 1f
])
set(l, [
    1f, 0f, 0f, 0f,
    0f, 1f, 0f, 0f,
    0f, 0f, 1f, 0f,
    0f, 0f, 0f, 1f,
])
```

Parameters:
- The value `l` is the uniform location, used for setting values. It can be obtained using `@n` or `ShaderProgram.locate(n)`.
- The value `n` is the name of the uniform, used to obtain the location. It is used in `@n` and `ShaderProgram.locate(n)`.

Functions:
- `@n` obtains a uniform location using name `n` and the currently bound shader program.
- `ShaderProgram.locate(n)` obtains a uniform location using name `n` and the passed shader program.
- `set(l, v)` sets the uniform value `v` at location `l`.
  - `v` can be scalar, vector, or a matrix. These forms look like:
  - scalar: `set(l, v)`,
  - vector: `set(l, x, y, z)`,
  - or, finally: matrix `set(l, m)`.