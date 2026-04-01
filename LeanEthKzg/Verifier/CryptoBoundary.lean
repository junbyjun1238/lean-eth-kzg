import LeanEthKzg.Spec.Types

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

end LeanEthKzg.Verifier
