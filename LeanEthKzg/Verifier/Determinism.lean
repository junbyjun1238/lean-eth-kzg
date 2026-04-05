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
  unfold verificationDecision verifyKzgProof normalizeAndBuildKzgProofQuery
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

theorem normalizeAndBuildKzgProofQuery_rejectsOnNormalizationError
    (input : KzgProofInput)
    (err : NormalizationError)
    (h : normalizeKzgProofInput input = .error err) :
    normalizeAndBuildKzgProofQuery input = .error err := by
  unfold normalizeAndBuildKzgProofQuery
  rw [h]
  rfl

theorem normalizeAndBuildKzgProofQuery_noQueryOnNormalizationError
    (input : KzgProofInput)
    (err : NormalizationError)
    (query : KzgProofQuery)
    (h : normalizeKzgProofInput input = .error err) :
    normalizeAndBuildKzgProofQuery input ≠ .ok query := by
  rw [normalizeAndBuildKzgProofQuery_rejectsOnNormalizationError input err h]
  simp

theorem verifyBlobKzgProof_rejectsOnNormalizationError
    (backend : Backend)
    (input : BlobProofInput)
    (err : NormalizationError)
    (h : normalizeBlobProofInput input = .error err) :
    verificationDecision (verifyBlobKzgProof backend input) = .reject := by
  unfold verificationDecision verifyBlobKzgProof normalizeAndBuildBlobProofQuery
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

theorem normalizeAndBuildBlobProofQuery_rejectsOnNormalizationError
    (input : BlobProofInput)
    (err : NormalizationError)
    (h : normalizeBlobProofInput input = .error err) :
    normalizeAndBuildBlobProofQuery input = .error err := by
  unfold normalizeAndBuildBlobProofQuery
  rw [h]
  rfl

theorem normalizeAndBuildBlobProofQuery_noQueryOnNormalizationError
    (input : BlobProofInput)
    (err : NormalizationError)
    (query : BlobProofQuery)
    (h : normalizeBlobProofInput input = .error err) :
    normalizeAndBuildBlobProofQuery input ≠ .ok query := by
  rw [normalizeAndBuildBlobProofQuery_rejectsOnNormalizationError input err h]
  simp

theorem verifyBlobKzgProofBatch_rejectsOnNormalizationError
    (backend : Backend)
    (input : BlobBatchInput)
    (err : NormalizationError)
    (h : normalizeBlobBatchForVerification input = .error err) :
    verificationDecision (verifyBlobKzgProofBatch backend input) = .reject := by
  unfold verificationDecision verifyBlobKzgProofBatch normalizeAndBuildBlobBatchQuery
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

theorem normalizeAndBuildBlobBatchQuery_rejectsOnNormalizationError
    (input : BlobBatchInput)
    (err : NormalizationError)
    (h : normalizeBlobBatchForVerification input = .error err) :
    normalizeAndBuildBlobBatchQuery input = .error err := by
  unfold normalizeAndBuildBlobBatchQuery
  rw [h]
  rfl

theorem normalizeAndBuildBlobBatchQuery_noQueryOnNormalizationError
    (input : BlobBatchInput)
    (err : NormalizationError)
    (query : BlobBatchQuery)
    (h : normalizeBlobBatchForVerification input = .error err) :
    normalizeAndBuildBlobBatchQuery input ≠ .ok query := by
  rw [normalizeAndBuildBlobBatchQuery_rejectsOnNormalizationError input err h]
  simp

theorem verifyCellKzgProofBatch_rejectsOnNormalizationError
    (backend : Backend)
    (input : CellBatchInput)
    (err : NormalizationError)
    (h : normalizeCellBatchInput input = .error err) :
    verificationDecision (verifyCellKzgProofBatch backend input) = .reject := by
  unfold verificationDecision verifyCellKzgProofBatch normalizeAndBuildCellBatchQuery
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

theorem normalizeAndBuildCellBatchQuery_rejectsOnNormalizationError
    (input : CellBatchInput)
    (err : NormalizationError)
    (h : normalizeCellBatchInput input = .error err) :
    normalizeAndBuildCellBatchQuery input = .error err := by
  unfold normalizeAndBuildCellBatchQuery
  rw [h]
  rfl

theorem normalizeAndBuildCellBatchQuery_noQueryOnNormalizationError
    (input : CellBatchInput)
    (err : NormalizationError)
    (query : CellBatchQuery)
    (h : normalizeCellBatchInput input = .error err) :
    normalizeAndBuildCellBatchQuery input ≠ .ok query := by
  rw [normalizeAndBuildCellBatchQuery_rejectsOnNormalizationError input err h]
  simp

end LeanEthKzg.Verifier
