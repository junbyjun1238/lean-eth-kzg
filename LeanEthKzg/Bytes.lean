namespace LeanEthKzg

abbrev Bytes := ByteArray

instance : Inhabited Bytes where
  default := ByteArray.empty

instance : Repr Bytes where
  reprPrec xs _ :=
    repr xs.toList

def byteCount (xs : Bytes) : Nat :=
  xs.size

def natToFixedWidthBE (width : Nat) (value : Nat) : Bytes :=
  Id.run do
    let mut out := ByteArray.empty
    for idx in List.range width do
      let shift := width - idx - 1
      let divisor := 256 ^ shift
      let byte := (value / divisor) % 256
      out := out.push (UInt8.ofNat byte)
    return out

end LeanEthKzg
