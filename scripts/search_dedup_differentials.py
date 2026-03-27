#!/usr/bin/env python3

import argparse
import copy
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

import yaml

from run_replay_plan import (
    DEFAULT_CHECKOUT_ROOT,
    DEFAULT_TRUSTED_SETUP_RELPATH,
    build_checkout,
    dump_json,
    resolve_checkout_path,
    resolve_workspace_path,
    run_case,
)


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_FIXTURES_ROOT = (
    REPO_ROOT
    / ".tmp"
    / "consensus-spec-tests-v1.6.0-beta.0"
    / "tests"
    / "general"
    / "fulu"
    / "kzg"
    / "verify_cell_kzg_proof_batch"
    / "kzg-mainnet"
)
DEFAULT_OUTPUT = REPO_ROOT / "artifacts" / "dedup-search-report.json"
DEFAULT_CANDIDATE_DIR = REPO_ROOT / "artifacts" / "dedup-search-candidates"
DEFAULT_BASELINE_TAG = "v2.1.4"
DEFAULT_FIXED_TAG = "v2.1.5"
DEFAULT_MUTATION_FAMILIES = [
    "replace_full_entry",
    "replace_commitment_only",
    "replace_cell_only",
    "replace_proof_only",
    "replace_commitment_and_proof",
]


def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def stable_unique(values: list[str]) -> list[str]:
    unique: list[str] = []
    for value in values:
        if value not in unique:
            unique.append(value)
    return unique


def build_entries(test: dict) -> list[dict]:
    input_data = test["input"]
    return [
        {
            "commitment": input_data["commitments"][index],
            "cell_index": input_data["cell_indices"][index],
            "cell": input_data["cells"][index],
            "proof": input_data["proofs"][index],
        }
        for index in range(len(input_data["commitments"]))
    ]


def build_case_input(entries: list[dict]) -> dict:
    return {
        "api": "verify_cell_kzg_proof_batch",
        "input": {
            "commitments": [entry["commitment"] for entry in entries],
            "cell_indices": [entry["cell_index"] for entry in entries],
            "cells": [entry["cell"] for entry in entries],
            "proofs": [entry["proof"] for entry in entries],
        },
    }


def load_valid_fixture_cases(fixtures_root: Path) -> list[dict]:
    cases = []
    for path in sorted(fixtures_root.glob("*/data.yaml")):
        test = load_yaml(path)
        if test.get("output") is not True:
            continue
        entries = build_entries(test)
        unique_commitments = stable_unique([entry["commitment"] for entry in entries])
        tail_start = len(unique_commitments)
        bug_shape = [entry["commitment"] for entry in entries[:tail_start]] != unique_commitments
        cases.append(
            {
                "name": path.parent.name,
                "path": path.as_posix(),
                "entries": entries,
                "entry_count": len(entries),
                "unique_commitment_count": len(unique_commitments),
                "tail_positions": list(range(tail_start, len(entries))),
                "bug_shape": bug_shape,
            }
        )
    return cases


def collect_donor_entries(valid_cases: list[dict]) -> list[dict]:
    donors = []
    seen = set()
    for case in valid_cases:
        for index, entry in enumerate(case["entries"]):
            signature = (
                entry["commitment"],
                entry["cell_index"],
                entry["cell"],
                entry["proof"],
            )
            if signature in seen:
                continue
            seen.add(signature)
            donors.append(
                {
                    "source_case": case["name"],
                    "source_index": index,
                    **entry,
                }
            )
    return donors


def mutate_entries(
    seed_entries: list[dict],
    target_index: int,
    donor: dict,
    family: str,
) -> list[dict]:
    mutated = copy.deepcopy(seed_entries)
    target = mutated[target_index]

    if family == "replace_full_entry":
        mutated[target_index] = {
            "commitment": donor["commitment"],
            "cell_index": donor["cell_index"],
            "cell": donor["cell"],
            "proof": donor["proof"],
        }
    elif family == "replace_commitment_only":
        target["commitment"] = donor["commitment"]
    elif family == "replace_cell_only":
        target["cell_index"] = donor["cell_index"]
        target["cell"] = donor["cell"]
    elif family == "replace_proof_only":
        target["proof"] = donor["proof"]
    elif family == "replace_commitment_and_proof":
        target["commitment"] = donor["commitment"]
        target["proof"] = donor["proof"]
    else:
        raise ValueError(f"unsupported mutation family: {family}")

    return mutated


def entries_signature(entries: list[dict]) -> tuple:
    return tuple(
        (entry["commitment"], entry["cell_index"], entry["cell"], entry["proof"])
        for entry in entries
    )


def observe_candidate(
    temp_case_path: Path,
    script_path: Path,
    python_executable: str,
    tag_state: dict,
) -> dict:
    return run_case(
        script_path=script_path,
        python_executable=python_executable,
        checkout_path=Path(tag_state["checkout_path"]),
        case_path=temp_case_path,
        trusted_setup_path=Path(tag_state["trusted_setup_path"]),
    )


def build_tag_state(
    tag: str,
    checkout_root: Path,
    trusted_setup_relpath: Path,
    python_executable: str,
    force_rebuild: bool,
    dry_run: bool,
) -> dict:
    return build_checkout(
        checkout_path=resolve_checkout_path(checkout_root, tag),
        trusted_setup_relpath=trusted_setup_relpath,
        python_executable=python_executable,
        dry_run=dry_run,
        force_rebuild=force_rebuild,
    )


def differential_kind(baseline_observed: dict, fixed_observed: dict) -> str:
    baseline_outcome = baseline_observed.get("outcome")
    fixed_outcome = fixed_observed.get("outcome")
    if baseline_outcome == "accept" and fixed_outcome == "reject":
        return "baseline_accept_fixed_reject"
    if baseline_outcome == "accept" and fixed_outcome == "exception":
        return "baseline_accept_fixed_exception"
    if baseline_outcome == "reject" and fixed_outcome == "accept":
        return "baseline_reject_fixed_accept"
    if baseline_outcome == "exception" and fixed_outcome == "accept":
        return "baseline_exception_fixed_accept"
    return "other"


def build_report(args: argparse.Namespace) -> dict:
    fixtures_root = resolve_workspace_path(args.fixtures_root)
    output_path = resolve_workspace_path(args.output)
    candidate_dir = resolve_workspace_path(args.candidate_dir)
    checkout_root = resolve_workspace_path(args.checkout_root)
    trusted_setup_relpath = Path(args.trusted_setup_relpath)
    script_path = (REPO_ROOT / "scripts" / "run_replay_plan.py").resolve()

    valid_cases = load_valid_fixture_cases(fixtures_root)
    seed_cases = [case for case in valid_cases if case["bug_shape"]]
    donor_entries = collect_donor_entries(valid_cases)
    mutation_families = args.mutation_family or DEFAULT_MUTATION_FAMILIES

    baseline_state = build_tag_state(
        tag=args.baseline_tag,
        checkout_root=checkout_root,
        trusted_setup_relpath=trusted_setup_relpath,
        python_executable=args.python_executable,
        force_rebuild=args.force_rebuild,
        dry_run=args.dry_run,
    )
    fixed_state = build_tag_state(
        tag=args.fixed_tag,
        checkout_root=checkout_root,
        trusted_setup_relpath=trusted_setup_relpath,
        python_executable=args.python_executable,
        force_rebuild=args.force_rebuild,
        dry_run=args.dry_run,
    )

    candidate_dir.mkdir(parents=True, exist_ok=True)
    seen_signatures = set()
    processed_count = 0
    executed_count = 0
    skipped_count = 0
    differential_count = 0
    desired_differential_count = 0
    differentials = []

    with tempfile.TemporaryDirectory() as temp_dir_text:
        temp_case_path = Path(temp_dir_text) / "candidate.json"

        for seed_case in seed_cases:
            seed_signature = entries_signature(seed_case["entries"])
            for target_index in seed_case["tail_positions"]:
                for family in mutation_families:
                    for donor in donor_entries[: args.max_donors]:
                        mutated_entries = mutate_entries(
                            seed_entries=seed_case["entries"],
                            target_index=target_index,
                            donor=donor,
                            family=family,
                        )
                        signature = entries_signature(mutated_entries)
                        if signature == seed_signature or signature in seen_signatures:
                            skipped_count += 1
                            continue
                        seen_signatures.add(signature)
                        processed_count += 1

                        candidate_case = build_case_input(mutated_entries)
                        dump_json(temp_case_path, candidate_case)

                        candidate_id = (
                            f"{seed_case['name']}__{family}__tail{target_index}"
                            f"__{donor['source_case']}__entry{donor['source_index']}"
                        )

                        if (
                            args.dry_run
                            or baseline_state["status"] != "ready"
                            or fixed_state["status"] != "ready"
                        ):
                            if processed_count >= args.max_candidates:
                                break
                            continue

                        baseline_observed = observe_candidate(
                            temp_case_path=temp_case_path,
                            script_path=script_path,
                            python_executable=args.python_executable,
                            tag_state=baseline_state,
                        )
                        fixed_observed = observe_candidate(
                            temp_case_path=temp_case_path,
                            script_path=script_path,
                            python_executable=args.python_executable,
                            tag_state=fixed_state,
                        )
                        executed_count += 1

                        if baseline_observed != fixed_observed:
                            kind = differential_kind(
                                baseline_observed=baseline_observed,
                                fixed_observed=fixed_observed,
                            )
                            differential_count += 1
                            if kind == "baseline_accept_fixed_reject":
                                desired_differential_count += 1

                            candidate_output_path = candidate_dir / f"{candidate_id}.json"
                            dump_json(
                                candidate_output_path,
                                {
                                    "schema_version": 1,
                                    "candidate_id": candidate_id,
                                    "seed_case": seed_case["name"],
                                    "seed_fixture_path": seed_case["path"],
                                    "mutation_family": family,
                                    "target_tail_index": target_index,
                                    "donor_source_case": donor["source_case"],
                                    "donor_source_index": donor["source_index"],
                                    "baseline_tag": args.baseline_tag,
                                    "fixed_tag": args.fixed_tag,
                                    "baseline_observed": baseline_observed,
                                    "fixed_observed": fixed_observed,
                                    "differential_kind": kind,
                                    "case": candidate_case,
                                },
                            )
                            differentials.append(
                                {
                                    "candidate_id": candidate_id,
                                    "seed_case": seed_case["name"],
                                    "mutation_family": family,
                                    "target_tail_index": target_index,
                                    "donor_source_case": donor["source_case"],
                                    "donor_source_index": donor["source_index"],
                                    "baseline_observed": baseline_observed,
                                    "fixed_observed": fixed_observed,
                                    "differential_kind": kind,
                                    "candidate_path": candidate_output_path.as_posix(),
                                }
                            )

                            if len(differentials) >= args.max_differentials:
                                break

                        if processed_count >= args.max_candidates:
                            break
                    if len(differentials) >= args.max_differentials or processed_count >= args.max_candidates:
                        break
                if len(differentials) >= args.max_differentials or processed_count >= args.max_candidates:
                    break
            if len(differentials) >= args.max_differentials or processed_count >= args.max_candidates:
                break

    report = {
        "schema_version": 1,
        "generated_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "baseline_tag": args.baseline_tag,
        "fixed_tag": args.fixed_tag,
        "fixtures_root": fixtures_root.as_posix(),
        "candidate_dir": candidate_dir.as_posix(),
        "seed_cases": [
            {
                "name": case["name"],
                "path": case["path"],
                "entry_count": case["entry_count"],
                "unique_commitment_count": case["unique_commitment_count"],
                "tail_positions": case["tail_positions"],
            }
            for case in seed_cases
        ],
        "mutation_families": mutation_families,
        "build_states": {
            args.baseline_tag: baseline_state,
            args.fixed_tag: fixed_state,
        },
        "summary": {
            "seed_case_count": len(seed_cases),
            "donor_entry_count": len(donor_entries),
            "max_donors_considered": min(args.max_donors, len(donor_entries)),
            "candidate_count": len(seen_signatures),
            "processed_count": processed_count,
            "executed_count": executed_count,
            "skipped_count": skipped_count,
            "differential_count": differential_count,
            "desired_differential_count": desired_differential_count,
        },
        "differentials": differentials,
        "notes": [
            "This search currently focuses on seeds where the buggy v2.1.4 challenge ignores one or more tail commitments.",
            "A desired witness is baseline accept / fixed reject, because that would turn the weak binding bug into a replayable verifier differential.",
        ],
    }
    dump_json(output_path, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Search for verify_cell_kzg_proof_batch witnesses that differ between v2.1.4 and v2.1.5."
    )
    parser.add_argument(
        "--fixtures-root",
        default=str(DEFAULT_FIXTURES_ROOT.relative_to(REPO_ROOT)),
        help="Path to consensus-spec-tests verify_cell_kzg_proof_batch fixtures.",
    )
    parser.add_argument(
        "--output",
        default=str(DEFAULT_OUTPUT.relative_to(REPO_ROOT)),
        help="Path to write the search report JSON.",
    )
    parser.add_argument(
        "--candidate-dir",
        default=str(DEFAULT_CANDIDATE_DIR.relative_to(REPO_ROOT)),
        help="Directory to write differential candidate cases.",
    )
    parser.add_argument(
        "--checkout-root",
        default=str(DEFAULT_CHECKOUT_ROOT.relative_to(REPO_ROOT)),
        help="Directory that contains c-kzg-4844-<tag> checkouts.",
    )
    parser.add_argument(
        "--trusted-setup-relpath",
        default=str(DEFAULT_TRUSTED_SETUP_RELPATH.as_posix()),
        help="Trusted setup path relative to each c-kzg-4844 checkout.",
    )
    parser.add_argument(
        "--python-executable",
        default=sys.executable,
        help="Python executable to use for builds and per-case invocation.",
    )
    parser.add_argument(
        "--baseline-tag",
        default=DEFAULT_BASELINE_TAG,
        help="Historical tag expected to contain the bug.",
    )
    parser.add_argument(
        "--fixed-tag",
        default=DEFAULT_FIXED_TAG,
        help="Fixed tag to compare against.",
    )
    parser.add_argument(
        "--mutation-family",
        action="append",
        help="Optional mutation family filter. May be passed multiple times.",
    )
    parser.add_argument(
        "--max-donors",
        type=int,
        default=256,
        help="Maximum number of donor entries to consider.",
    )
    parser.add_argument(
        "--max-candidates",
        type=int,
        default=2048,
        help="Maximum number of candidate mutations to evaluate.",
    )
    parser.add_argument(
        "--max-differentials",
        type=int,
        default=32,
        help="Stop after this many differentials have been written.",
    )
    parser.add_argument(
        "--force-rebuild",
        action="store_true",
        help="Rebuild ckzg extensions even if artifacts already exist.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not execute candidates; report seed, donor, and build-state information only.",
    )
    args = parser.parse_args()

    report = build_report(args)
    print(
        f"wrote {resolve_workspace_path(args.output).as_posix()} with "
        f"{report['summary']['processed_count']} processed candidates "
        f"({report['summary']['executed_count']} executed) and "
        f"{report['summary']['differential_count']} differentials"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
