# lean-eth-kzg

Lean-centered specifications and regression tooling for the verifier-facing KZG boundary used by Ethereum Deneb/Fulu.

The repository is currently spec-first: Lean fixes byte-level semantics, normalization, and
transcript invariants first, while the replayable artifact layers are being filled in around
that core.

- Lean models raw-byte API semantics, normalization, and verifier invariants.
- External harnesses compare those semantics against pinned `c-kzg-4844` tags.
- Official vectors and Lean-guided adversarial corpora become replayable artifacts.

## Repository layout

- `LeanEthKzg/Spec`: byte-level input models, exact length checks, and normalization logic.
- `LeanEthKzg/Verifier`: backend-agnostic verifier semantics and batch-path selection.
- `LeanEthKzg/Regression`: bug classes, invariants, and witness families.
- `LeanEthKzg/Conformance`: pinned implementation targets and expected replay outcomes.
- `corpus/official`: pinned official vectors and manifests.
- `corpus/adversarial`: Lean-generated regression corpora.
- `scripts`: vector adapters and reproducible generators.
- `ffi`: public-boundary harnesses for `c-kzg-4844`.
- `artifacts`: generated reports and replay outputs.
- `vendor`: pinned upstream metadata and fetch policy.

## Current status

The repository now includes:

- a compilable Lean package,
- exact byte-length constants for Deneb/Fulu-facing public inputs,
- normalization functions for `verify_kzg_proof`, `verify_blob_kzg_proof`,
  `verify_blob_kzg_proof_batch`, and `verify_cell_kzg_proof_batch`,
- stable dedup and transcript construction for Fulu cell-batch inputs,
- a backend interface that cleanly separates byte-level semantics from cryptographic checks,
- normalization reports that carry API and transcript payload metadata for future case manifests
  and replay harnesses,
- an initial adversarial case-manifest schema, a first malformed batch witness, and a first
  concrete historical bad-tag witness imported from upstream consensus-spec-tests,
- a second historical bad-tag draft case tied to upstream release notes,
- a script-generated replay plan that expands adversarial cases across pinned `c-kzg-4844` tags.

The main remaining gap is artifactization: `ffi`, `scripts`, `vendor`, and corpus outputs still
need to grow into a tag-matrix replay pipeline that demonstrates historical bad-tag failures.

## Immediate next steps

1. Replace the remaining draft historical bad-tag case with concrete replayable bytes or a vendored fixture.
2. Implement a vector-normalization script for pinned official releases.
3. Teach the FFI runner to execute the generated replay plan against local `c-kzg-4844` checkouts.
