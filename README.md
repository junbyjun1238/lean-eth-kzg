# lean-eth-kzg

Lean-centered specifications and regression tooling for the verifier-facing KZG boundary used by Ethereum Deneb/Fulu.

At present, Lean defines byte-level semantics, normalization, and transcript invariants.
Replay tooling and test artifacts are built around those definitions.

- Lean models raw-byte API semantics, normalization, and verifier invariants.
- External harnesses compare those semantics against pinned `c-kzg-4844` tags.
- Official vectors and adversarial test cases are stored as replayable artifacts.

For a detailed explanation of the cryptographic boundary used in this repository, see
[`docs/crypto-boundary.md`](docs/crypto-boundary.md).

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

Current division of responsibility:

- Lean owns the verifier-facing byte boundary and transcript normal form.
- External cryptographic backends still own decode validity, subgroup checks, infinity checks,
  field-element canonicality, and the final pairing-based predicate.

The main remaining gaps are:

- tightening the external cryptographic boundary into a more explicit Lean-side interface, and
- continuing replay and corpus work where concrete historical witnesses are available.

## Immediate next steps

1. Turn the documented cryptographic boundary into explicit Lean-side predicates or interfaces.
2. Implement a vector-normalization script for pinned official releases.
3. Continue replay and corpus work for bug classes with concrete historical witnesses.
