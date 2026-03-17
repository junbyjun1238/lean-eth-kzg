# Scope

This repository targets the verifier-facing KZG boundary for Ethereum Deneb and Fulu.

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

## Explicit non-goals

- full C memory or pointer verification,
- a full cryptographic security proof for KZG or Fiat-Shamir,
- a generic SNARK framework or polynomial library,
- reimplementing a pairing backend from scratch.
