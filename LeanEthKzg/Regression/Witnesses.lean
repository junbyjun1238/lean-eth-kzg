import LeanEthKzg.Regression.Invariants
import LeanEthKzg.Conformance.Targets

namespace LeanEthKzg.Regression

open LeanEthKzg.Conformance

inductive WitnessFamily where
  | threshold789
  | duplicateCommitments
  | pointAtInfinity
  | malformedBytes
  | permutationEquivalentBatches
  | fuluCellOrdering
  deriving Repr, BEq, DecidableEq, Inhabited

def WitnessFamily.expectedFailures : WitnessFamily -> Array CKZGTag
  | .threshold789 => #[.v2_1_2]
  | .duplicateCommitments => #[.v2_1_4]
  | .pointAtInfinity => #[.v2_1_2]
  | .malformedBytes => #[]
  | .permutationEquivalentBatches => #[]
  | .fuluCellOrdering => #[]

def WitnessFamily.relatedBugClass : WitnessFamily -> Option BugClass
  | .threshold789 => some .pointAtInfinityFastPath
  | .duplicateCommitments => some .dedupWeakFiatShamir
  | .pointAtInfinity => some .pointAtInfinityFastPath
  | .malformedBytes => none
  | .permutationEquivalentBatches => none
  | .fuluCellOrdering => none

def WitnessFamily.summary : WitnessFamily -> String
  | .threshold789 => "Edge cases around the 7/8/9 fast-path threshold."
  | .duplicateCommitments => "Repeated commitments that should still bind every unique commitment."
  | .pointAtInfinity => "Invalid-point cases that must not slip through the batch fast path."
  | .malformedBytes => "Non-canonical lengths and malformed byte payloads."
  | .permutationEquivalentBatches => "Equivalent batches whose normalization order should not change semantics."
  | .fuluCellOrdering => "Corner cases around Fulu cell indexing and grouping."

end LeanEthKzg.Regression
