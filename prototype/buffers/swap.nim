import cpu, gpu

proc add*(buffer: var Buffer, batch: Batch): int32 =
    buffer.add(batch.location, batch.width)