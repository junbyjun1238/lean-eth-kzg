namespace LeanEthKzg.Regression

inductive BugClass where
  | pointAtInfinityFastPath
  | dedupWeakFiatShamir
  deriving Repr, BEq, DecidableEq, Inhabited

inductive Invariant where
  | invalidInputDeterminism
  | singletonBatchConsistency
  | batchNormalFormDeterminism
  | challengeCanonicality
  | fastPathNaiveAgreement
  | uniqueCommitmentBinding
  deriving Repr, BEq, DecidableEq, Inhabited

def Invariant.summary : Invariant -> String
  | .invalidInputDeterminism => "Malformed byte inputs must be rejected deterministically."
  | .singletonBatchConsistency => "Singleton batch APIs must agree with their single-input counterpart."
  | .batchNormalFormDeterminism => "Normalization and deduplication must not depend on incidental ordering."
  | .challengeCanonicality => "Challenge inputs must be derived from a canonical transcript."
  | .fastPathNaiveAgreement => "Fast and naive verification paths must agree on normalized inputs."
  | .uniqueCommitmentBinding => "Every unique commitment used by the statement must be bound into the challenge."

def BugClass.blockedBy : BugClass -> Array Invariant
  | .pointAtInfinityFastPath => #[.fastPathNaiveAgreement, .invalidInputDeterminism]
  | .dedupWeakFiatShamir => #[.challengeCanonicality, .uniqueCommitmentBinding]

end LeanEthKzg.Regression
