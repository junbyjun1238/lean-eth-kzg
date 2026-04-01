namespace LeanEthKzg.Verifier

/--
`CryptoBoundary` is the home for the explicit interface between Lean-side
byte-level verifier semantics and external cryptographic backends.

The initial commit only introduces the module so later commits can move the
backend contract here in small steps.
-/
def cryptoBoundaryModuleReady : Prop := True

end LeanEthKzg.Verifier
