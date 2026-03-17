namespace LeanEthKzg.Conformance

inductive CKZGTag where
  | v2_1_2
  | v2_1_3
  | v2_1_4
  | v2_1_5
  deriving Repr, BEq, DecidableEq, Inhabited

inductive ExpectedOutcome where
  | pass
  | fail
  deriving Repr, BEq, DecidableEq, Inhabited

def CKZGTag.ref : CKZGTag → String
  | .v2_1_2 => "v2.1.2"
  | .v2_1_3 => "v2.1.3"
  | .v2_1_4 => "v2.1.4"
  | .v2_1_5 => "v2.1.5"

end LeanEthKzg.Conformance

