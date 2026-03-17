import LeanEthKzg.Spec.Deneb
import LeanEthKzg.Spec.Fulu

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

structure NormalizationReport where
  transcript : TranscriptInput
  uniqueCommitmentCount : Nat := 0
  deriving Repr, Inhabited

structure Backend where
  verifyKzgProof : NormalizedKzgProofInput -> Bool
  verifyBlobKzgProof : NormalizedBlobProofInput -> Bool
  verifyBlobKzgProofBatch : NormalizedBlobBatchInput -> Bool
  verifyCellKzgProofBatch : NormalizedCellBatchInput -> Bool

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

def toDecision (value : Bool) : Decision :=
  if value then .accept else .reject

def verifyKzgProof (backend : Backend) (input : KzgProofInput) :
    DecodeResult (Decision × NormalizationReport) := do
  let normalized <- normalizeKzgProofInput input
  let transcript := kzgProofTranscript normalized
  pure (toDecision (backend.verifyKzgProof normalized), { transcript })

def verifyBlobKzgProof (backend : Backend) (input : BlobProofInput) :
    DecodeResult (Decision × NormalizationReport) := do
  let normalized <- normalizeBlobProofInput input
  let transcript := blobProofTranscript normalized
  pure (toDecision (backend.verifyBlobKzgProof normalized), { transcript })

def verifyBlobKzgProofBatch (backend : Backend) (input : BlobBatchInput) :
    DecodeResult (Decision × NormalizationReport) := do
  let normalized <- normalizeBlobBatchInput input
  let transcript := blobBatchTranscript normalized
  pure (toDecision (backend.verifyBlobKzgProofBatch normalized), { transcript })

def verifyCellKzgProofBatch (backend : Backend) (input : CellBatchInput) :
    DecodeResult (Decision × NormalizationReport) := do
  let normalized <- normalizeCellBatchInput input
  let transcript := cellBatchTranscript normalized
  pure (
    toDecision (backend.verifyCellKzgProofBatch normalized),
    {
      transcript,
      uniqueCommitmentCount := normalized.uniqueCommitments.size
    }
  )

end LeanEthKzg.Verifier
