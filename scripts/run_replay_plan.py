#!/usr/bin/env python3

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PLAN = REPO_ROOT / "artifacts" / "adversarial-replay-plan.json"
DEFAULT_OUTPUT = REPO_ROOT / "artifacts" / "adversarial-replay-report.json"
DEFAULT_CHECKOUT_ROOT = REPO_ROOT / ".tmp"
DEFAULT_TRUSTED_SETUP_RELPATH = Path("src") / "trusted_setup.txt"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def dump_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def resolve_workspace_path(path_text: str | Path) -> Path:
    path = Path(path_text)
    if path.is_absolute():
        return path
    return REPO_ROOT / path


def hex_to_bytes(hex_text: str) -> bytes:
    if hex_text.startswith("0x"):
        hex_text = hex_text[2:]
    return bytes.fromhex(hex_text)


def truncate_text(text: str, limit: int = 1200) -> str:
    text = text.strip()
    if len(text) <= limit:
        return text
    return text[:limit] + "...<truncated>"


def locate_extension_artifact(checkout_path: Path) -> Path | None:
    for pattern in ["ckzg*.pyd", "ckzg*.so", "ckzg*.dll"]:
        matches = sorted(checkout_path.glob(pattern))
        if matches:
            return matches[0]
    return None


def resolve_checkout_path(checkout_root: Path, tag: str) -> Path:
    return checkout_root / f"c-kzg-4844-{tag}"


def expected_binding_outcome(case: dict) -> str:
    if case["expected"]["normalization"]["result"] == "error":
        return "exception"
    return case["expected"]["decision"]


def case_matches_expectation(case: dict, observed: dict) -> bool:
    return observed.get("outcome") == expected_binding_outcome(case)


def build_checkout(
    checkout_path: Path,
    trusted_setup_relpath: Path,
    python_executable: str,
    dry_run: bool,
    force_rebuild: bool,
) -> dict:
    result = {
        "checkout_path": checkout_path.as_posix(),
        "trusted_setup_path": str((checkout_path / trusted_setup_relpath).as_posix()),
        "status": None,
        "detail": None,
        "artifact_path": None,
    }

    if not checkout_path.exists():
        result["status"] = "missing_checkout"
        result["detail"] = "checkout directory does not exist"
        return result

    if not (checkout_path / "setup.py").exists():
        result["status"] = "invalid_checkout"
        result["detail"] = "setup.py not found in checkout"
        return result

    trusted_setup_path = checkout_path / trusted_setup_relpath
    if not trusted_setup_path.exists():
        result["status"] = "missing_trusted_setup"
        result["detail"] = f"trusted setup file missing at {trusted_setup_path.as_posix()}"
        return result

    if not (checkout_path / "blst" / "bindings").exists():
        result["status"] = "missing_submodule"
        result["detail"] = "required blst submodule is not initialized"
        return result

    artifact = locate_extension_artifact(checkout_path)
    if artifact is not None and not force_rebuild:
        result["status"] = "ready"
        result["detail"] = "reusing existing ckzg extension artifact"
        result["artifact_path"] = artifact.as_posix()
        return result

    if dry_run:
        result["status"] = "dry_run"
        result["detail"] = "build skipped because --dry-run was used"
        return result

    if shutil.which("make") is None:
        result["status"] = "build_unavailable"
        result["detail"] = "required build tool 'make' is not available on PATH"
        return result

    completed = subprocess.run(
        [python_executable, "setup.py", "build_ext", "--inplace"],
        cwd=checkout_path,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    artifact = locate_extension_artifact(checkout_path)
    if completed.returncode == 0 and artifact is not None:
        result["status"] = "ready"
        result["detail"] = "built ckzg Python extension in place"
        result["artifact_path"] = artifact.as_posix()
        return result

    merged_output = "\n".join(part for part in [completed.stdout, completed.stderr] if part)
    result["status"] = "build_failed"
    result["detail"] = truncate_text(merged_output or "build failed with no output")
    if artifact is not None:
        result["artifact_path"] = artifact.as_posix()
    return result


def invoke_case_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Internal case runner for ckzg replay.")
    parser.add_argument("--case", required=True)
    parser.add_argument("--checkout", required=True)
    parser.add_argument("--trusted-setup", required=True)
    args = parser.parse_args(argv)

    checkout_path = Path(args.checkout)
    case = load_json(Path(args.case))

    try:
        sys.path.insert(0, str(checkout_path))
        import ckzg  # type: ignore

        trusted_setup = ckzg.load_trusted_setup(args.trusted_setup, 0)
        api = case["api"]
        input_data = case["input"]

        if api == "verify_kzg_proof":
            valid = ckzg.verify_kzg_proof(
                hex_to_bytes(input_data["commitment"]),
                hex_to_bytes(input_data["z"]),
                hex_to_bytes(input_data["y"]),
                hex_to_bytes(input_data["proof"]),
                trusted_setup,
            )
        elif api == "verify_blob_kzg_proof":
            valid = ckzg.verify_blob_kzg_proof(
                hex_to_bytes(input_data["blob"]),
                hex_to_bytes(input_data["commitment"]),
                hex_to_bytes(input_data["proof"]),
                trusted_setup,
            )
        elif api == "verify_blob_kzg_proof_batch":
            valid = ckzg.verify_blob_kzg_proof_batch(
                b"".join(hex_to_bytes(blob) for blob in input_data["blobs"]),
                b"".join(hex_to_bytes(commitment) for commitment in input_data["commitments"]),
                b"".join(hex_to_bytes(proof) for proof in input_data["proofs"]),
                trusted_setup,
            )
        elif api == "verify_cell_kzg_proof_batch":
            valid = ckzg.verify_cell_kzg_proof_batch(
                [hex_to_bytes(commitment) for commitment in input_data["commitments"]],
                list(input_data["cell_indices"]),
                [hex_to_bytes(cell) for cell in input_data["cells"]],
                [hex_to_bytes(proof) for proof in input_data["proofs"]],
                trusted_setup,
            )
        else:
            raise ValueError(f"unsupported API: {api}")

        payload = {
            "outcome": "accept" if bool(valid) else "reject",
            "return_value": bool(valid),
        }
    except Exception as exc:
        payload = {
            "outcome": "exception",
            "exception_type": type(exc).__name__,
            "message": str(exc),
        }

    print(json.dumps(payload))
    return 0


def run_case(
    script_path: Path,
    python_executable: str,
    checkout_path: Path,
    case_path: Path,
    trusted_setup_path: Path,
) -> dict:
    env = os.environ.copy()
    python_path = str(checkout_path)
    if env.get("PYTHONPATH"):
        python_path = python_path + os.pathsep + env["PYTHONPATH"]
    env["PYTHONPATH"] = python_path

    completed = subprocess.run(
        [
            python_executable,
            str(script_path),
            "_invoke_case",
            "--case",
            str(case_path),
            "--checkout",
            str(checkout_path),
            "--trusted-setup",
            str(trusted_setup_path),
        ],
        cwd=checkout_path,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=env,
    )

    if completed.returncode != 0:
        merged_output = "\n".join(part for part in [completed.stdout, completed.stderr] if part)
        return {
            "outcome": "runner_error",
            "message": truncate_text(merged_output or "runner subprocess exited unsuccessfully"),
            "returncode": completed.returncode,
        }

    try:
        return json.loads(completed.stdout.strip())
    except json.JSONDecodeError:
        merged_output = "\n".join(part for part in [completed.stdout, completed.stderr] if part)
        return {
            "outcome": "runner_error",
            "message": truncate_text(merged_output or "runner subprocess did not emit JSON"),
            "returncode": completed.returncode,
        }


def build_report(args: argparse.Namespace) -> dict:
    plan_path = resolve_workspace_path(args.plan)
    output_path = resolve_workspace_path(args.output)
    checkout_root = resolve_workspace_path(args.checkout_root)
    trusted_setup_relpath = Path(args.trusted_setup_relpath)
    script_path = Path(__file__).resolve()

    plan = load_json(plan_path)
    selected_tags = set(args.tag or [])
    jobs = [job for job in plan["jobs"] if not selected_tags or job["tag"] in selected_tags]

    tag_builds: dict[str, dict] = {}
    for tag in sorted({job["tag"] for job in jobs}):
        tag_builds[tag] = build_checkout(
            checkout_path=resolve_checkout_path(checkout_root, tag),
            trusted_setup_relpath=trusted_setup_relpath,
            python_executable=args.python_executable,
            dry_run=args.dry_run,
            force_rebuild=args.force_rebuild,
        )

    counts = Counter()
    job_reports = []

    for job in jobs:
        case_path = resolve_workspace_path(job["case_path"])
        case = load_json(case_path)
        build_state = tag_builds[job["tag"]]

        report = {
            "case_id": job["case_id"],
            "tag": job["tag"],
            "api": job["api"],
            "family": job["family"],
            "case_path": case_path.as_posix(),
            "expected_replay": job["expected_replay"],
            "expected_case_outcome": expected_binding_outcome(case),
            "expected_decision": job["expected_decision"],
            "expected_normalization": job["expected_normalization"],
            "status": None,
            "detail": None,
            "observed": None,
        }

        if not job["runnable"]:
            report["status"] = "skipped"
            report["detail"] = f"job marked non-runnable by replay plan ({job['fixture_state']})"
            counts["skipped"] += 1
            job_reports.append(report)
            continue

        if build_state["status"] != "ready":
            report["status"] = "skipped"
            report["detail"] = build_state["detail"]
            counts["skipped"] += 1
            job_reports.append(report)
            continue

        observed = run_case(
            script_path=script_path,
            python_executable=args.python_executable,
            checkout_path=Path(build_state["checkout_path"]),
            case_path=case_path,
            trusted_setup_path=Path(build_state["trusted_setup_path"]),
        )
        report["observed"] = observed

        if observed.get("outcome") == "runner_error":
            report["status"] = "error"
            report["detail"] = observed.get("message")
            counts["error"] += 1
            job_reports.append(report)
            continue

        matches_case = case_matches_expectation(case, observed)
        matches_matrix = matches_case if job["expected_replay"] == "pass" else not matches_case
        report["status"] = "pass" if matches_matrix else "fail"
        report["detail"] = (
            "observed binding behavior matched the expected replay matrix"
            if matches_matrix
            else "observed binding behavior did not match the expected replay matrix"
        )
        report["observed_matches_case"] = matches_case
        report["observed_matches_replay_matrix"] = matches_matrix
        counts[report["status"]] += 1
        job_reports.append(report)

    report = {
        "schema_version": 1,
        "source_plan": plan_path.as_posix(),
        "generated_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "environment": {
            "python_executable": args.python_executable,
            "platform": platform.platform(),
            "checkout_root": checkout_root.as_posix(),
            "trusted_setup_relpath": trusted_setup_relpath.as_posix(),
            "dry_run": args.dry_run,
            "force_rebuild": args.force_rebuild,
            "make_available": shutil.which("make") is not None,
        },
        "summary": {
            "job_count": len(job_reports),
            "pass_count": counts["pass"],
            "fail_count": counts["fail"],
            "error_count": counts["error"],
            "skipped_count": counts["skipped"],
        },
        "tag_builds": {
            tag: {
                "checkout_path": state["checkout_path"],
                "trusted_setup_path": state["trusted_setup_path"],
                "status": state["status"],
                "detail": state["detail"],
                "artifact_path": state["artifact_path"],
            }
            for tag, state in sorted(tag_builds.items())
        },
        "jobs": job_reports,
    }

    dump_json(output_path, report)
    return report


def run_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Replay adversarial cases against pinned c-kzg-4844 tag checkouts."
    )
    parser.add_argument(
        "--plan",
        default=str(DEFAULT_PLAN.relative_to(REPO_ROOT)),
        help="Path to the replay plan JSON.",
    )
    parser.add_argument(
        "--output",
        default=str(DEFAULT_OUTPUT.relative_to(REPO_ROOT)),
        help="Path to write the replay report JSON.",
    )
    parser.add_argument(
        "--checkout-root",
        default=str(DEFAULT_CHECKOUT_ROOT.relative_to(REPO_ROOT)),
        help="Directory that contains c-kzg-4844 tag checkouts named c-kzg-4844-<tag>.",
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
        "--tag",
        action="append",
        help="Optional tag filter. May be passed multiple times.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not attempt to build ckzg or execute cases; report checkout readiness only.",
    )
    parser.add_argument(
        "--force-rebuild",
        action="store_true",
        help="Rebuild ckzg even if an extension artifact already exists in the checkout.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit non-zero unless every replay job finishes with status=pass.",
    )
    args = parser.parse_args(argv)

    report = build_report(args)
    print(
        f"wrote {resolve_workspace_path(args.output).as_posix()} with "
        f"{report['summary']['job_count']} jobs "
        f"({report['summary']['pass_count']} pass, "
        f"{report['summary']['fail_count']} fail, "
        f"{report['summary']['error_count']} error, "
        f"{report['summary']['skipped_count']} skipped)"
    )
    if args.strict and any(job["status"] != "pass" for job in report["jobs"]):
        return 1
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "_invoke_case":
        return invoke_case_main(sys.argv[2:])
    return run_main(sys.argv[1:])


if __name__ == "__main__":
    raise SystemExit(main())
