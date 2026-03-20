#!/usr/bin/env python3

import argparse
import json
from pathlib import Path


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def build_fixture_state(case: dict) -> tuple[str, bool]:
    status = case["status"]
    strategy = case.get("input", {}).get("fixture_strategy")

    if status != "active":
        return ("draft", False)
    if strategy == "external_regression_fixture":
        return ("pending_external_fixture", False)
    return ("inline_or_manifest_only", True)


def build_plan(index_path: Path, tags_path: Path) -> dict:
    index = load_json(index_path)
    tags = load_json(tags_path)

    case_root = index_path.parent
    jobs = []
    case_summaries = []

    for case_ref in index["cases"]:
        case_path = case_root / case_ref["path"]
        case = load_json(case_path)
        if case["id"] != case_ref["id"]:
            raise ValueError(f"case id mismatch for {case_path.as_posix()}")
        if case["status"] != case_ref["status"]:
            raise ValueError(f"case status mismatch for {case['id']}")
        fixture_state, runnable = build_fixture_state(case)
        tag_matrix = case["tag_matrix"]

        for tag_info in tags["tags"]:
            tag = tag_info["tag"]
            if tag not in tag_matrix:
                raise ValueError(f"missing tag_matrix entry for {case['id']} -> {tag}")
            expected = tag_matrix[tag]
            jobs.append(
                {
                    "case_id": case["id"],
                    "tag": tag,
                    "api": case["api"],
                    "family": case["family"],
                    "status": case["status"],
                    "runnable": runnable,
                    "fixture_state": fixture_state,
                    "expected_replay": expected["expected_replay"],
                    "expected_decision": case["expected"]["decision"],
                    "expected_normalization": case["expected"]["normalization"]["result"],
                    "reason": expected["reason"],
                    "tag_commit": tag_info["commit"],
                    "tag_references": tag_info["references"],
                    "case_path": str(case_path.as_posix()),
                }
            )

        case_summaries.append(
            {
                "id": case["id"],
                "api": case["api"],
                "status": case["status"],
                "runnable": runnable,
                "fixture_state": fixture_state,
                "tag_count": len(tag_matrix),
                "case_path": str(case_path.as_posix()),
            }
        )

    return {
        "schema_version": 1,
        "source_index": str(index_path.as_posix()),
        "source_tags": str(tags_path.as_posix()),
        "summary": {
            "case_count": len(case_summaries),
            "runnable_case_count": sum(1 for case in case_summaries if case["runnable"]),
            "job_count": len(jobs),
            "runnable_job_count": sum(1 for job in jobs if job["runnable"]),
        },
        "cases": case_summaries,
        "jobs": jobs,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Expand adversarial corpus cases across pinned c-kzg-4844 tags."
    )
    parser.add_argument(
        "--index",
        default="corpus/adversarial/index.json",
        help="Path to the adversarial corpus index.",
    )
    parser.add_argument(
        "--tags",
        default="vendor/c-kzg-4844-tags.json",
        help="Path to pinned c-kzg-4844 tag metadata.",
    )
    parser.add_argument(
        "--output",
        default="artifacts/adversarial-replay-plan.json",
        help="Path to write the expanded replay plan.",
    )
    args = parser.parse_args()

    index_path = Path(args.index)
    tags_path = Path(args.tags)
    output_path = Path(args.output)

    plan = build_plan(index_path=index_path, tags_path=tags_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(plan, handle, indent=2)
        handle.write("\n")

    print(
        f"wrote {output_path.as_posix()} with "
        f"{plan['summary']['job_count']} jobs "
        f"({plan['summary']['runnable_job_count']} runnable)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
