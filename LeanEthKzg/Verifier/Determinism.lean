import LeanEthKzg.Verifier.API

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

theorem verificationDecision_error (err : NormalizationError) :
    verificationDecision (.error err) = .reject := by
  rfl

theorem verifyKzgProof_rejectsOnNormalizationError
    (backend : Backend)
    (input : KzgProofInput)
    (err : NormalizationError)
    (h : normalizeKzgProofInput input = .error err) :
    verificationDecision (verifyKzgProof backend input) = .reject := by
  unfold verificationDecision verifyKzgProof
  rw [h]
  rfl

theorem verifyKzgProof_invalidInputDeterministic
    (backend1 backend2 : Backend)
    (input : KzgProofInput)
    (err : NormalizationError)
    (h : normalizeKzgProofInput input = .error err) :
    verificationDecision (verifyKzgProof backend1 input) =
      verificationDecision (verifyKzgProof backend2 input) := by
  rw [
    verifyKzgProof_rejectsOnNormalizationError backend1 input err h,
    verifyKzgProof_rejectsOnNormalizationError backend2 input err h
  ]

theorem verifyBlobKzgProof_rejectsOnNormalizationError
    (backend : Backend)
    (input : BlobProofInput)
    (err : NormalizationError)
    (h : normalizeBlobProofInput input = .error err) :
    verificationDecision (verifyBlobKzgProof backend input) = .reject := by
  unfold verificationDecision verifyBlobKzgProof
  rw [h]
  rfl

theorem verifyBlobKzgProof_invalidInputDeterministic
    (backend1 backend2 : Backend)
    (input : BlobProofInput)
    (err : NormalizationError)
    (h : normalizeBlobProofInput input = .error err) :
    verificationDecision (verifyBlobKzgProof backend1 input) =
      verificationDecision (verifyBlobKzgProof backend2 input) := by
  rw [
    verifyBlobKzgProof_rejectsOnNormalizationError backend1 input err h,
    verifyBlobKzgProof_rejectsOnNormalizationError backend2 input err h
  ]

theorem verifyBlobKzgProofBatch_rejectsOnNormalizationError
    (backend : Backend)
    (input : BlobBatchInput)
    (err : NormalizationError)
    (h : normalizeBlobBatchForVerification input = .error err) :
    verificationDecision (verifyBlobKzgProofBatch backend input) = .reject := by
  unfold verificationDecision verifyBlobKzgProofBatch
  rw [h]
  rfl

theorem verifyBlobKzgProofBatch_invalidInputDeterministic
    (backend1 backend2 : Backend)
    (input : BlobBatchInput)
    (err : NormalizationError)
    (h : normalizeBlobBatchForVerification input = .error err) :
    verificationDecision (verifyBlobKzgProofBatch backend1 input) =
      verificationDecision (verifyBlobKzgProofBatch backend2 input) := by
  rw [
    verifyBlobKzgProofBatch_rejectsOnNormalizationError backend1 input err h,
    verifyBlobKzgProofBatch_rejectsOnNormalizationError backend2 input err h
  ]

theorem verifyCellKzgProofBatch_rejectsOnNormalizationError
    (backend : Backend)
    (input : CellBatchInput)
    (err : NormalizationError)
    (h : normalizeCellBatchInput input = .error err) :
    verificationDecision (verifyCellKzgProofBatch backend input) = .reject := by
  unfold verificationDecision verifyCellKzgProofBatch
  rw [h]
  rfl

theorem verifyCellKzgProofBatch_invalidInputDeterministic
    (backend1 backend2 : Backend)
    (input : CellBatchInput)
    (err : NormalizationError)
    (h : normalizeCellBatchInput input = .error err) :
    verificationDecision (verifyCellKzgProofBatch backend1 input) =
      verificationDecision (verifyCellKzgProofBatch backend2 input) := by
  rw [
    verifyCellKzgProofBatch_rejectsOnNormalizationError backend1 input err h,
    verifyCellKzgProofBatch_rejectsOnNormalizationError backend2 input err h
  ]

end LeanEthKzg.Verifier
