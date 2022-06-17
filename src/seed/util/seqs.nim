import sequtils

proc indices*[T](sequence: seq[T]): seq[int] =
    result = toSeq(low(sequence) .. high(sequence))

proc sum*[T: SomeNumber](sequence: seq[T]): T =
    if sequence.len == 0:
        return 0
    elif sequence.len == 1:
        return sequence[0]

    result = sequence.foldl(a + b)

proc flatten*[T](sequence: seq[seq[T]]): seq[T] =
    for subseq in sequence:
        for item in subseq:
            result.add(item)