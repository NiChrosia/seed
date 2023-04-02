suggestions:
- abstract types should be defined as minimally as possible
- passing of context should be explicitly noted

# regularized draw system

Generic components.

ShaderProgram
---
Concrete.

Highest node in the hierarchy. Corresponds to multiple uniforms & batches.

UniformVar
---
Concrete.

```nim
T: variable data type

index: GLint

init[T](program: GLuint, name: string) -> void
# bound program
update[T](data: T)                     -> void
```

Batch
---
Abstract.

draw() must be called with a shader program bound.

```nim
init() -> void
# bound program
draw() -> void
```

Specific components.

Buffer
---
Concrete.

```nim
id: GLuint

init(width: GLuint, kind, usage: GLenum) -> void
update(x, width: GLuint, data: pointer)  -> void
```

UniformBuffer
---
Concrete.

```nim
buffer: Buffer

init(binding, width: GLuint, usage: GLenum) -> void
attach(program: GLuint, name: string)       -> void
update(x, width: GLuint, data: pointer)     -> void
```

Atlas
---
Concrete.

Entirely detached.

```nim
texture: GLuint

init()                                  -> void
transform(texture: string, local: Vec2) -> Vec2
```

QuadBatch
---
Concrete.

Attached to a shader program. Can draw infinite
quadrilaterals with arbitary position, texture, and tint.

```nim
modelBuffer: ref UniformBuffer
atlas:       ref Atlas
vbo:         Buffer
vao:         GLuint

init(modelBuffer: ref UniformBuffer, atlas: ref Atlas)            -> void
quad(a, b, c, d: Vec2, texture: string, tint: float, model: Mat4) -> void
# bound program
draw()                                                            -> void
```
