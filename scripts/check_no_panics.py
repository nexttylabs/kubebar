#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

PATTERNS = {
    r"\.unwrap\s*\(": "Use proper error handling instead of .unwrap() in production Rust code.",
    r"\.expect\s*\(": "Use proper error handling instead of .expect() in production Rust code.",
    r"\bpanic!\s*\(": "Avoid panic! in production Rust code.",
    r"\bassert!\s*\(": "Avoid assert! in production Rust code.",
}

IGNORED_PARTS = {"tests", "benches", "examples", "fixtures", "testdata"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Block panic-style patterns in changed production Rust code.")
    parser.add_argument("--base", required=True, help="Base git revision to diff from.")
    parser.add_argument("--head", default="HEAD", help="Head git revision to diff to.")
    return parser.parse_args()


def is_production_rust_file(path: str) -> bool:
    file_path = Path(path)
    if file_path.suffix != ".rs":
        return False
    if any(part in IGNORED_PARTS for part in file_path.parts):
        return False
    return True


def git_diff(base: str, head: str) -> str:
    cmd = ["git", "diff", "--unified=0", base, head, "--", "*.rs"]
    result = subprocess.run(cmd, check=False, capture_output=True, text=True)
    if result.returncode not in {0, 1}:
        print(result.stderr.strip(), file=sys.stderr)
        raise SystemExit(result.returncode)
    return result.stdout


def main() -> int:
    args = parse_args()
    diff = git_diff(args.base, args.head)

    current_file: str | None = None
    failures: list[str] = []

    for raw_line in diff.splitlines():
        if raw_line.startswith("+++ b/"):
            candidate = raw_line[6:]
            current_file = candidate if is_production_rust_file(candidate) else None
            continue

        if current_file is None:
            continue

        if not raw_line.startswith("+") or raw_line.startswith("+++"):
            continue

        line = raw_line[1:]
        for pattern, message in PATTERNS.items():
            if re.search(pattern, line):
                failures.append(f"{current_file}: {message}\n  Added line: {line.strip()}")

    if failures:
        print("Found panic-style patterns in changed production Rust files:\n", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("No panic-style patterns found in changed production Rust files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
