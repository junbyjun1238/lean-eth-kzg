# Scripts

Small adapters and reproducible generators belong here.

Expected near-term scripts:

- vector normalization from upstream YAML or release assets,
- corpus manifest generation,
- replay orchestration for pinned implementation tags.

Current scripts:

- `build_replay_matrix.py`: expands adversarial cases and pinned tag metadata into a deterministic
  replay plan for the future FFI runner.
