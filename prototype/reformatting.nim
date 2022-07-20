import std/[strformat], opengl, windy

type
    SubBuffer = ref object of RootObj
        index, offset: int32
        size, capacity: int32
    
    Buffer = ref object of SubBuffer
        id: uint32

        sections: seq[SubBuffer]

# simplified functions
    
proc genBuffer(): uint32 =
    glGenBuffers(1, addr result)

proc setData(buffer: Buffer, data: pointer, offset: uint = 0) =
    glBindBuffer(GL_ARRAY_BUFFER, buffer.id)
    glBufferData(GL_ARRAY_BUFFER, buffer.capacity, data, GL_DYNAMIC_COPY)

proc copy(a, b: Buffer, aOffset, bOffset, size: int32) =
    glBindBuffer(GL_COPY_READ_BUFFER, a.id)
    glBindBuffer(GL_COPY_WRITE_BUFFER, b.id)
    glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, aOffset, bOffset, size)

proc map*(buffer: Buffer): pointer =
    glBindBuffer(GL_ARRAY_BUFFER, buffer.id)
    return glMapBuffer(GL_ARRAY_BUFFER, GL_READ_WRITE)

proc unmap*(buffer: Buffer) =
    glBindBuffer(GL_ARRAY_BUFFER, buffer.id)
    assert glUnmapBuffer(GL_ARRAY_BUFFER), "Failed to unmap buffer!"

proc deleteBuffer(id: uint32) =
    glDeleteBuffers(1, unsafeAddr id)

# utility

proc indices[T](list: T): Slice[int] =
    return low(list) .. high(list)

# buffers

# data

proc set(buffer: var Buffer, data: pointer, size, offset: int32) =
    glBindBuffer(GL_COPY_READ_BUFFER, buffer.id)
    glBufferSubData(GL_COPY_READ_BUFFER, offset, size, data)

proc set(buffer: var Buffer, section: var SubBuffer, data: pointer, size: int32) =
    buffer.set(data, size, section.offset)
    section.size = size

proc set[T](buffer: var Buffer, section: var SubBuffer, data: seq[T]) =
    buffer.set(section, unsafeAddr data[0], int32(sizeof(T) * data.len))

proc get*(buffer: Buffer, offset, size: int32): pointer =
    result = alloc(size)

    glBindBuffer(GL_COPY_READ_BUFFER, buffer.id)
    glGetBufferSubData(GL_COPY_READ_BUFFER, offset, size, result)

proc get*(buffer: Buffer, section: SubBuffer): pointer =
    return buffer.get(section.offset, section.size)

proc getAsSeq*[T](buffer: Buffer, size: int32, offset: int32 = 0): seq[T] =
    result.setLen(size div sizeof(T))

    glBindBuffer(GL_COPY_READ_BUFFER, buffer.id)
    glGetBufferSubData(GL_COPY_READ_BUFFER, offset, size, addr result[0])

proc getAsSeq*[T](buffer: Buffer, section: SubBuffer): seq[T] =
    return buffer.getAsSeq[:T](section.size, section.offset)

# new

proc newBuffer(capacity: int32): Buffer =
    result = new(Buffer)
    result.id = genBuffer()
    result.capacity = capacity
    result.setData(nil)

# break due to dependencies: sizing

proc resize(buffer: var Buffer, newCapacity: int32 = buffer.capacity * 2) =
    var newBuffer = newBuffer(newCapacity)
    
    copy(buffer, newBuffer, 0, 0, buffer.size)
    
    buffer = newBuffer

# resume: new

proc newSection(buffer: var Buffer, capacity: int32): SubBuffer =
    if buffer.size + capacity > buffer.capacity:
        buffer.resize()

    result = new(SubBuffer)
    result.index = int32(buffer.sections.len)
    result.offset = buffer.size
    result.capacity = capacity

    buffer.sections.add(result)
    buffer.size += capacity

# formatting

proc reformat(buffer, newBuffer: Buffer, snapshot: seq[SubBuffer]) =
    var offset: int32 = 0
    
    for section in buffer.sections.mitems:
        section.offset = offset
        offset += section.capacity
        
    for sectionIndex in snapshot.indices:
        let oldSection = snapshot[sectionIndex]
        let newSection = buffer.sections[sectionIndex]
        
        copy(buffer, newBuffer, oldSection.offset, newSection.offset, oldSection.size)
    
    deleteBuffer(buffer.id)

proc reformat(buffer: var Buffer, snapshot: seq[SubBuffer]) =
    let newBuffer = newBuffer(buffer.capacity)
    
    buffer.reformat(newBuffer, snapshot)
    
    buffer = newBuffer

# body should only modify the sections themselves, not the
# data contained within
template reformatWith(buffer: var Buffer, body: untyped) =
    let snapshot = buffer.sections
    
    body
    
    buffer.reformat(snapshot)

# sizing

proc snapshot(buffer: Buffer): seq[SubBuffer] =
    for section in buffer.sections:
        var newSection = new(SubBuffer)
        newSection.index = section.index
        newSection.offset = section.offset
        newSection.size = section.size
        newSection.capacity = section.capacity
        result.add(newSection)

proc resize(buffer: var Buffer, section: var SubBuffer, newCapacity: int32 = section.capacity * 2) =
    # TL;DR: if the buffer can't hold the section
    if buffer.size - section.capacity + newCapacity > buffer.capacity:
        # optimization to use newly resized buffer as the formatting buffer
        let newBuffer = newBuffer(buffer.capacity * 2)
        let snapshot = buffer.snapshot()

        section.capacity = newCapacity

        buffer.reformat(newBuffer, snapshot)

        buffer = newBuffer
    else:
        reformatWith(buffer):
            section.capacity = newCapacity

# stringification

proc `$`(section: SubBuffer): string =
    return fmt("""    offset: {section.offset}
    size: {section.size}
    capacity: {section.capacity}""")

# buffer: end

let window = newWindow("Reformatting example", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)
window.makeContextCurrent()
loadExtensions()

var buffer = newBuffer(16)
var a = buffer.newSection(8)
var b = buffer.newSection(8)

var aData = @[int32(1), 2]
buffer.set(a, aData)

var bData = @[int32(3), 4]
buffer.set(b, bData)

echo buffer.getAsSeq[:int32](buffer.capacity)

echo "a: \n", a
echo "b: \n", b

buffer.resize(a, 16)

echo buffer.getAsSeq[:int32](buffer.capacity)

echo "post resize:"
echo "a: \n", a
echo "b: \n", b