# lean-eth-kzg

Lean-centered verification and regression tooling for the verifier-facing KZG boundary used by Ethereum Deneb/Fulu.

This repository is organized around the milestones in [plan.md](./plan.md):

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
- a backend interface that cleanly separates byte-level semantics from cryptographic checks.

## Immediate next steps

1. Add the first adversarial witness values under `corpus/adversarial`.
2. Implement a vector-normalization script for official releases.
3. Build the first FFI replay harness against pinned `c-kzg-4844` tags.

