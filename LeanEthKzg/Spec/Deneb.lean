import LeanEthKzg.Spec.Types

namespace LeanEthKzg.Spec

structure KzgProofInput where
  commitment : CommitmentBytes
  evaluationPoint : FieldElementBytes
  claimedValue : FieldElementBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure BlobProofInput where
  blob : BlobBytes
  commitment : CommitmentBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure BlobBatchInput where
  blobs : Array BlobBytes
  commitments : Array CommitmentBytes
  proofs : Array ProofBytes
  deriving Repr, Inhabited

structure NormalizedKzgProofInput where
  commitment : CommitmentBytes
  evaluationPoint : FieldElementBytes
  claimedValue : FieldElementBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure NormalizedBlobProofInput where
  blob : BlobBytes
  commitment : CommitmentBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure BlobBatchEntry where
  blob : BlobBytes
  commitment : CommitmentBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure NormalizedBlobBatchInput where
  entries : Array BlobBatchEntry
  deriving Repr, Inhabited

def normalizeKzgProofInput (input : KzgProofInput) : DecodeResult NormalizedKzgProofInput := do
  let commitment <- ensureLength "commitment" bytesPerCommitment input.commitment
  let evaluationPoint <- ensureLength "evaluation_point" bytesPerFieldElement input.evaluationPoint
  let claimedValue <- ensureLength "claimed_value" bytesPerFieldElement input.claimedValue
  let proof <- ensureLength "proof" bytesPerProof input.proof
  pure { commitment, evaluationPoint, claimedValue, proof }

def normalizeBlobProofInput (input : BlobProofInput) : DecodeResult NormalizedBlobProofInput := do
  let blob <- ensureLength "blob" bytesPerBlob input.blob
  let commitment <- ensureLength "commitment" bytesPerCommitment input.commitment
  let proof <- ensureLength "proof" bytesPerProof input.proof
  pure { blob, commitment, proof }

def normalizeBlobBatchInput (input : BlobBatchInput) : DecodeResult NormalizedBlobBatchInput := do
  ensureVectorLength "blob_batch.commitments" input.blobs.size input.commitments.size
  ensureVectorLength "blob_batch.proofs" input.blobs.size input.proofs.size
  let mut entries : Array BlobBatchEntry := #[]
  for h : i in [0:input.blobs.size] do
    let blob <- ensureLength s!"blob_batch.blobs[{i}]" bytesPerBlob input.blobs[i]
    let commitment <- ensureLength s!"blob_batch.commitments[{i}]" bytesPerCommitment input.commitments[i]!
    let proof <- ensureLength s!"blob_batch.proofs[{i}]" bytesPerProof input.proofs[i]!
    entries := entries.push { blob, commitment, proof }
  pure { entries }

def kzgProofTranscript (input : NormalizedKzgProofInput) : TranscriptInput :=
  transcript "verify_kzg_proof" #[
    input.commitment,
    input.evaluationPoint,
    input.claimedValue,
    input.proof
  ]

def blobProofTranscript (input : NormalizedBlobProofInput) : TranscriptInput :=
  transcript blobFiatShamirDomain #[
    input.blob,
    input.commitment,
    input.proof
  ]

def blobBatchTranscript (input : NormalizedBlobBatchInput) : TranscriptInput :=
  let count := LeanEthKzg.natToFixedWidthBE 8 input.entries.size
  let messages :=
    input.entries.foldl
      (fun acc entry => acc.push entry.blob |>.push entry.commitment |>.push entry.proof)
      #[count]
  transcript "verify_blob_kzg_proof_batch" messages

end LeanEthKzg.Spec
