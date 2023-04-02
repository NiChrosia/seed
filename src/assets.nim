import tables, base64

var assets*: Table[string, string]

proc getAsset*(path: string): string =
  result = assets[path].decode()

func toByteSeq(str: string): seq[byte] {.inline.} =
  ## Copy ``string`` memory into an immutable``seq[byte]``.
  let length = str.len
  if length > 0:
    result = newSeq[byte](length)
    copyMem(result[0].unsafeAddr, str[0].unsafeAddr, length)

proc getAssetToByteSeq*(path: string): seq[byte] =
  result = toByteSeq (getAsset path)

assets["assets/sprites/white.png"] = """iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAAtJREFUCJlj+A8EAAn7A/3jVfKcAAAAAElFTkSuQmCC"""

assets["assets/shaders/main.fs"] = """I3ZlcnNpb24gNDMwCgppbiB2ZWMyIHZUZXhDb29yZHM7Cgp1bmlmb3JtIHNhbXBsZXIyRCBhdGxhczsKCm91dCB2ZWM0IGZyYWdDb2xvcjsKCnZvaWQgbWFpbigpIHsKCWZyYWdDb2xvciA9IHRleHR1cmUoYXRsYXMsIHZUZXhDb29yZHMpOwp9Cg=="""

assets["assets/shaders/main.vs"] = """I3ZlcnNpb24gNDMwCgpsYXlvdXQgKGxvY2F0aW9uID0gMCkgaW4gdmVjMyBhUG9zOwpsYXlvdXQgKGxvY2F0aW9uID0gMSkgaW4gdmVjMiBhVGV4Q29vcmRzOwoKbGF5b3V0IChsb2NhdGlvbiA9IDIpIGluIGludCBhTW9kZWxJbmRleDsKCnVuaWZvcm0gbWF0NCB2aWV3Owp1bmlmb3JtIG1hdDQgcHJvajsKCmxheW91dCAoc3RkNDMwLCBiaW5kaW5nID0gMCkgYnVmZmVyIE1vZGVscyB7CgltYXQ0IG1vZGVsc1tdOwp9OwoKb3V0IHZlYzIgdlRleENvb3JkczsKCnZvaWQgbWFpbigpIHsKCWdsX1Bvc2l0aW9uID0gcHJvaiAqIHZpZXcgKiBtb2RlbHNbYU1vZGVsSW5kZXhdICogdmVjNChhUG9zLCAxLjApOwoJdlRleENvb3JkcyA9IGFUZXhDb29yZHM7Cn0K"""

