import cpu, gpu

proc add*(buffer: var Buffer, batch: Batch): int32 =
    result = buffer.add(batch.location, batch.width)

    dealloc(batch.location)