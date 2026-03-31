# Adversarial corpus

Regression cases live here as plain, replayable artifacts.

The goal is to encode small witnesses that:

- distinguish fixed and historical bad `c-kzg-4844` tags,
- exercise Fulu-specific `verify_cell_kzg_proof_batch` behavior,
- stay usable outside Lean.

## Layout

- `index.json`: manifest of replayable adversarial cases.
- `case.schema.json`: schema for each per-case JSON artifact.
- `cases/*.json`: concrete witnesses and per-tag expectations.

The first cases can be intentionally small malformed-input witnesses. They exercise the public
normalization contract without requiring large blobs or fully cryptographic test vectors.

Historical bug cases may begin as `draft` entries when the upstream release or pull request provenance is
already known but the exact replayable bytes have not been vendored yet.

Concrete upstream-imported cases should record the exact consensus-spec-tests tag and fixture path
they came from so the FFI layer can replay the same bytes against pinned `c-kzg-4844` tags.

Imported cases that preserve the input pattern of a bug family, but do not actually fail on an
older tag, should be described as coverage cases rather than confirmed historical regressions.
