namespace LeanEthKzg

/-- Shared byte-oriented definitions used across verifier-facing specs. -/
abbrev Bytes := ByteArray

instance : Inhabited Bytes where
  default := ByteArray.empty

instance : Repr Bytes where
  reprPrec xs _ :=
    repr xs.toList

/--
Encode `value` as a big-endian byte array of exactly `width` bytes.
Values larger than `256 ^ width - 1` are truncated to their low `width` bytes.
-/
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
