# Cryptographic Boundary

This repository does not try to prove the full mathematics of KZG inside Lean.
It instead formalizes the verifier-facing boundary that Ethereum Deneb and Fulu
actually expose to clients and external libraries.

That means the project answers:

- what raw bytes are accepted or rejected,
- how batch inputs are normalized,
- how duplicate commitments are deduplicated,
- how transcript messages are assembled,
- when singleton and batch APIs must agree.

It does not yet answer:

- whether a compressed commitment decodes to a valid curve point,
- whether a proof is in the correct subgroup,
- whether a field element encoding is canonical,
- whether the final pairing check is cryptographically sound.

## Two formalization targets

There are two distinct goals people often conflate.

### 1. Full KZG formalization

This path formalizes the full cryptographic system:

- finite fields,
- elliptic curves,
- pairings,
- polynomial commitments,
- Fiat-Shamir security arguments,
- and the final verifier theorem.

That path is meaningful, but it is much heavier than the current project.

### 2. Ethereum verifier-boundary formalization

This path formalizes the public verifier interface:

- model the public API entry points,
- fix exact byte lengths and vector shapes,
- define normalization outcomes,
- define transcript normal forms,
- and leave the final cryptographic predicate behind an explicit backend boundary.

This repository is intentionally on the second path.

## Current Lean responsibilities

Lean currently defines the public-input and transcript boundary:

- exact byte lengths for commitments, proofs, field elements, blobs, and cells,
- vector-shape agreement for batch APIs,
- cell-index bounds,
- stable dedup for Fulu cell-batch commitments,
- commitment-index normalization for deduplicated batches,
- transcript message layout for Deneb and Fulu verifier APIs,
- singleton/batch consistency and invalid-input determinism theorems.

In code, that work mostly lives in:

- `LeanEthKzg/Spec/Deneb.lean`
- `LeanEthKzg/Spec/Fulu.lean`
- `LeanEthKzg/Verifier/API.lean`
- `LeanEthKzg/Verifier/Determinism.lean`
- `LeanEthKzg/Verifier/NormalForm.lean`

## Current backend responsibilities

The external cryptographic backend is still responsible for the parts that depend on
real curve and field decoding:

- commitment decoding validity,
- proof decoding validity,
- field-element canonicality,
- point-at-infinity rejection,
- subgroup checks,
- the final cryptographic verification predicate.

In Lean, that boundary is represented by `LeanEthKzg.Verifier.Backend`.
The current backend interface is intentionally small: Lean computes normalized
inputs and transcript-facing metadata, and the backend returns the cryptographic
accept or reject decision.

## Why this split is useful

Most real verifier regressions in Ethereum do not come from reproving pairing
theory incorrectly inside a client. They come from boundary mistakes:

- malformed bytes not being rejected consistently,
- batch and singleton paths disagreeing,
- transcripts omitting or reordering public inputs,
- deduplication changing the challenge shape,
- edge cases being handled differently across fast paths.

Formalizing the boundary in Lean is therefore useful even before the full KZG
mathematics is formalized. It gives the repository a precise public contract
that can be checked against pinned `c-kzg-4844` tags and historical bug cases.

## Current trust model

The current trust model is:

1. Lean defines the public verifier semantics up to a normalized cryptographic query.
2. An external backend decides whether that normalized query is cryptographically valid.
3. Replay harnesses compare real `c-kzg-4844` releases against those Lean-facing expectations.

This is not an end-to-end formal proof of KZG.
It is a verifier-boundary specification plus replayable regression tooling.

## Planned next step

The next refinement is to make the cryptographic boundary more explicit in code
by introducing named predicates or interfaces for items such as:

- commitment decode success,
- proof decode success,
- field canonicality,
- subgroup and infinity restrictions.

That would still stop short of full pairing formalization, but it would make the
Trusted Computing Base more explicit and visible inside Lean.
