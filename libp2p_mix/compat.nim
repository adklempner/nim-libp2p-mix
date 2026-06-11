## Compatibility shim for older nim-libp2p (ff8d518) which lacks libp2p/crypto/rng.
## Provides randBelow / pick / pickOne backports.
{.push raises: [].}

import results
import libp2p/crypto/crypto

import ./curve25519
export curve25519.Rng

proc randBelow*(rng: Rng, max: uint32): int =
  let threshold = (0'u32 - max) mod max
  while true:
    var bytes: array[4, byte]
    rng[].generate(bytes)
    let r =
      bytes[0].uint32 or (bytes[1].uint32 shl 8) or (bytes[2].uint32 shl 16) or
      (bytes[3].uint32 shl 24)
    if r >= threshold:
      return (r mod max).int

proc pick*[T](rng: Rng, x: openArray[T], n: int): Opt[seq[T]] =
  doAssert n >= 0, "n must be non-negative"
  if x.len == 0:
    return Opt.none(seq[T])
  if n == 0:
    return Opt.some(newSeq[T]())

  var indices = newSeq[int](x.len)
  for i in 0 ..< x.len:
    indices[i] = i

  let count = min(n, x.len)
  var output = newSeq[T](count)
  for i in 0 ..< count:
    let j = i + rng.randBelow((x.len - i).uint32)
    swap(indices[i], indices[j])
    output[i] = x[indices[i]]
  Opt.some(output)

proc pickOne*[T](rng: Rng, x: openArray[T]): Opt[T] =
  if x.len == 0:
    return Opt.none(T)
  Opt.some(x[rng.randBelow(x.len.uint32)])
