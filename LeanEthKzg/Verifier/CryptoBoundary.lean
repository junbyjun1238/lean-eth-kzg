import LeanEthKzg.Spec.Types
import LeanEthKzg.Spec.Deneb

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

/--
`CryptoBoundary` is the home for the explicit interface between Lean-side
byte-level verifier semantics and external cryptographic backends.

The current commit introduces names for the cryptographic predicates that are
still owned by external backends.
-/
abbrev CommitmentDecodePredicate := CommitmentBytes -> Prop

abbrev ProofDecodePredicate := ProofBytes -> Prop

abbrev FieldElementCanonicalPredicate := FieldElementBytes -> Prop

abbrev CommitmentSubgroupPredicate := CommitmentBytes -> Prop

abbrev ProofSubgroupPredicate := ProofBytes -> Prop

abbrev CommitmentNotInfinityPredicate := CommitmentBytes -> Prop

abbrev ProofNotInfinityPredicate := ProofBytes -> Prop

structure KzgProofBoundaryRequirements where
  commitmentDecodes : CommitmentDecodePredicate
  proofDecodes : ProofDecodePredicate
  evaluationPointCanonical : FieldElementCanonicalPredicate
  claimedValueCanonical : FieldElementCanonicalPredicate
  commitmentInSubgroup : CommitmentSubgroupPredicate
  proofInSubgroup : ProofSubgroupPredicate
  commitmentNotInfinity : CommitmentNotInfinityPredicate
  proofNotInfinity : ProofNotInfinityPredicate

def KzgProofBoundaryRequirements.holdsFor
    (requirements : KzgProofBoundaryRequirements)
    (input : NormalizedKzgProofInput) : Prop :=
  requirements.commitmentDecodes input.commitment /\
  requirements.proofDecodes input.proof /\
  requirements.evaluationPointCanonical input.evaluationPoint /\
  requirements.claimedValueCanonical input.claimedValue /\
  requirements.commitmentInSubgroup input.commitment /\
  requirements.proofInSubgroup input.proof /\
  requirements.commitmentNotInfinity input.commitment /\
  requirements.proofNotInfinity input.proof

end LeanEthKzg.Verifier
