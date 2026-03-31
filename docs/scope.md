# Scope

This repository targets the verifier-facing KZG boundary for Ethereum Deneb and Fulu.
See also `docs/crypto-boundary.md` for the design rationale behind that boundary.

## In scope

- raw-byte API semantics for verifier entry points,
- exact public-input length checks for blobs, commitments, proofs, field elements, and cells,
- normalization and transcript-facing invariants,
- regression witnesses for the 2025 `verify_cell_kzg_proof_batch` bug classes,
- replayable conformance checks against pinned `c-kzg-4844` tags,
- official-vector ingestion through normalized external adapters.

## Current byte-level constants

- commitment bytes: `48`
- proof bytes: `48`
- field element bytes: `32`
- field elements per blob: `4096`
- bytes per blob: `131072`
- field elements per cell: `64`
- bytes per cell: `2048`
- cells per extended blob: `128`

## Trusted computing base

- trusted setup artifacts,
- external cryptographic backends used by `c-kzg-4844`,
- vector preprocessing scripts,
- C toolchain and FFI boundary used by replay harnesses.

## Invalid-input boundary

Lean currently decides:

- exact byte lengths for public inputs,
- vector-shape agreement across batch APIs,
- cell index bounds,
- transcript normal form for normalized inputs.

External backends currently decide:

- commitment and proof decoding validity,
- field-element canonicality,
- point-at-infinity and subgroup restrictions.

The repository treats those cryptographic decode predicates as an explicit boundary rather than
silently folding them into byte-level normalization.

## Boundary contract

The current project is divided as follows:

1. Lean maps raw public bytes into either a normalization error or a normalized verifier query.
2. Lean fixes the transcript shape and batch normal form for that normalized query.
3. An external backend decides the remaining cryptographic predicate on that normalized query.

This means the repository is not yet a full formal proof of KZG.
It is a formal specification of the Ethereum verifier boundary plus replayable regression tooling
around real `c-kzg-4844` releases.

## Next refinement

The next refinement is to make the current backend trust boundary more explicit in code, for
example by naming predicates or interfaces for:

- commitment decode success,
- proof decode success,
- field-element canonicality,
- subgroup and point-at-infinity restrictions.

## Explicit non-goals

- full C memory or pointer verification,
- a full cryptographic security proof for KZG or Fiat-Shamir,
- a generic SNARK framework or polynomial library,
- reimplementing a pairing backend from scratch.
