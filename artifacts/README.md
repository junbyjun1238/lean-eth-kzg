# Artifacts

Generated outputs belong here, for example:

- conformance replay reports,
- bad-tag failure summaries,
- normalized corpus snapshots produced by CI.

The first stable artifact format should include, at minimum:

- target API,
- raw input bytes or references,
- normalization outcome,
- transcript payload bytes or digest,
- bug-class label,
- per-tag expected outcome for pinned `c-kzg-4844` releases.

Tracked bootstrap artifacts:

- `adversarial-replay-plan.json`: deterministic expansion of adversarial cases across pinned tags.

The next generated artifact is:

- `adversarial-replay-report.json`: observed pass/fail/skip outcomes keyed by the same case and
  tag coordinates, plus checkout/build readiness details.
- `dedup-search-report.json`: differential-search summary for candidate `verify_cell_kzg_proof_batch`
  witnesses across `v2.1.4` and `v2.1.5`, including seed provenance, shape diagnostics, and
  per-mutation-family counters.
- `dedup-search-candidates/`: concrete candidate cases that exhibited differing behavior.
