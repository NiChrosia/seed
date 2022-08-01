## CPU buffers, generally used as batches to
## send to the GPU.

type
    Batch* = object
        location*: pointer
        filled*, width*: int32

# utility

proc `+`(data: pointer, offset: int): pointer =
    let asInt = cast[int](data)
    let shifted = asInt + offset
    let asPtr = cast[pointer](shifted)

    return asPtr

# sizing

proc resize(batch: var Batch, newWidth: int32) =
    ## Resizes a batch in 5 steps:
    ##   1. Allocate a temporary batch
    ##   2. Copy from this batch to the temporary one
    ##   3. Reallocate this batch with the new width
    ##   4. Copy from the temporary batch back to the
    ##   newly resized batch.
    ##   5. Deallocate the temporary batch.

    var temporary = alloc(batch.filled)

    copyMem(temporary, batch.location, batch.filled)

    dealloc(batch.location)
    batch.location = alloc(newWidth)

    copyMem(batch.location, temporary, batch.filled)
    batch.width = newWidth

    dealloc(temporary)

proc checkSize(batch: var Batch, increase: int32) =
    if batch.filled + increase > batch.width:
        batch.resize(batch.width * 2)
        # recursion in case a single size double
        # isn't enough to accomodate the increase
        batch.checkSize(increase)

# adding

proc add*(batch: var Batch, item: pointer, width: int32): int32 =
    batch.checkSize(width)

    let shifted = batch.location + batch.filled
    result = batch.filled

    copyMem(shifted, item, width)

    batch.filled += width

# init

proc newBatch*(initialWidth: int32 = 64): Batch =
    result.width = initialWidth
    result.location = alloc(result.width)

proc newSeqBatch*[T](theSeq: seq[T]): Batch =
    let width = int32(sizeof(T) * theSeq.len())

    result = newBatch(width)
    discard result.add(unsafeAddr theSeq[0], width)

proc newBatch*[T](item: T): Batch =
    when T is seq:
        raise newException(ValueError, "Passing a sequence to the implicit batch initializer is not allowed, as sizeof returns an incorrect value. Try using newSeqBatch instead.")

    let width = int32(sizeof(T))

    result = newBatch(width)
    discard result.add(unsafeAddr item, width)