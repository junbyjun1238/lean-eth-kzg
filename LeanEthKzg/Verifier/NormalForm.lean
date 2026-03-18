import LeanEthKzg.Verifier.API

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

theorem normalizeKzgProofInput_deterministic
    (input : KzgProofInput)
    {normalized₁ normalized₂ : NormalizedKzgProofInput}
    (h₁ : normalizeKzgProofInput input = .ok normalized₁)
    (h₂ : normalizeKzgProofInput input = .ok normalized₂) :
    normalized₁ = normalized₂ := by
  rw [h₁] at h₂
  cases h₂
  rfl

theorem normalizeBlobProofInput_deterministic
    (input : BlobProofInput)
    {normalized₁ normalized₂ : NormalizedBlobProofInput}
    (h₁ : normalizeBlobProofInput input = .ok normalized₁)
    (h₂ : normalizeBlobProofInput input = .ok normalized₂) :
    normalized₁ = normalized₂ := by
  rw [h₁] at h₂
  cases h₂
  rfl

theorem normalizeBlobBatchForVerification_deterministic
    (input : BlobBatchInput)
    {normalized₁ normalized₂ : NormalizedBlobBatchInput}
    (h₁ : normalizeBlobBatchForVerification input = .ok normalized₁)
    (h₂ : normalizeBlobBatchForVerification input = .ok normalized₂) :
    normalized₁ = normalized₂ := by
  rw [h₁] at h₂
  cases h₂
  rfl

theorem normalizeCellBatchInput_deterministic
    (input : CellBatchInput)
    {normalized₁ normalized₂ : NormalizedCellBatchInput}
    (h₁ : normalizeCellBatchInput input = .ok normalized₁)
    (h₂ : normalizeCellBatchInput input = .ok normalized₂) :
    normalized₁ = normalized₂ := by
  rw [h₁] at h₂
  cases h₂
  rfl

theorem kzgProofTranscript_deterministic
    (input : KzgProofInput)
    {normalized₁ normalized₂ : NormalizedKzgProofInput}
    (h₁ : normalizeKzgProofInput input = .ok normalized₁)
    (h₂ : normalizeKzgProofInput input = .ok normalized₂) :
    kzgProofTranscript normalized₁ = kzgProofTranscript normalized₂ := by
  cases normalizeKzgProofInput_deterministic input h₁ h₂
  rfl

theorem blobProofTranscript_deterministic
    (input : BlobProofInput)
    {normalized₁ normalized₂ : NormalizedBlobProofInput}
    (h₁ : normalizeBlobProofInput input = .ok normalized₁)
    (h₂ : normalizeBlobProofInput input = .ok normalized₂) :
    blobProofTranscript normalized₁ = blobProofTranscript normalized₂ := by
  cases normalizeBlobProofInput_deterministic input h₁ h₂
  rfl

theorem blobBatchTranscript_deterministic
    (input : BlobBatchInput)
    {normalized₁ normalized₂ : NormalizedBlobBatchInput}
    (h₁ : normalizeBlobBatchForVerification input = .ok normalized₁)
    (h₂ : normalizeBlobBatchForVerification input = .ok normalized₂) :
    blobBatchTranscript normalized₁ = blobBatchTranscript normalized₂ := by
  cases normalizeBlobBatchForVerification_deterministic input h₁ h₂
  rfl

theorem cellBatchTranscript_deterministic
    (input : CellBatchInput)
    {normalized₁ normalized₂ : NormalizedCellBatchInput}
    (h₁ : normalizeCellBatchInput input = .ok normalized₁)
    (h₂ : normalizeCellBatchInput input = .ok normalized₂) :
    cellBatchTranscript normalized₁ = cellBatchTranscript normalized₂ := by
  cases normalizeCellBatchInput_deterministic input h₁ h₂
  rfl

end LeanEthKzg.Verifier
