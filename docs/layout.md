# Layout

## Lean modules

- `LeanEthKzg/Spec`: byte-oriented input and domain models for Deneb/Fulu verifier APIs.
- `LeanEthKzg/Verifier`: normalization and verifier-path semantics.
- `LeanEthKzg/Regression`: named bug classes, invariants, and witness families.
- `LeanEthKzg/Conformance`: pinned external implementation targets and replay expectations.

## External artifacts

- `corpus/official`: immutable manifests for archived or pinned upstream vectors.
- `corpus/adversarial`: Lean-guided JSON/hex corpora designed to kill historical bad tags.
- `scripts`: small adapters that turn upstream vectors into normalized local artifacts.
- `ffi`: boundary harnesses that call public `c-kzg-4844` APIs without modeling C internals.
- `artifacts`: generated reports, replay summaries, and CI outputs.
- `vendor`: fetch manifests, checksums, and notes for pinned upstream inputs.

## Design rule

Anything that smells like "prove the C internals" stays out of the Lean core and lives, if at all, behind a boundary harness. The Lean side should stay focused on verifier semantics and regression-relevant invariants.

