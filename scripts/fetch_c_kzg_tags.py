#!/usr/bin/env python3

import argparse
import json
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TAGS = REPO_ROOT / "vendor" / "c-kzg-4844-tags.json"
DEFAULT_CHECKOUT_ROOT = REPO_ROOT / ".tmp"


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def resolve_workspace_path(path_text: str | Path) -> Path:
    path = Path(path_text)
    if path.is_absolute():
        return path
    return REPO_ROOT / path


def run_git(command: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def ensure_submodules(checkout_path: Path) -> None:
    completed = run_git(
        [
            "git",
            "submodule",
            "update",
            "--init",
            "--depth",
            "1",
            "--recursive",
        ],
        cwd=checkout_path,
    )
    if completed.returncode != 0:
        raise SystemExit(
            completed.stderr
            or completed.stdout
            or f"failed to initialize submodules in {checkout_path.as_posix()}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fetch pinned c-kzg-4844 tag checkouts under .tmp for replay runs."
    )
    parser.add_argument(
        "--tags-json",
        default=str(DEFAULT_TAGS.relative_to(REPO_ROOT)),
        help="Path to vendor/c-kzg-4844-tags.json.",
    )
    parser.add_argument(
        "--checkout-root",
        default=str(DEFAULT_CHECKOUT_ROOT.relative_to(REPO_ROOT)),
        help="Directory that should contain c-kzg-4844-<tag> checkouts.",
    )
    parser.add_argument(
        "--tag",
        action="append",
        help="Optional tag filter. May be passed multiple times.",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="If a checkout already exists, fetch the requested tag and hard-switch it to that tag.",
    )
    args = parser.parse_args()

    metadata = load_json(resolve_workspace_path(args.tags_json))
    checkout_root = resolve_workspace_path(args.checkout_root)
    checkout_root.mkdir(parents=True, exist_ok=True)
    repo_url = f"https://github.com/{metadata['repository']}.git"
    selected_tags = set(args.tag or [])

    fetched = 0
    reused = 0

    for tag_info in metadata["tags"]:
        tag = tag_info["tag"]
        if selected_tags and tag not in selected_tags:
            continue

        target = checkout_root / f"c-kzg-4844-{tag}"
        if target.exists():
            if not args.refresh:
                ensure_submodules(target)
                reused += 1
                print(f"reuse {target.as_posix()}")
                continue

            completed = run_git(["git", "fetch", "--depth", "1", "origin", tag], cwd=target)
            if completed.returncode != 0:
                raise SystemExit(completed.stderr or completed.stdout or f"failed to fetch {tag}")
            completed = run_git(["git", "checkout", "--force", tag], cwd=target)
            if completed.returncode != 0:
                raise SystemExit(completed.stderr or completed.stdout or f"failed to checkout {tag}")
            ensure_submodules(target)
            fetched += 1
            print(f"refresh {target.as_posix()} @ {tag}")
            continue

        completed = run_git(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--branch",
                tag,
                "--recurse-submodules",
                "--shallow-submodules",
                repo_url,
                str(target),
            ]
        )
        if completed.returncode != 0:
            raise SystemExit(completed.stderr or completed.stdout or f"failed to clone {tag}")
        ensure_submodules(target)
        fetched += 1
        print(f"clone {target.as_posix()} @ {tag}")

    print(f"done ({fetched} fetched, {reused} reused)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
