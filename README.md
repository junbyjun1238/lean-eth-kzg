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
- an initial adversarial case-manifest schema, a first malformed batch witness, one concrete
  historical bad-tag witness, and one upstream-imported duplicate-commitment coverage case,
- a script-generated replay plan that expands adversarial cases across pinned `c-kzg-4844` tags,
- a replay runner that resolves pinned `c-kzg-4844` checkouts and emits per-tag replay reports,
- a GitHub Actions workflow that fetches pinned tags and runs the replay matrix on Linux.

The main remaining gap is confirmation: this repository now has the replay-plan, checkout-fetch,
runner, and CI wiring layers, but still needs a stronger deduplicated-commitment witness after
the first Linux report on 2026-03-22 showed that the imported `not_sorted` fixture still passes
on `c-kzg-4844 v2.1.4`.

## Immediate next steps

1. Synthesize or import a stronger deduplicated-commitment witness that actually fails on `c-kzg-4844 v2.1.4`.
2. Implement a vector-normalization script for pinned official releases.
3. Add compact bad-tag summaries for CI and README consumption.
