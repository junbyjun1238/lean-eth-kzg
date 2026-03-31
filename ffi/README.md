# FFI

This directory is reserved for public-boundary harnesses that call pinned `c-kzg-4844` builds.

The harness layer exists to compare Lean-side semantics with implementation behavior without turning this repository into a full C verification effort.

Current behavior:

- consume `artifacts/adversarial-replay-plan.json`,
- resolve pinned checkouts for each tag,
- run only entries marked `runnable: true`,
- report observed outcomes back in the same case and tag coordinates.

The current repository implementation of this behavior lives in
`scripts/run_replay_plan.py`, which expects checkouts under `.tmp/c-kzg-4844-<tag>` by default
and uses the official Python binding surface from each checkout.
