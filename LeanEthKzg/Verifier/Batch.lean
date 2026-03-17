import LeanEthKzg.Verifier.API

namespace LeanEthKzg.Verifier

open LeanEthKzg.Spec

inductive BatchPath where
  | naive
  | fast
  deriving Repr, BEq, DecidableEq, Inhabited

def selectCellBatchPath (input : NormalizedCellBatchInput) : BatchPath :=
  if input.cells.size < 8 then .naive else .fast

theorem selectCellBatchPath_small (input : NormalizedCellBatchInput) (h : input.cells.size < 8) :
    selectCellBatchPath input = .naive := by
  simp [selectCellBatchPath, h]

theorem selectCellBatchPath_large (input : NormalizedCellBatchInput) (h : 8 <= input.cells.size) :
    selectCellBatchPath input = .fast := by
  have hNot : ¬ input.cells.size < 8 := Nat.not_lt.mpr h
  simp [selectCellBatchPath, hNot]

end LeanEthKzg.Verifier
