import LeanEthKzg.Verifier.CryptoBoundary
import LeanEthKzg.Spec.Deneb
import LeanEthKzg.Spec.Fulu

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

structure NormalizationReport where
  api : VerificationApi
  transcript : TranscriptInput
  transcriptMessageCount : Nat
  transcriptPayloadByteSize : Nat
  normalizedInputCount : Nat
  uniqueCommitmentCount : Nat := 0
  deriving Repr, Inhabited

def NormalizationReport.ofTranscript
    (api : VerificationApi)
    (transcript : TranscriptInput)
    (normalizedInputCount : Nat)
    (uniqueCommitmentCount : Nat := 0) : NormalizationReport :=
  {
    api,
    transcript,
    transcriptMessageCount := transcript.messageCount,
    transcriptPayloadByteSize := transcript.totalMessageBytes,
    normalizedInputCount,
    uniqueCommitmentCount
  }

def toDecision (value : Bool) : Decision :=
  if value then .accept else .reject

def buildKzgProofQuery (input : NormalizedKzgProofInput) : KzgProofQuery :=
  KzgProofQuery.ofNormalizedInput input

def buildBlobProofQuery (input : NormalizedBlobProofInput) : BlobProofQuery :=
  BlobProofQuery.ofNormalizedInput input

def buildBlobBatchQuery (input : NormalizedBlobBatchInput) : BlobBatchQuery :=
  BlobBatchQuery.ofNormalizedInput input

def buildCellBatchQuery (input : NormalizedCellBatchInput) : CellBatchQuery :=
  CellBatchQuery.ofNormalizedInput input

def verifyNormalizedBlobKzgProof (backend : Backend) (input : NormalizedBlobProofInput) : Decision :=
  toDecision (backend.verifyBlobKzgProof (buildBlobProofQuery input))

def verifyNormalizedBlobKzgProofBatch (backend : Backend) (input : NormalizedBlobBatchInput) :
    Decision :=
  toDecision (backend.verifyBlobKzgProofBatch (buildBlobBatchQuery input))

def verificationDecision (result : DecodeResult (Prod Decision NormalizationReport)) : Decision :=
  match result with
  | .ok (decision, _) => decision
  | .error _ => .reject

def Backend.singletonBlobConsistent (backend : Backend) : Prop :=
  forall input : NormalizedBlobProofInput,
    backend.verifyBlobKzgProof (buildBlobProofQuery input) =
      backend.verifyBlobKzgProofBatch (buildBlobBatchQuery input.toSingletonBatch)

theorem verifyNormalizedBlobKzgProof_singletonBatchConsistency
    (backend : Backend)
    (h : backend.singletonBlobConsistent)
    (input : NormalizedBlobProofInput) :
    verifyNormalizedBlobKzgProof backend input =
      verifyNormalizedBlobKzgProofBatch backend input.toSingletonBatch := by
  unfold verifyNormalizedBlobKzgProof verifyNormalizedBlobKzgProofBatch
  exact congrArg toDecision (h input)

def verifyKzgProof (backend : Backend) (input : KzgProofInput) :
    DecodeResult (Prod Decision NormalizationReport) := do
  let normalized <- normalizeKzgProofInput input
  let query := buildKzgProofQuery normalized
  pure (
    toDecision (backend.verifyKzgProof query),
    NormalizationReport.ofTranscript .verifyKzgProof query.transcript 1
  )

def verifyBlobKzgProof (backend : Backend) (input : BlobProofInput) :
    DecodeResult (Prod Decision NormalizationReport) := do
  let normalized <- normalizeBlobProofInput input
  let query := buildBlobProofQuery normalized
  pure (
    toDecision (backend.verifyBlobKzgProof query),
    NormalizationReport.ofTranscript .verifyBlobKzgProof query.transcript 1
  )

def normalizeBlobBatchForVerification (input : BlobBatchInput) :
    DecodeResult NormalizedBlobBatchInput := do
  match input.asSingletonBlobProof? with
  | some singleton =>
      let single <- normalizeBlobProofInput singleton
      pure single.toSingletonBatch
  | none =>
      normalizeBlobBatchInput input

def verifyBlobKzgProofBatch (backend : Backend) (input : BlobBatchInput) :
    DecodeResult (Prod Decision NormalizationReport) := do
  let normalized <- normalizeBlobBatchForVerification input
  let query := buildBlobBatchQuery normalized
  pure (
    toDecision (backend.verifyBlobKzgProofBatch query),
    NormalizationReport.ofTranscript
      .verifyBlobKzgProofBatch
      query.transcript
      normalized.entries.size
  )

theorem normalizeBlobBatchForVerification_toSingletonBatch (input : BlobProofInput) :
    normalizeBlobBatchForVerification input.toSingletonBatch =
      match normalizeBlobProofInput input with
      | .ok normalized => .ok normalized.toSingletonBatch
      | .error err => .error err := by
  unfold normalizeBlobBatchForVerification
  simp [BlobBatchInput.asSingletonBlobProof?_toSingletonBatch]
  cases hNorm : normalizeBlobProofInput input <;> rfl

theorem verifyBlobKzgProof_singletonBatchConsistency
    (backend : Backend)
    (h : backend.singletonBlobConsistent)
    (input : BlobProofInput) :
    verificationDecision (verifyBlobKzgProof backend input) =
      verificationDecision (verifyBlobKzgProofBatch backend input.toSingletonBatch) := by
  unfold verificationDecision verifyBlobKzgProof verifyBlobKzgProofBatch
  rw [normalizeBlobBatchForVerification_toSingletonBatch]
  cases hNorm : normalizeBlobProofInput input with
  | error err =>
      rfl
  | ok normalized =>
      simpa using congrArg toDecision (h normalized)

def verifyCellKzgProofBatch (backend : Backend) (input : CellBatchInput) :
    DecodeResult (Prod Decision NormalizationReport) := do
  let normalized <- normalizeCellBatchInput input
  let query := buildCellBatchQuery normalized
  pure (
    toDecision (backend.verifyCellKzgProofBatch query),
    NormalizationReport.ofTranscript
      .verifyCellKzgProofBatch
      query.transcript
      normalized.cells.size
      normalized.uniqueCommitments.size
  )

end LeanEthKzg.Verifier
