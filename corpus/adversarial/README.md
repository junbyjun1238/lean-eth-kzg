# Adversarial corpus

Theorem-guided regression cases live here as plain, replayable artifacts.

The goal is to encode small witnesses that:

- distinguish fixed and historical bad `c-kzg-4844` tags,
- exercise Fulu-specific `verify_cell_kzg_proof_batch` behavior,
- stay usable outside Lean.

