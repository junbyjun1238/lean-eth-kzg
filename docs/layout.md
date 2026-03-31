# Layout

## Lean modules

- `LeanEthKzg/Spec`: byte-oriented input and domain models for Deneb/Fulu verifier APIs.
- `LeanEthKzg/Verifier`: normalization and verifier-path semantics.
- `LeanEthKzg/Regression`: named bug classes, invariants, and witness families.
- `LeanEthKzg/Conformance`: pinned external implementation targets and replay expectations.

## External artifacts

- `corpus/official`: immutable manifests for archived or pinned upstream vectors.
- `corpus/adversarial`: JSON and hex test cases used to replay known regressions against older tags.
- `scripts`: small adapters that turn upstream vectors into normalized local artifacts.
- `ffi`: boundary harnesses that call public `c-kzg-4844` APIs without modeling C internals.
- `artifacts`: generated reports, replay summaries, and CI outputs.
- `vendor`: fetch manifests, checksums, and notes for pinned upstream inputs.

## Design rule

Work that would require modeling C internals stays outside the Lean core and, if needed, lives
behind a boundary harness. The Lean side stays focused on verifier semantics and
regression-relevant invariants.

## Boundary note

The repository's central design choice is to formalize the Ethereum verifier boundary before
attempting a full KZG mathematics development. The Lean modules model public-byte semantics and
transcript normal forms, while cryptographic decode and pairing validity remain outside the Lean
core behind an explicit backend boundary. See `docs/crypto-boundary.md` for the full rationale.
