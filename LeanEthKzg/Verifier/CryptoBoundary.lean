import LeanEthKzg.Spec.Types
import LeanEthKzg.Spec.Deneb
import LeanEthKzg.Spec.Fulu

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

abbrev BlobFieldElementsCanonicalPredicate := BlobBytes -> Prop

abbrev BlobBatchEntriesCanonicalPredicate := Array BlobBatchEntry -> Prop

abbrev CellFieldElementsCanonicalPredicate := CellBytes -> Prop

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

structure KzgProofQuery where
  normalizedInput : NormalizedKzgProofInput
  transcript : TranscriptInput

def KzgProofQuery.ofNormalizedInput (input : NormalizedKzgProofInput) : KzgProofQuery :=
  {
    normalizedInput := input
    transcript := kzgProofTranscript input
  }

structure BlobProofBoundaryRequirements where
  blobFieldElementsCanonical : BlobFieldElementsCanonicalPredicate
  commitmentDecodes : CommitmentDecodePredicate
  proofDecodes : ProofDecodePredicate
  commitmentInSubgroup : CommitmentSubgroupPredicate
  proofInSubgroup : ProofSubgroupPredicate
  commitmentNotInfinity : CommitmentNotInfinityPredicate
  proofNotInfinity : ProofNotInfinityPredicate

def BlobProofBoundaryRequirements.holdsFor
    (requirements : BlobProofBoundaryRequirements)
    (input : NormalizedBlobProofInput) : Prop :=
  requirements.blobFieldElementsCanonical input.blob /\
  requirements.commitmentDecodes input.commitment /\
  requirements.proofDecodes input.proof /\
  requirements.commitmentInSubgroup input.commitment /\
  requirements.proofInSubgroup input.proof /\
  requirements.commitmentNotInfinity input.commitment /\
  requirements.proofNotInfinity input.proof

structure BlobProofQuery where
  normalizedInput : NormalizedBlobProofInput
  transcript : TranscriptInput

def BlobProofQuery.ofNormalizedInput (input : NormalizedBlobProofInput) : BlobProofQuery :=
  {
    normalizedInput := input
    transcript := blobProofTranscript input
  }

structure BlobBatchBoundaryRequirements where
  entriesCanonical : BlobBatchEntriesCanonicalPredicate
  commitmentDecodes : CommitmentDecodePredicate
  proofDecodes : ProofDecodePredicate
  commitmentInSubgroup : CommitmentSubgroupPredicate
  proofInSubgroup : ProofSubgroupPredicate
  commitmentNotInfinity : CommitmentNotInfinityPredicate
  proofNotInfinity : ProofNotInfinityPredicate

def BlobBatchBoundaryRequirements.holdsFor
    (requirements : BlobBatchBoundaryRequirements)
    (input : NormalizedBlobBatchInput) : Prop :=
  requirements.entriesCanonical input.entries /\
  (forall entry : BlobBatchEntry, entry ∈ input.entries ->
    requirements.commitmentDecodes entry.commitment /\
    requirements.proofDecodes entry.proof /\
    requirements.commitmentInSubgroup entry.commitment /\
    requirements.proofInSubgroup entry.proof /\
    requirements.commitmentNotInfinity entry.commitment /\
    requirements.proofNotInfinity entry.proof)

structure BlobBatchQuery where
  normalizedInput : NormalizedBlobBatchInput
  transcript : TranscriptInput

def BlobBatchQuery.ofNormalizedInput (input : NormalizedBlobBatchInput) : BlobBatchQuery :=
  {
    normalizedInput := input
    transcript := blobBatchTranscript input
  }

structure CellBatchBoundaryRequirements where
  cellFieldElementsCanonical : CellFieldElementsCanonicalPredicate
  commitmentDecodes : CommitmentDecodePredicate
  proofDecodes : ProofDecodePredicate
  commitmentInSubgroup : CommitmentSubgroupPredicate
  proofInSubgroup : ProofSubgroupPredicate
  commitmentNotInfinity : CommitmentNotInfinityPredicate
  proofNotInfinity : ProofNotInfinityPredicate

def CellBatchBoundaryRequirements.holdsFor
    (requirements : CellBatchBoundaryRequirements)
    (input : NormalizedCellBatchInput) : Prop :=
  (forall commitment : CommitmentBytes, commitment ∈ input.uniqueCommitments ->
    requirements.commitmentDecodes commitment /\
    requirements.commitmentInSubgroup commitment /\
    requirements.commitmentNotInfinity commitment) /\
  (forall cell : CellBytes, cell ∈ input.cells ->
    requirements.cellFieldElementsCanonical cell) /\
  (forall proof : ProofBytes, proof ∈ input.proofs ->
    requirements.proofDecodes proof /\
    requirements.proofInSubgroup proof /\
    requirements.proofNotInfinity proof)

structure CellBatchQuery where
  normalizedInput : NormalizedCellBatchInput
  transcript : TranscriptInput

def CellBatchQuery.ofNormalizedInput (input : NormalizedCellBatchInput) : CellBatchQuery :=
  {
    normalizedInput := input
    transcript := cellBatchTranscript input
  }

structure Backend where
  verifyKzgProof : KzgProofQuery -> Bool
  verifyBlobKzgProof : BlobProofQuery -> Bool
  verifyBlobKzgProofBatch : BlobBatchQuery -> Bool
  verifyCellKzgProofBatch : CellBatchQuery -> Bool

def rejectAll : Backend where
  verifyKzgProof := fun _ => false
  verifyBlobKzgProof := fun _ => false
  verifyBlobKzgProofBatch := fun _ => false
  verifyCellKzgProofBatch := fun _ => false

def acceptAll : Backend where
  verifyKzgProof := fun _ => true
  verifyBlobKzgProof := fun _ => true
  verifyBlobKzgProofBatch := fun _ => true
  verifyCellKzgProofBatch := fun _ => true

end LeanEthKzg.Verifier
