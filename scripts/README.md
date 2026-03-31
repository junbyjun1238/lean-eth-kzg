# Scripts

Small adapters and reproducible generators belong here.

Typical contents:

- vector normalization from upstream YAML or release assets,
- corpus manifest generation,
- replay orchestration for pinned implementation tags.

Current scripts:

- `build_replay_matrix.py`: expands adversarial cases and pinned tag metadata into a deterministic
  replay plan for the FFI runner.
- `fetch_c_kzg_tags.py`: materializes pinned `c-kzg-4844` tag checkouts under `.tmp/`, including
  required submodules, for replay runs and CI jobs.
- `run_replay_plan.py`: resolves pinned `c-kzg-4844` checkouts, builds the Python binding when
  possible, writes a replay report that records pass/fail/skip outcomes per case and tag, and can
  fail CI in `--strict` mode if any replay job does not land in `status=pass`.
- `search_dedup_differentials.py`: expands the duplicate-commitment Fulu search space with
  derived seed cases, additional mutation families, and transcript-shape summaries while searching for
  `v2.1.4` vs `v2.1.5` verifier differentials.
