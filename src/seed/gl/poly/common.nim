import ../attributes, ../buffers
import ../shaders/[types]

import opengl

type
    InstanceCategory*[V, P] = ref object
        vertices, properties, indices: Buffer
        layout: uint32

        perInstance, instances: int32

proc initInstCategory*[V, P](program: ShaderProgram, vertexBuilder, propertyBuilder: var AttributeBuilder, vertices: seq[V], indices: seq[uint32]): InstanceCategory[V, P] =
    # fields
    result = new(InstanceCategory[V, P])

    result.vertices = newBuffer(GL_DYNAMIC_DRAW, 1024)
    result.properties = newBuffer(GL_DYNAMIC_DRAW, 1024)
    result.indices = newBuffer(GL_DYNAMIC_DRAW, 1024)

    result.perInstance = int32(indices.len)

    glGenVertexArrays(1, addr result.layout)

    # state
    glBindVertexArray(result.layout)

    result.vertices.bindTo(GL_ARRAY_BUFFER)
    vertexBuilder.a(result.layout)
        .p(*program)
        .build()

    result.properties.bindTo(GL_ARRAY_BUFFER)
    propertyBuilder.a(result.layout)
        .p(*program)
        .build()

    result.indices.bindTo(GL_ELEMENT_ARRAY_BUFFER)

    # data
    discard result.vertices.add(newBatch(vertices))
    discard result.indices.add(newBatch(indices))

proc add*[V, P](c: var InstanceCategory[V, P], properties: P) =
    discard c.properties.add(newBatch(properties))
    inc c.instances

proc draw*[V, P](c: InstanceCategory[V, P]) =
    glBindVertexArray(c.layout)
    glDrawElementsInstanced(GL_TRIANGLES, c.perInstance, GL_UNSIGNED_INT, nil, c.instances)