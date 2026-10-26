"""Synchronize the monitoring-owned process contract with explicitly selected consumers."""

import argparse
import hashlib
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", action="append", default=[], type=Path)
    parser.add_argument("--policy-only-target", action="append", default=[], type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = Path(__file__).resolve().parent
    mismatches = []
    for root, policy_only in [(p, False) for p in args.target] + [(p, True) for p in args.policy_only_target]:
        root = root.resolve(strict=True)
        if not (root / "AGENTS.md").is_file():
            parser.error(f"Not an explicit repository root: {root}")
        names = ["process-health-policy.json"] if policy_only else ["process-health-policy.json", "ProcessHealthTelemetry.cs"]
        for name in names:
            content = (source / name).read_bytes()
            destination = root / "src" / "contract" / name
            if args.check:
                if not destination.is_file() or destination.read_bytes() != content:
                    mismatches.append(str(destination))
            else:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(content)
            print(f"{hashlib.sha256(content).hexdigest()}  {destination}")
    if mismatches:
        print("Process contract drift:\n" + "\n".join(mismatches), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
