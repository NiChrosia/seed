import opengl, windy, std/[strformat]

type
    Section* = ref object
        buffer*: Buffer
        
        offset*, occupied*, size*: int32

    Buffer* = ref object
        handle*: uint32
        usage*: GlEnum

        occupied*, size*: int32
        sections*: seq[Section]

const utilityBuffer = GlCopyReadBuffer

# data

proc setSlice*(handle: uint32, offset, size: int32, data: pointer) =
    glBindBuffer(utilityBuffer, handle)
    glBufferSubData(utilityBuffer, offset, size, data)

proc setWhole*(handle: uint32, size: int32, data: pointer, usage: GlEnum) =
    glBindBuffer(utilityBuffer, handle)
    glBufferData(utilityBuffer, size, data, usage)

proc allocateWhole*(handle: uint32, newSize: int32, usage: GlEnum) =
    setWhole(handle, newSize, nil, usage)

# init

proc newBuffer*(usage: GlEnum, startSize: int32 = 1024): Buffer =
    result = new(Buffer)

    glGenBuffers(1, addr result.handle)
    result.size = startSize
    result.usage = usage

    allocateWhole(result.handle, startSize, usage)

# sizing

# - snapshots, used for reformatting

proc snapshot*(buffer: Buffer): seq[Section] =
    result.setLen(buffer.sections.len)

    for index in 0 ..< buffer.sections.len:
        var original = buffer.sections[index]
        result[index] = new(typeof(original[]))

        result[index][] = original[]

# - back to sizing

proc resize*(buffer: var Buffer, newSize: int32) =
    var temporary = newBuffer(buffer.usage, buffer.occupied)

    glBindBuffer(GlCopyReadBuffer, buffer.handle)
    glBindBuffer(GlCopyWriteBuffer, temporary.handle)

    # copy from buffer to temp
    glCopyBufferSubData(GlCopyReadBuffer, GlCopyWriteBuffer, 0, 0, buffer.occupied)

    # allocate empty memory with new size
    allocateWhole(buffer.handle, newSize, buffer.usage)
    buffer.size = newSize

    # copy back from temp to newly resized buffer
    glCopyBufferSubData(GlCopyWriteBuffer, GlCopyReadBuffer, 0, 0, buffer.occupied)

    # delete the temporary buffer; as this proc should
    # be called relatively infrequently, the creation
    # and deletion should not be a performance concern
    glDeleteBuffers(1, addr temporary.handle)

proc checkSize(buffer: var Buffer, increase: int32) =
    if buffer.occupied + increase > buffer.size:
        buffer.resize(buffer.size * 2)

proc reformat*(buffer: var Buffer, snapshot: seq[Section]) =
    ## Reformats the data according to the current and
    ## old snapshot.

    assert buffer.sections.len == snapshot.len, "Given section seqs do not have matching sizes!"

    var temporary = newBuffer(buffer.usage, buffer.size)

    glBindBuffer(GlCopyReadBuffer, buffer.handle)
    glBindBuffer(GlCopyWriteBuffer, temporary.handle)

    for index in 0 ..< snapshot.len:
        var old = snapshot[index]
        var current = buffer.sections[index]

        # copy from this buffer at old to the
        # temporary buffer at new
        glCopyBufferSubData(GlCopyReadBuffer, GlCopyWriteBuffer, old.offset, current.offset, old.size)

    # finally, now that the reformatting is complete,
    # replace the data in the current buffer with the
    # temporary buffer's.
    glCopyBufferSubData(GlCopyWriteBuffer, GlCopyReadBuffer, 0, 0, buffer.size)

    glDeleteBuffers(1, addr temporary.handle)

proc resize*(section: var Section, newSize: int32) =
    let snapshot = section.buffer.snapshot()

    section.buffer.checkSize(newSize - section.size)

    section.buffer.reformat(snapshot)
    section.buffer.occupied += newSize - section.size
    section.size = newSize

proc checkSize(section: var Section, increase: int32) =
    if section.occupied + increase > section.size:
        section.resize(section.size * 2)

# init: 2

proc newSection*(buffer: var Buffer, startSize: int32 = 64): Section =
    result = new(Section)
    result.buffer = buffer
    result.offset = buffer.occupied
    result.size = startSize

    buffer.checkSize(startSize)

    buffer.sections.add(result)
    buffer.occupied += startSize

# op

proc add*[S](section: var Section, shape: S): int32 =
    ## adds an object to the buffer, and returns
    ## the offset, to allow future modification
    result = section.occupied

    let size = int32(sizeof(S))

    section.checkSize(size)

    setSlice(section.buffer.handle, section.offset + section.occupied, size, unsafeAddr shape)
    section.occupied += size

# debug

proc `$`*(buffer: Buffer): string =
    return "Buffer" & $buffer[]

proc `$`*(section: Section): string =
    let buffer = "..."
    let offset = $section.offset
    let occupied = $section.occupied
    let size = $section.size

    return fmt"Section(buffer: {buffer}, offset: {offset}, occupied: {occupied}, size: {size})"