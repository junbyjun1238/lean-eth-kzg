# FFI

This directory is reserved for public-boundary harnesses that call pinned `c-kzg-4844` builds.

The harness layer exists to compare Lean-side semantics with implementation behavior without turning this repository into a full C verification effort.

The immediate contract for this layer is:

- consume `artifacts/adversarial-replay-plan.json`,
- run only entries marked `runnable: true`,
- report observed outcomes back in the same case and tag coordinates.
