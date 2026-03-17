import LeanEthKzg.Bytes

namespace LeanEthKzg.Spec

abbrev CommitmentBytes := Bytes
abbrev ProofBytes := Bytes
abbrev BlobBytes := Bytes
abbrev CellBytes := Bytes
abbrev FieldElementBytes := Bytes

def bytesPerCommitment : Nat := 48
def bytesPerProof : Nat := 48
def bytesPerFieldElement : Nat := 32
def fieldElementsPerBlob : Nat := 4096
def bytesPerBlob : Nat := bytesPerFieldElement * fieldElementsPerBlob
def fieldElementsPerExtendedBlob : Nat := 2 * fieldElementsPerBlob
def fieldElementsPerCell : Nat := 64
def bytesPerCell : Nat := fieldElementsPerCell * bytesPerFieldElement
def cellsPerExtendedBlob : Nat := fieldElementsPerExtendedBlob / fieldElementsPerCell

def blobFiatShamirDomain : String := "FSBLOBVERIFY_V1_"
def blobBatchChallengeDomain : String := "RCKZGBATCH___V1_"
def cellBatchChallengeDomain : String := "RCKZGCBATCH__V1_"

inductive Decision where
  | accept
  | reject
  deriving Repr, BEq, DecidableEq, Inhabited

inductive NormalizationError where
  | wrongLength (label : String) (expected actual : Nat)
  | wrongVectorLength (label : String) (expected actual : Nat)
  | indexOutOfBounds (label : String) (upperBound actual : Nat)
  deriving Repr, BEq, DecidableEq, Inhabited

abbrev DecodeResult (T : Type) := Except NormalizationError T

structure TranscriptInput where
  domain : String
  messages : Array Bytes
  deriving Repr, Inhabited

def ensureLength (label : String) (expected : Nat) (value : Bytes) : DecodeResult Bytes :=
  if value.size = expected then
    .ok value
  else
    .error (.wrongLength label expected value.size)

def ensureVectorLength (label : String) (expected actual : Nat) : DecodeResult Unit :=
  if expected = actual then
    .ok ()
  else
    .error (.wrongVectorLength label expected actual)

def ensureIndex (label : String) (upperBound : Nat) (value : UInt64) : DecodeResult UInt64 :=
  if value.toNat < upperBound then
    .ok value
  else
    .error (.indexOutOfBounds label upperBound value.toNat)

def transcript (domain : String) (messages : Array Bytes) : TranscriptInput :=
  { domain, messages }

end LeanEthKzg.Spec
