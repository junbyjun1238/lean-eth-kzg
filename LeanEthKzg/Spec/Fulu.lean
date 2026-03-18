import LeanEthKzg.Spec.Types

namespace LeanEthKzg.Spec

structure CellProofCase where
  commitment : CommitmentBytes
  cellIndex : UInt64
  cell : CellBytes
  proof : ProofBytes
  deriving Repr, Inhabited

structure CellBatchInput where
  commitments : Array CommitmentBytes
  cellIndices : Array UInt64
  cells : Array CellBytes
  proofs : Array ProofBytes
  deriving Repr, Inhabited

structure NormalizedCellBatchInput where
  commitments : Array CommitmentBytes
  uniqueCommitments : Array CommitmentBytes
  commitmentIndices : Array UInt64
  cellIndices : Array UInt64
  cells : Array CellBytes
  proofs : Array ProofBytes
  deriving Repr, Inhabited

private def stableDedupCommitments (commitments : Array CommitmentBytes) : Array CommitmentBytes :=
  commitments.foldl
    (fun acc commitment =>
      if acc.contains commitment then acc else acc.push commitment)
    #[]

private def firstCommitmentIndex (commitments : Array CommitmentBytes) (target : CommitmentBytes) : Nat :=
  let rec go (idx : Nat) (rest : List CommitmentBytes) : Nat :=
    match rest with
    | [] => 0
    | head :: tail =>
        if head == target then idx else go (idx + 1) tail
  go 0 commitments.toList

def normalizeCellBatchInput (input : CellBatchInput) : DecodeResult NormalizedCellBatchInput := do
  ensureVectorLength "cell_batch.cell_indices" input.commitments.size input.cellIndices.size
  ensureVectorLength "cell_batch.cells" input.commitments.size input.cells.size
  ensureVectorLength "cell_batch.proofs" input.commitments.size input.proofs.size
  let mut commitments : Array CommitmentBytes := #[]
  let mut cellIndices : Array UInt64 := #[]
  let mut cells : Array CellBytes := #[]
  let mut proofs : Array ProofBytes := #[]
  for h : i in [0:input.commitments.size] do
    let commitment <- ensureLength s!"cell_batch.commitments[{i}]" bytesPerCommitment input.commitments[i]
    let cellIndex <- ensureIndex s!"cell_batch.cell_indices[{i}]" cellsPerExtendedBlob input.cellIndices[i]!
    let cell <- ensureLength s!"cell_batch.cells[{i}]" bytesPerCell input.cells[i]!
    let proof <- ensureLength s!"cell_batch.proofs[{i}]" bytesPerProof input.proofs[i]!
    commitments := commitments.push commitment
    cellIndices := cellIndices.push cellIndex
    cells := cells.push cell
    proofs := proofs.push proof
  let uniqueCommitments := stableDedupCommitments commitments
  let commitmentIndices :=
    commitments.map (fun commitment => UInt64.ofNat (firstCommitmentIndex uniqueCommitments commitment))
  pure {
    commitments,
    uniqueCommitments,
    commitmentIndices,
    cellIndices,
    cells,
    proofs
  }

def cellBatchTranscriptHeader (input : NormalizedCellBatchInput) : Array Bytes :=
  #[
    LeanEthKzg.natToFixedWidthBE 8 fieldElementsPerBlob,
    LeanEthKzg.natToFixedWidthBE 8 fieldElementsPerCell,
    LeanEthKzg.natToFixedWidthBE 8 input.uniqueCommitments.size,
    LeanEthKzg.natToFixedWidthBE 8 input.cellIndices.size
  ]

def cellBatchTranscriptEntryMessages (input : NormalizedCellBatchInput) : Array Bytes :=
  Id.run do
    let mut acc : Array Bytes := #[]
    for i in [0:input.cellIndices.size] do
      acc := acc.push (LeanEthKzg.natToFixedWidthBE 8 input.commitmentIndices[i]!.toNat)
      acc := acc.push (LeanEthKzg.natToFixedWidthBE 8 input.cellIndices[i]!.toNat)
      acc := acc.push input.cells[i]!
      acc := acc.push input.proofs[i]!
    return acc

def cellBatchTranscriptMessages (input : NormalizedCellBatchInput) : Array Bytes :=
  cellBatchTranscriptHeader input ++
    (input.uniqueCommitments ++ cellBatchTranscriptEntryMessages input)

def cellBatchTranscript (input : NormalizedCellBatchInput) : TranscriptInput :=
  transcript cellBatchChallengeDomain (cellBatchTranscriptMessages input)

theorem uniqueCommitment_mem_cellBatchTranscriptMessages
    (input : NormalizedCellBatchInput)
    {commitment : CommitmentBytes}
    (h : commitment ∈ input.uniqueCommitments) :
    commitment ∈ cellBatchTranscriptMessages input := by
  unfold cellBatchTranscriptMessages
  simp [h]

theorem uniqueCommitment_mem_cellBatchTranscript
    (input : NormalizedCellBatchInput)
    {commitment : CommitmentBytes}
    (h : commitment ∈ input.uniqueCommitments) :
    commitment ∈ (cellBatchTranscript input).messages := by
  simpa [cellBatchTranscript] using uniqueCommitment_mem_cellBatchTranscriptMessages input h

theorem getElem?_cellBatchTranscriptMessages_uniqueCommitment
    (input : NormalizedCellBatchInput)
    {i : Nat}
    (h : i < input.uniqueCommitments.size) :
    (cellBatchTranscriptMessages input)[(cellBatchTranscriptHeader input).size + i]? =
      some input.uniqueCommitments[i] := by
  unfold cellBatchTranscriptMessages
  have hOuter : (cellBatchTranscriptHeader input).size <= (cellBatchTranscriptHeader input).size + i :=
    Nat.le_add_right _ _
  rw [Array.getElem?_append_right hOuter]
  have hInner :
      (input.uniqueCommitments ++ cellBatchTranscriptEntryMessages input)[i]? =
        some input.uniqueCommitments[i] := by
    rw [Array.getElem?_append_left h]
    exact Array.getElem?_eq_getElem h
  simpa [Nat.add_sub_cancel_left] using hInner

theorem getElem?_cellBatchTranscript_uniqueCommitment
    (input : NormalizedCellBatchInput)
    {i : Nat}
    (h : i < input.uniqueCommitments.size) :
    (cellBatchTranscript input).messages[(cellBatchTranscriptHeader input).size + i]? =
      some input.uniqueCommitments[i] := by
  simpa [cellBatchTranscript] using
    getElem?_cellBatchTranscriptMessages_uniqueCommitment input h

end LeanEthKzg.Spec
